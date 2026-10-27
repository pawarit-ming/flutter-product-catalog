import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../application/catalog_query_provider.dart';
import '../application/categories_provider.dart';
import '../application/product_list_notifier.dart';
import '../application/product_list_state.dart';
import '../data/catalog_query.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/product_grid.dart';

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
    ProductSort.recommended => 'แนะนำ',
    ProductSort.priceLowToHigh => 'ราคาปกติต่ำไปสูง',
    ProductSort.priceHighToLow => 'ราคาปกติสูงไปต่ำ',
    ProductSort.ratingHighToLow => 'คะแนนรีวิวสูงสุด',
    ProductSort.titleAToZ => 'ชื่อสินค้า A–Z',
  };

  String get compactLabel => switch (this) {
    ProductSort.recommended => 'แนะนำ',
    ProductSort.priceLowToHigh => 'ราคาปกติ ↑',
    ProductSort.priceHighToLow => 'ราคาปกติ ↓',
    ProductSort.ratingHighToLow => 'คะแนนสูงสุด',
    ProductSort.titleAToZ => 'ชื่อ A–Z',
  };

  IconData get icon => switch (this) {
    ProductSort.recommended => Icons.tune_rounded,
    ProductSort.priceLowToHigh => Icons.arrow_upward_rounded,
    ProductSort.priceHighToLow => Icons.arrow_downward_rounded,
    ProductSort.ratingHighToLow => Icons.star_outline_rounded,
    ProductSort.titleAToZ => Icons.sort_by_alpha_rounded,
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
  late final _searchController = TextEditingController(
    text: ref.read(catalogSearchProvider),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CatalogQueryNotifier get _query => ref.read(catalogQueryProvider.notifier);

  void _onSearchChanged(String text) {
    ref.read(catalogSearchProvider.notifier).setText(text);
  }

  void _submitSearch(String text) {
    _query.setSearch(text);
  }

  void _clearSearch() {
    _query.setSearch('');
  }

  void _selectCategory(String? slug) {
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
    ref.listen(catalogSearchProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });
    ref.listen(catalogQueryProvider, (previous, next) {
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
    // The clear button follows the draft, independently of API query updates.
    ref.watch(catalogSearchProvider);
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
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างการค้นหา',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
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

    Widget chip(String label, String? slug) {
      final selected = !query.isSearching && selectedSlug == slug;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        labelStyle: TextStyle(
          color: selected ? colors.onPrimary : colors.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
        onSelected: (_) => onSelected(slug),
      );
    }

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
        _SortMenu(
          selected: query.sort,
          onSelected: ref.read(catalogQueryProvider.notifier).setSort,
        ),
      ],
    );
  }
}

/// An outlined sort control with a readable, right-anchored options menu.
/// The popup is wider than the compact trigger to fit full Thai labels.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.selected, required this.onSelected});

  final ProductSort selected;
  final ValueChanged<ProductSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopupMenuButton<ProductSort>(
      tooltip: 'เรียงลำดับ',
      position: PopupMenuPosition.under,
      offset: const Offset(0, AppSpace.xs),
      menuPadding: const EdgeInsets.all(AppSpace.xs),
      constraints: BoxConstraints.tightFor(
        width: math.min(
          280,
          MediaQuery.sizeOf(context).width - AppSpace.lg * 2,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<ProductSort>(
          enabled: false,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Text(
            'เรียงลำดับสินค้า',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final sort in ProductSort.values)
          PopupMenuItem(
            value: sort,
            height: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xs,
              vertical: 2,
            ),
            child: Semantics(
              selected: sort == selected,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.md,
                ),
                decoration: BoxDecoration(
                  color: sort == selected ? colors.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(AppRadius.thumb),
                ),
                child: Row(
                  children: [
                    Icon(
                      sort.icon,
                      size: 20,
                      color: sort == selected
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        sort.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: colors.onSurface,
                          fontWeight: sort == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    SizedBox.square(
                      dimension: 20,
                      child: sort == selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: colors.onSurface,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      child: Semantics(
        label: 'เรียงลำดับ: ${selected.label}',
        excludeSemantics: true,
        // Keep a 48 dp tap target around the smaller visible control.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.thumb),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  selected.compactLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.expand_more,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
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
              LinearProgressIndicator(value: progress.toDouble(), minHeight: 2),
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
