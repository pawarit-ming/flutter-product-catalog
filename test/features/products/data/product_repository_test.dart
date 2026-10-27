import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/features/products/data/catalog_query.dart';
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

Map<String, Object?> page(List<int> ids, {required int total, int skip = 0}) =>
    {
      'products': [for (final id in ids) productJson(id)],
      'total': total,
      'skip': skip,
      'limit': ids.length,
    };

void main() {
  late FakeAdapter adapter;
  late DioProductRepository repository;

  void respond(ResponseBody Function(RequestOptions options) handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    repository = DioProductRepository(dio);
  }

  Matcher throwsAppError(AppErrorType type) =>
      throwsA(isA<AppException>().having((e) => e.type, 'type', type));

  Future<void> list({
    CatalogQuery query = const CatalogQuery(),
    int offset = 0,
    int limit = 20,
  }) => repository.getProducts(query: query, offset: offset, limit: limit);

  group('getProducts', () {
    test('sends limit and skip, and builds the cursor from total', () async {
      respond((_) => json(page([21, 22], total: 30, skip: 20)));

      final result = await repository.getProducts(
        query: const CatalogQuery(),
        offset: 20,
        limit: 2,
      );

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/products');
      expect(uri.queryParameters, {'limit': '2', 'skip': '20'});
      expect(result.items.map((p) => p.id), [21, 22]);
      expect(result.nextOffset, 22);
      expect(result.total, 30);
      expect(result.hasMore, isTrue);
    });

    test('stops when the cursor reaches total', () async {
      respond((_) => json(page([29, 30], total: 30, skip: 28)));

      final result = await repository.getProducts(
        query: const CatalogQuery(),
        offset: 28,
        limit: 2,
      );

      expect(result.nextOffset, 30);
      expect(result.hasMore, isFalse);
    });

    test(
      'an empty page ends pagination even if total says otherwise',
      () async {
        respond((_) => json(page([], total: 50, skip: 40)));

        final result = await repository.getProducts(
          query: const CatalogQuery(),
          offset: 40,
          limit: 20,
        );

        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
      },
    );

    test('searches with q and sort parameters', () async {
      respond((_) => json(page([1], total: 1)));

      await list(
        query: const CatalogQuery(
          search: 'phone case',
          sort: ProductSort.priceHighToLow,
        ),
      );

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/products/search');
      expect(uri.queryParameters, {
        'q': 'phone case',
        'limit': '20',
        'skip': '0',
        'sortBy': 'price',
        'order': 'desc',
      });
    });

    test('filters by category', () async {
      respond((_) => json(page([1], total: 1)));

      await list(
        query: const CatalogQuery(
          categorySlug: 'skin-care',
          sort: ProductSort.ratingHighToLow,
        ),
      );

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/products/category/skin-care');
      expect(uri.queryParameters['sortBy'], 'rating');
      expect(uri.queryParameters['order'], 'desc');
    });

    test('rejects a response without products or total', () async {
      respond((_) => json([productJson(1)]));
      await expectLater(list(), throwsAppError(AppErrorType.invalidData));

      respond((_) => json({'products': []}));
      await expectLater(list(), throwsAppError(AppErrorType.invalidData));
    });

    test('rejects the whole page if one product is malformed', () {
      respond(
        (_) => json({
          'products': [
            productJson(1),
            {'id': 2},
          ],
          'total': 2,
        }),
      );
      expect(list(), throwsAppError(AppErrorType.invalidData));
    });

    test('maps 404 on the list to a server error, not "not found"', () {
      respond((_) => json({'message': 'nope'}, 404));
      expect(list(), throwsAppError(AppErrorType.server));
    });

    test('maps HTTP 500 to a server error', () {
      respond((_) => json({'message': 'boom'}, 500));
      expect(list(), throwsAppError(AppErrorType.server));
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
      expect(list(), throwsAppError(AppErrorType.invalidData));
    });

    test('maps timeouts', () {
      respond(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(list(), throwsAppError(AppErrorType.timeout));
    });

    test('maps connection errors and socket errors to network', () async {
      respond(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(list(), throwsAppError(AppErrorType.network));

      respond((_) => throw const SocketException('offline'));
      await expectLater(list(), throwsAppError(AppErrorType.network));
    });

    test('maps cancellation to cancelled', () {
      respond((_) => json(page([], total: 0)));
      final token = CancelToken()..cancel();
      expect(
        repository.getProducts(
          query: const CatalogQuery(),
          offset: 0,
          limit: 20,
          cancelToken: token,
        ),
        throwsAppError(AppErrorType.cancelled),
      );
    });
  });

  group('getProduct', () {
    test('loads one product by id', () async {
      respond((_) => json(productJson(5)));

      final product = await repository.getProduct(5);

      expect(adapter.requests.single.uri.path, '/products/5');
      expect(product.id, 5);
      expect(product.brand, 'Acme');
    });

    test('maps HTTP 404 to not found', () {
      respond((_) => json({'message': "Product with id '5' not found"}, 404));
      expect(repository.getProduct(5), throwsAppError(AppErrorType.notFound));
    });

    test('maps HTTP 400 to a server error', () {
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

  group('getCategories', () {
    test('parses the category list', () async {
      respond(
        (_) => json([
          {'slug': 'beauty', 'name': 'Beauty', 'url': 'https://x.test'},
          {'slug': 'skin-care', 'name': 'Skin Care', 'url': 'https://x.test'},
        ]),
      );

      final categories = await repository.getCategories();

      expect(adapter.requests.single.uri.path, '/products/categories');
      expect(categories.map((c) => c.slug), ['beauty', 'skin-care']);
    });

    test('rejects a malformed list', () {
      respond((_) => json({'categories': []}));
      expect(
        repository.getCategories(),
        throwsAppError(AppErrorType.invalidData),
      );
    });
  });

  group('getCategoryCover', () {
    test('asks for one product photo and returns its thumbnail', () async {
      respond(
        (_) => json({
          'products': [
            {
              'thumbnail': 'https://x.test/thumb.webp',
              'images': ['https://x.test/1.webp'],
            },
          ],
          'total': 5,
        }),
      );

      final cover = await repository.getCategoryCover('home-decoration');

      final uri = adapter.requests.single.uri;
      expect(uri.path, '/products/category/home-decoration');
      expect(uri.queryParameters, {'limit': '1', 'select': 'thumbnail,images'});
      expect(cover, 'https://x.test/thumb.webp');
    });

    test('falls back to the first image, then to null', () async {
      respond(
        (_) => json({
          'products': [
            {
              'thumbnail': 'not a url',
              'images': ['https://x.test/1.webp'],
            },
          ],
        }),
      );
      expect(await repository.getCategoryCover('a'), 'https://x.test/1.webp');

      respond((_) => json({'products': <Object>[]}));
      expect(await repository.getCategoryCover('a'), isNull);
    });

    test('rejects a malformed response', () {
      respond((_) => json(['nope']));
      expect(
        repository.getCategoryCover('a'),
        throwsAppError(AppErrorType.invalidData),
      );
    });
  });
}
