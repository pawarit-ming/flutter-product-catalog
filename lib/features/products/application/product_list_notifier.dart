import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/riverpod/no_retry.dart';
import '../data/catalog_query.dart';
import '../data/product_repository.dart';
import 'catalog_query_provider.dart';
import 'product_list_state.dart';

const productPageSize = 20;

/// Lives at the app's root scope (not auto-disposed) so the list survives
/// navigating to the detail screen and back. It watches [catalogQueryProvider],
/// so a new search, category or sort rebuilds it from the first page.
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, ProductListState>(
      ProductListNotifier.new,
      retry: noRetry,
    );

class ProductListNotifier extends AsyncNotifier<ProductListState> {
  /// Bumped by every build and refresh. A request only writes state if the
  /// generation it started with is still current and this notifier has not
  /// been disposed, so a slow Load More that finishes after a Refresh or a
  /// query change (in success, catch or finally) cannot touch the new list,
  /// cursor or loading flags.
  int _generation = 0;
  bool _disposed = false;
  CancelToken? _loadMoreToken;
  CancelToken? _refreshToken;
  Future<void>? _refreshInFlight;
  late CatalogQuery _query;

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  /// The single entry point for the initial load. On a rebuild (e.g. a new
  /// query) the previous build's requests are cancelled in onDispose and
  /// their late results are rejected by [_isCurrent].
  @override
  Future<ProductListState> build() async {
    _query = ref.watch(catalogQueryProvider);
    _generation++;
    _disposed = false;
    final token = CancelToken();
    ref.onDispose(() {
      _disposed = true;
      token.cancel();
      _loadMoreToken?.cancel();
      _refreshToken?.cancel();
    });

    final page = await _repository.getProducts(
      query: _query,
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
    final current = _currentData;
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
        query: _query,
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
    final snapshot = _currentData;
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
        query: _query,
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

  /// Loaded data for the current query, or null while (re)loading or after
  /// a failed load (which may still carry the previous query's items).
  ProductListState? get _currentData =>
      state.isLoading || state.hasError ? null : state.value;

  bool _isCurrent(int generation) =>
      !_disposed && ref.mounted && generation == _generation;
}
