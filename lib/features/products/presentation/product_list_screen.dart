import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../application/catalog_query_provider.dart';
import '../application/categories_provider.dart';
import '../application/product_list_notifier.dart';
import '../application/product_list_state.dart';
import '../data/catalog_query.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/product_grid.dart';

const searchDebounce = Duration(milliseconds: 400);

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
    ProductSort.recommended => 'แนะนำ',
    ProductSort.priceLowToHigh => 'ราคา: ต่ำ → สูง',
    ProductSort.priceHighToLow => 'ราคา: สูง → ต่ำ',
    ProductSort.ratingHighToLow => 'คะแนนสูงสุด',
    ProductSort.titleAToZ => 'ชื่อ A → Z',
  };
}

/// Catalog tab: search, category chips, sort, and the paginated grid.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  // Created once so the scroll position survives opening a product.
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CatalogQueryNotifier get _query => ref.read(catalogQueryProvider.notifier);

  void _onSearchChanged(String text) {
    setState(() {}); // shows or hides the clear button
    _searchDebounce?.cancel();
    _searchDebounce = Timer(searchDebounce, () => _query.setSearch(text));
  }

  void _submitSearch(String text) {
    _searchDebounce?.cancel();
    _query.setSearch(text);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _query.setSearch('');
    setState(() {});
  }

  void _selectCategory(String? slug) {
    _searchDebounce?.cancel();
    _searchController.clear();
    _query.setCategory(slug);
  }

  Future<void> _onRefresh() async {
    final list = ref.read(productListProvider);
    if (list.isLoading) {
      await _waitForList();
    } else if (list.hasError || !list.hasValue) {
      await _retryInitialLoad();
    } else {
      await ref.read(productListProvider.notifier).refresh();
    }
  }

  Future<void> _retryInitialLoad() {
    ref.invalidate(productListProvider);
    return _waitForList();
  }

  // Errors are rendered from the provider state; only wait for completion.
  Future<void> _waitForList() => ref
      .read(productListProvider.future)
      .then<void>((_) {}, onError: (Object _) {});

  @override
  Widget build(BuildContext context) {
    ref.listen(productListProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      // One message per failed refresh request.
      if (before != null &&
          before.isRefreshing &&
          after != null &&
          !after.isRefreshing &&
          after.refreshError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('รีเฟรชไม่สำเร็จ: ${after.refreshError!.message}'),
            ),
          );
      }
    });
    ref.listen(catalogQueryProvider, (previous, next) {
      // Keep the search box in sync when another screen changes the query
      // (e.g. picking a category clears the search).
      if (_searchController.text.trim() != next.search) {
        _searchController.text = next.search;
      }
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });

    final query = ref.watch(catalogQueryProvider);
    final list = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),
      body: Column(
        children: [
          _CatalogHeader(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onSearchSubmitted: _submitSearch,
            onClearSearch: _clearSearch,
            onCategorySelected: _selectCategory,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                key: const PageStorageKey('product-list'),
                controller: _scrollController,
                // Pull-to-refresh must work even when the list is short or
                // empty.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final layout = ProductGridLayout.forWidth(
                        constraints.crossAxisExtent,
                        MediaQuery.textScalerOf(context),
                      );
                      return _buildContent(list, query, layout);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<ProductListState> list,
    CatalogQuery query,
    ProductGridLayout layout,
  ) {
    // A new query keeps the previous items in `value` while loading, so check
    // loading and error first.
    if (list.isLoading) {
      return SliverPadding(
        padding: _gridPadding(layout),
        sliver: SliverProductSkeletonGrid(layout: layout),
      );
    }
    if (list.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: AppException.from(list.error!).message,
          onAction: _retryInitialLoad,
        ),
      );
    }

    final data = list.requireValue;
    if (data.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: query.isSearching
            ? EmptyView(
                icon: Icons.search_off,
                title: 'ไม่พบสินค้าที่ตรงกับ "${query.search}"',
                message: 'ลองใช้คำค้นอื่น หรือดึงลงเพื่อรีเฟรช',
                actionLabel: 'ล้างการค้นหา',
                onAction: _clearSearch,
              )
            : query.categorySlug != null
            ? EmptyView(
                title: 'ไม่มีสินค้าในหมวดนี้',
                message: 'ลองเลือกหมวดอื่น หรือดึงลงเพื่อรีเฟรช',
                actionLabel: 'ดูสินค้าทั้งหมด',
                onAction: () => _selectCategory(null),
              )
            : EmptyView(
                title: 'ไม่พบสินค้า',
                message: 'ดึงลงเพื่อรีเฟรช หรือลองอีกครั้ง',
                actionLabel: 'ลองอีกครั้ง',
                onAction: _onRefresh,
              ),
      );
    }

    return SliverPadding(
      padding: _gridPadding(layout),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverProductGrid(products: data.items, layout: layout),
          SliverToBoxAdapter(
            child: _ListFooter(
              state: data,
              onLoadMore: () =>
                  ref.read(productListProvider.notifier).loadMore(),
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _gridPadding(ProductGridLayout layout) => EdgeInsets.fromLTRB(
    layout.horizontalPadding,
    4,
    layout.horizontalPadding,
    24,
  );
}

/// Search box, category chips and the result count / sort row. Stays fixed
/// above the scrolling grid.
class _CatalogHeader extends ConsumerWidget {
  const _CatalogHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onCategorySelected,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(catalogQueryProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ค้นหาสินค้า เช่น iPhone, น้ำหอม',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างการค้นหา',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _CategoryChips(query: query, onSelected: onCategorySelected),
              _ResultBar(query: query),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.query, required this.onSelected});

  final CatalogQuery query;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final colors = Theme.of(context).colorScheme;
    final selectedSlug = query.isSearching ? null : query.categorySlug;

    Widget chip(String label, String? slug) => ChoiceChip(
      label: Text(label),
      selected: !query.isSearching && selectedSlug == slug,
      onSelected: (_) => onSelected(slug),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          chip('ทั้งหมด', null),
          ...categories.when(
            data: (list) => [for (final c in list) chip(c.name, c.slug)],
            // Static placeholders: no animation while loading.
            loading: () => [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 88,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
            error: (_, _) => [
              ActionChip(
                avatar: const Icon(Icons.refresh, size: 18),
                label: const Text('โหลดหมวดหมู่ไม่สำเร็จ ลองใหม่'),
                onPressed: () => ref.invalidate(categoriesProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends ConsumerWidget {
  const _ResultBar({required this.query});

  final CatalogQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(productListProvider);
    final data = list.isLoading || list.hasError ? null : list.value;
    final summary = data == null
        ? ''
        : 'แสดง ${data.items.length} จาก ${data.total} รายการ';

    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        PopupMenuButton<ProductSort>(
          tooltip: 'เรียงลำดับ',
          initialValue: query.sort,
          onSelected: ref.read(catalogQueryProvider.notifier).setSort,
          itemBuilder: (context) => [
            for (final sort in ProductSort.values)
              CheckedPopupMenuItem(
                value: sort,
                checked: sort == query.sort,
                child: Text(sort.label),
              ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: 4),
                Text(query.sort.label, style: theme.textTheme.labelLarge),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state, required this.onLoadMore});

  final ProductListState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadMoreError = state.loadMoreError;

    final Widget action;
    if (state.isLoadingMore) {
      action = const SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (loadMoreError != null) {
      action = Column(
        children: [
          Text(
            loadMoreError.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: state.isRefreshing ? null : onLoadMore,
            style: _buttonStyle,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองอีกครั้ง'),
          ),
        ],
      );
    } else if (state.hasMore) {
      action = OutlinedButton(
        onPressed: state.isRefreshing ? null : onLoadMore,
        style: _buttonStyle,
        child: const Text('โหลดเพิ่มเติม'),
      );
    } else {
      action = Text(
        'แสดงครบทุกรายการแล้ว',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final total = state.total;
    final pages = math.max(1, (total / productPageSize).ceil());
    final page = (state.nextOffset / productPageSize).ceil().clamp(1, pages);
    final progress = total == 0 ? 1.0 : (state.nextOffset / total).clamp(0, 1);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            children: [
              Text(
                'หน้า $page จาก $pages • โหลดแล้ว ${state.items.length} '
                'จาก $total รายการ',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.toDouble(),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              action,
            ],
          ),
        ),
      ),
    );
  }

  static final _buttonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(200, 48)),
  );
}
