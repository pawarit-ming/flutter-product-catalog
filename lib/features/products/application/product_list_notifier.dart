import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/riverpod/no_retry.dart';
import '../data/product_repository.dart';
import 'product_list_state.dart';

const productPageSize = 20;

/// Lives at the app's root scope (not auto-disposed) so the list survives
/// navigating to the detail screen and back.
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, ProductListState>(
      ProductListNotifier.new,
      retry: noRetry,
    );

class ProductListNotifier extends AsyncNotifier<ProductListState> {
  /// Bumped by every refresh. A request only writes state if
  /// the generation it started with is still current, so a slow Load More that
  /// finishes after a Refresh (in success, catch or finally) cannot touch the
  /// new list, cursor or loading flags.
  int _generation = 0;
  CancelToken? _loadMoreToken;
  CancelToken? _refreshToken;
  Future<void>? _refreshInFlight;

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  /// The single entry point for the initial load. Riverpod creates a new
  /// notifier on every rebuild, so stale requests from a previous instance
  /// are cancelled in onDispose and rejected by `ref.mounted`.
  @override
  Future<ProductListState> build() async {
    final token = CancelToken();
    ref.onDispose(() {
      token.cancel();
      _loadMoreToken?.cancel();
      _refreshToken?.cancel();
    });

    final page = await _repository.getProducts(
      offset: 0,
      limit: productPageSize,
      cancelToken: token,
    );
    return ProductListState.fromFirstPage(page);
  }

  /// Loads the next page. Ignored while another Load More or a Refresh is
  /// running, or when there is nothing more to load. After a failure the
  /// cursor is unchanged, so calling this again retries the same offset.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    final generation = _generation;
    final token = CancelToken();
    _loadMoreToken = token;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final page = await _repository.getProducts(
        offset: current.nextOffset,
        limit: productPageSize,
        cancelToken: token,
      );
      if (!_isCurrent(generation)) return;
      state = AsyncData(state.requireValue.appendPage(page));
    } catch (e) {
      if (!_isCurrent(generation)) return;
      final error = AppException.from(e);
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingMore: false,
          loadMoreError: error.isCancelled ? null : error,
        ),
      );
    } finally {
      if (identical(_loadMoreToken, token)) _loadMoreToken = null;
    }
  }

  /// Reloads the first page. Existing items stay visible until it succeeds;
  /// on failure they are kept and [ProductListState.refreshError] is set.
  /// Calls made while a refresh is running share the same Future. The
  /// returned Future always completes normally.
  Future<void> refresh() => _refreshInFlight ??= _refresh().whenComplete(
    () => _refreshInFlight = null,
  );

  Future<void> _refresh() async {
    // Without data the initial load is retried by invalidating the provider
    // instead (see ProductListScreen).
    final snapshot = state.value;
    if (snapshot == null) return;

    final generation = ++_generation;
    _loadMoreToken?.cancel();
    _loadMoreToken = null;
    final token = CancelToken();
    _refreshToken = token;
    // The snapshot's cursor is kept until the new first page arrives.
    state = AsyncData(
      snapshot.copyWith(
        isRefreshing: true,
        isLoadingMore: false,
        refreshError: null,
      ),
    );

    try {
      final page = await _repository.getProducts(
        offset: 0,
        limit: productPageSize,
        cancelToken: token,
      );
      if (!_isCurrent(generation)) return;
      state = AsyncData(ProductListState.fromFirstPage(page));
    } catch (e) {
      if (!_isCurrent(generation)) return;
      final error = AppException.from(e);
      state = AsyncData(
        state.requireValue.copyWith(
          isRefreshing: false,
          isLoadingMore: false,
          refreshError: error.isCancelled ? null : error,
        ),
      );
    } finally {
      if (identical(_refreshToken, token)) _refreshToken = null;
    }
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;
}
