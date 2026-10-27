import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'catalog_query.dart';
import 'product.dart';
import 'product_category.dart';
import 'product_page.dart';

abstract interface class ProductRepository {
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    required int offset,
    required int limit,
    CancelToken? cancelToken,
  });

  Future<Product> getProduct(int id, {CancelToken? cancelToken});

  Future<List<ProductCategory>> getCategories({CancelToken? cancelToken});

  /// A photo of the first product in category [slug], used as the
  /// category's cover; null when the category has no product with a photo.
  Future<String?> getCategoryCover(String slug, {CancelToken? cancelToken});
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DioProductRepository(ref.watch(dioProvider)),
);

/// Talks to the DummyJSON products API. Every failure is rethrown as an
/// [AppException].
class DioProductRepository implements ProductRepository {
  DioProductRepository(this._dio);

  final Dio _dio;

  @override
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    required int offset,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    // limit=0 means "everything" to this API, so never send it.
    assert(limit > 0);
    final category = query.categorySlug;
    final path = query.isSearching
        ? '/products/search'
        : category != null
        ? '/products/category/${Uri.encodeComponent(category)}'
        : '/products';

    final data = await _get(
      path,
      queryParameters: {
        if (query.isSearching) 'q': query.search,
        'limit': limit,
        'skip': offset,
        'sortBy': ?query.sort.sortBy,
        'order': ?query.sort.order,
      },
      cancelToken: cancelToken,
      isDetail: false,
    );

    if (data is! Map) throw AppException(AppErrorType.invalidData);
    final rawItems = data['products'];
    final total = data['total'];
    if (rawItems is! List || total is! int || total < 0) {
      throw AppException(AppErrorType.invalidData);
    }

    // Reject the whole page if any product is malformed, so pagination never
    // looks complete while items were silently dropped.
    final items = _parse(() => rawItems.map(Product.fromJson).toList());
    final nextOffset = offset + rawItems.length;
    return ProductPage(
      items: items,
      nextOffset: nextOffset,
      total: total,
      hasMore: rawItems.isNotEmpty && nextOffset < total,
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

  @override
  Future<List<ProductCategory>> getCategories({
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/products/categories',
      cancelToken: cancelToken,
      isDetail: false,
    );
    if (data is! List) throw AppException(AppErrorType.invalidData);
    return _parse(() => data.map(ProductCategory.fromJson).toList());
  }

  @override
  Future<String?> getCategoryCover(
    String slug, {
    CancelToken? cancelToken,
  }) async {
    final data = await _get(
      '/products/category/${Uri.encodeComponent(slug)}',
      // One product, and only its photo fields, keeps this request tiny.
      queryParameters: {'limit': 1, 'select': 'thumbnail,images'},
      cancelToken: cancelToken,
      isDetail: false,
    );
    if (data is! Map || data['products'] is! List) {
      throw AppException(AppErrorType.invalidData);
    }
    final first = (data['products'] as List).firstOrNull;
    if (first is! Map) return null;
    return Product.parseImageUrls([first['thumbnail']]).firstOrNull ??
        Product.parseImageUrls(first['images']).firstOrNull;
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
        if (isDetail && status == 404) {
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
}
