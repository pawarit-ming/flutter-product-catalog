import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';

import '../../../helpers/fixtures.dart';

/// Answers every request with [handler] instead of using the network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object? data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late FakeAdapter adapter;
  late DioProductRepository repository;

  void respond(ResponseBody Function(RequestOptions options) handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = adapter;
    repository = DioProductRepository(dio);
  }

  Matcher throwsAppError(AppErrorType type) =>
      throwsA(isA<AppException>().having((e) => e.type, 'type', type));

  group('getProducts', () {
    test('sends offset and limit, and builds the next cursor', () async {
      respond((_) => json([productJson(21), productJson(22)]));

      final page = await repository.getProducts(offset: 20, limit: 2);

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/v1/products');
      expect(uri.queryParameters, {'offset': '20', 'limit': '2'});
      expect(page.items.map((p) => p.id), [21, 22]);
      expect(page.nextOffset, 22);
      expect(page.hasMore, isTrue);
    });

    test('reports no more pages when fewer than limit are returned', () async {
      respond((_) => json([productJson(1)]));

      final page = await repository.getProducts(offset: 0, limit: 20);

      expect(page.nextOffset, 1);
      expect(page.hasMore, isFalse);
    });

    test('an empty page ends pagination', () async {
      respond((_) => json([]));

      final page = await repository.getProducts(offset: 40, limit: 20);

      expect(page.items, isEmpty);
      expect(page.nextOffset, 40);
      expect(page.hasMore, isFalse);
    });

    test('cursor counts raw items, including duplicate IDs', () async {
      respond((_) => json([productJson(1), productJson(1)]));

      final page = await repository.getProducts(offset: 0, limit: 2);

      expect(page.nextOffset, 2);
      expect(page.hasMore, isTrue);
    });

    test('rejects a response that is not a list', () {
      respond((_) => json({'items': []}));
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.invalidData),
      );
    });

    test('rejects the whole page if one product is malformed', () {
      respond(
        (_) => json([
          productJson(1),
          {'id': 2},
        ]),
      );
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.invalidData),
      );
    });

    test('maps 404 on the list to a server error, not "not found"', () {
      respond((_) => json({'message': 'nope'}, 404));
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.server),
      );
    });

    test('maps HTTP 500 to a server error', () {
      respond((_) => json({'message': 'boom'}, 500));
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.server),
      );
    });

    test('maps invalid JSON to invalid data', () {
      respond(
        (_) => ResponseBody.fromString(
          '{not json',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.invalidData),
      );
    });

    test('maps timeouts', () {
      respond(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.timeout),
      );
    });

    test('maps connection errors and socket errors to network', () async {
      respond(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.network),
      );

      respond((_) => throw const SocketException('offline'));
      await expectLater(
        repository.getProducts(offset: 0, limit: 20),
        throwsAppError(AppErrorType.network),
      );
    });

    test('maps cancellation to cancelled', () {
      respond((_) => json([]));
      final token = CancelToken()..cancel();
      expect(
        repository.getProducts(offset: 0, limit: 20, cancelToken: token),
        throwsAppError(AppErrorType.cancelled),
      );
    });
  });

  group('getProduct', () {
    test('loads one product by id', () async {
      respond((_) => json(productJson(5)));

      final product = await repository.getProduct(5);

      expect(adapter.requests.single.uri.path, '/v1/products/5');
      expect(product.id, 5);
      expect(product.category.name, 'Clothes');
    });

    test('maps HTTP 404 to not found', () {
      respond((_) => json({'message': 'missing'}, 404));
      expect(repository.getProduct(5), throwsAppError(AppErrorType.notFound));
    });

    test('maps the API\'s HTTP 400 EntityNotFoundError to not found', () {
      respond(
        (_) => json({
          'name': 'EntityNotFoundError',
          'message': 'Could not find any entity',
        }, 400),
      );
      expect(repository.getProduct(5), throwsAppError(AppErrorType.notFound));
    });

    test('maps other HTTP 400 responses to a server error', () {
      respond((_) => json({'message': 'bad'}, 400));
      expect(repository.getProduct(5), throwsAppError(AppErrorType.server));
    });

    test('rejects a product whose id does not match the request', () {
      respond((_) => json(productJson(6)));
      expect(
        repository.getProduct(5),
        throwsAppError(AppErrorType.invalidData),
      );
    });
  });
}
