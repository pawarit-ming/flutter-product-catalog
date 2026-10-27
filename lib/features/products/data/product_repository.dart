import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'product.dart';
import 'product_page.dart';

abstract interface class ProductRepository {
  Future<ProductPage> getProducts({
    required int offset,
    required int limit,
    CancelToken? cancelToken,
  });

  Future<Product> getProduct(int id, {CancelToken? cancelToken});
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DioProductRepository(ref.watch(dioProvider)),
);

/// Talks to the Platzi Fake Store API. Every failure is rethrown as an
/// [AppException].
class DioProductRepository implements ProductRepository {
  DioProductRepository(this._dio);

  final Dio _dio;

  @override
  Future<ProductPage> getProducts({
    required int offset,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/products',
      queryParameters: {'offset': offset, 'limit': limit},
      cancelToken: cancelToken,
      isDetail: false,
    );
    if (data is! List) throw AppException(AppErrorType.invalidData);

    // Reject the whole page if any product is malformed, so pagination never
    // looks complete while items were silently dropped.
    final items = _parse(() => data.map(Product.fromJson).toList());
    return ProductPage(
      items: items,
      nextOffset: offset + data.length,
      hasMore: data.length >= limit,
    );
  }

  @override
  Future<Product> getProduct(int id, {CancelToken? cancelToken}) async {
    final data = await _get(
      '/products/$id',
      cancelToken: cancelToken,
      isDetail: true,
    );
    final product = _parse(() => Product.fromJson(data));
    if (product.id != id) throw AppException(AppErrorType.invalidData);
    return product;
  }

  Future<Object?> _get(
    String path, {
    required bool isDetail,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e, isDetail: isDetail);
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw AppException(AppErrorType.invalidData);
    } on TypeError {
      throw AppException(AppErrorType.invalidData);
    }
  }

  AppException _mapDioException(DioException e, {required bool isDetail}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppException(AppErrorType.timeout);
      case DioExceptionType.cancel:
        return AppException(AppErrorType.cancelled);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return AppException(AppErrorType.network);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (isDetail &&
            (status == 404 || _isEntityNotFound(e.response?.data))) {
          return AppException(AppErrorType.notFound, statusCode: status);
        }
        return AppException(AppErrorType.server, statusCode: status);
      case DioExceptionType.unknown:
        return switch (e.error) {
          FormatException() => AppException(AppErrorType.invalidData),
          SocketException() => AppException(AppErrorType.network),
          _ => AppException(AppErrorType.unknown),
        };
    }
  }

  /// The API answers an unknown product id with HTTP 400 and
  /// `{"name": "EntityNotFoundError"}` rather than 404.
  bool _isEntityNotFound(Object? data) =>
      data is Map && data['name'] == 'EntityNotFoundError';
}
