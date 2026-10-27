import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/riverpod/no_retry.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

/// Loads one product by ID. Auto-disposed when the detail screen closes,
/// which cancels only this request (the shared Dio client stays open).
final productDetailProvider = FutureProvider.autoDispose.family<Product, int>((
  ref,
  id,
) {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref
      .watch(productRepositoryProvider)
      .getProduct(id, cancelToken: token);
}, retry: noRetry);
