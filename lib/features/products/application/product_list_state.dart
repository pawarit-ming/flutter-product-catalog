import '../../../core/errors/app_exception.dart';
import '../data/product.dart';
import '../data/product_page.dart';

/// Loaded products plus the status of follow-up requests.
///
/// The initial load is represented by the surrounding `AsyncValue`; Load More
/// and Refresh are tracked here so that already loaded items stay on screen.
class ProductListState {
  const ProductListState({
    required this.items,
    required this.nextOffset,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isRefreshing = false,
    this.refreshError,
  });

  factory ProductListState.fromFirstPage(ProductPage page) => ProductListState(
    items: _withoutDuplicates(const [], page.items),
    nextOffset: page.nextOffset,
    total: page.total,
    hasMore: page.hasMore,
  );

  final List<Product> items;
  final int nextOffset;

  /// Total matching products according to the API.
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final AppException? loadMoreError;
  final bool isRefreshing;
  final AppException? refreshError;

  bool get isEmpty => items.isEmpty;

  /// Appends a page, keeping existing items and skipping already-seen IDs.
  /// The cursor comes from the page (raw count), not from the de-duplicated
  /// list length.
  ProductListState appendPage(ProductPage page) => ProductListState(
    items: _withoutDuplicates(items, page.items),
    nextOffset: page.nextOffset,
    total: page.total,
    hasMore: page.hasMore,
    refreshError: refreshError,
  );

  ProductListState copyWith({
    bool? isLoadingMore,
    Object? loadMoreError = _unset,
    bool? isRefreshing,
    Object? refreshError = _unset,
  }) => ProductListState(
    items: items,
    nextOffset: nextOffset,
    total: total,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: identical(loadMoreError, _unset)
        ? this.loadMoreError
        : loadMoreError as AppException?,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    refreshError: identical(refreshError, _unset)
        ? this.refreshError
        : refreshError as AppException?,
  );

  static const _unset = Object();

  static List<Product> _withoutDuplicates(
    List<Product> existing,
    List<Product> incoming,
  ) {
    final seen = {for (final p in existing) p.id};
    return List.unmodifiable([
      ...existing,
      for (final p in incoming)
        if (seen.add(p.id)) p,
    ]);
  }
}
