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
