import 'dart:async';

import 'package:dio/dio.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/features/products/data/catalog_query.dart';
import 'package:product_catalog/features/products/data/product.dart';
import 'package:product_catalog/features/products/data/product_category.dart';
import 'package:product_catalog/features/products/data/product_page.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';

/// Records each request and lets the test decide when and how it completes.
class FakeProductRepository implements ProductRepository {
  final listRequests = <ListRequest>[];
  final detailRequests = <DetailRequest>[];
  final categoryRequests = <Completer<List<ProductCategory>>>[];

  @override
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    required int offset,
    required int limit,
    CancelToken? cancelToken,
  }) {
    final request = ListRequest(query, offset, limit, cancelToken);
    listRequests.add(request);
    return request._completer.future;
  }

  @override
  Future<Product> getProduct(int id, {CancelToken? cancelToken}) {
    final request = DetailRequest(id, cancelToken);
    detailRequests.add(request);
    return request._completer.future;
  }

  @override
  Future<List<ProductCategory>> getCategories({CancelToken? cancelToken}) {
    final completer = Completer<List<ProductCategory>>();
    categoryRequests.add(completer);
    return completer.future;
  }
}

class ListRequest {
  ListRequest(this.query, this.offset, this.limit, this.cancelToken);

  final CatalogQuery query;
  final int offset;
  final int limit;
  final CancelToken? cancelToken;
  final _completer = Completer<ProductPage>();

  bool get isCancelled => cancelToken?.isCancelled ?? false;

  /// Mirrors the real repository: the cursor uses the raw item count, and
  /// [total] defaults to "one more page exists" when the page is full.
  void succeed(List<Product> items, {int? total}) {
    final nextOffset = offset + items.length;
    final resolvedTotal =
        total ?? (items.length >= limit ? nextOffset + 1 : nextOffset);
    _completer.complete(
      ProductPage(
        items: items,
        nextOffset: nextOffset,
        total: resolvedTotal,
        hasMore: items.isNotEmpty && nextOffset < resolvedTotal,
      ),
    );
  }

  void fail(AppErrorType type) => _completer.completeError(AppException(type));
}

class DetailRequest {
  DetailRequest(this.id, this.cancelToken);

  final int id;
  final CancelToken? cancelToken;
  final _completer = Completer<Product>();

  void succeed(Product product) => _completer.complete(product);

  void fail(AppErrorType type) => _completer.completeError(AppException(type));
}
