import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/riverpod/no_retry.dart';
import '../data/product_category.dart';
import '../data/product_repository.dart';

/// Category list from the API, shared by the filter chips and the
/// Categories tab.
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref.watch(productRepositoryProvider).getCategories(cancelToken: token);
}, retry: noRetry);

/// Cover photo URL for one category. Kept for the whole session once loaded,
/// so revisiting the Categories tab does not fetch the covers again.
final categoryCoverProvider = FutureProvider.family<String?, String>(
  (ref, slug) => ref.watch(productRepositoryProvider).getCategoryCover(slug),
  retry: noRetry,
);
