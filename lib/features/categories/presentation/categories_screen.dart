import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/application/home_tab_provider.dart';
import '../../products/application/catalog_query_provider.dart';
import '../../products/application/categories_provider.dart';
import '../../products/data/product_category.dart';
import '../../products/presentation/widgets/error_view.dart';
import '../../products/presentation/widgets/product_image.dart';

/// Departments shown on the Categories tab, in order, with the category
/// slugs each one holds. Categories the API adds later go under
/// [_otherDepartment].
const _departments = [
  ('ความงามและน้ำหอม', ['beauty', 'skin-care', 'fragrances']),
  (
    'แฟชั่นผู้หญิง',
    [
      'tops',
      'womens-dresses',
      'womens-bags',
      'womens-shoes',
      'womens-jewellery',
      'womens-watches',
    ],
  ),
  ('แฟชั่นผู้ชาย', ['mens-shirts', 'mens-shoes', 'mens-watches']),
  (
    'มือถือและคอมพิวเตอร์',
    ['smartphones', 'tablets', 'laptops', 'mobile-accessories'],
  ),
  (
    'บ้านและครัว',
    ['furniture', 'home-decoration', 'kitchen-accessories', 'groceries'],
  ),
  (
    'กีฬาและการเดินทาง',
    ['sports-accessories', 'sunglasses', 'motorcycle', 'vehicle'],
  ),
];
const _otherDepartment = 'หมวดอื่น ๆ';

/// [categories] sorted into departments; empty departments are left out.
List<(String, List<ProductCategory>)> _groupByDepartment(
  List<ProductCategory> categories,
) {
  final bySlug = {for (final category in categories) category.slug: category};
  final groups = <(String, List<ProductCategory>)>[];
  for (final (title, slugs) in _departments) {
    final members = [for (final slug in slugs) ?bySlug.remove(slug)];
    if (members.isNotEmpty) groups.add((title, members));
  }
  // Whatever is left keeps the API's order.
  final others = [
    for (final category in categories)
      if (bySlug.containsKey(category.slug)) category,
  ];
  if (others.isNotEmpty) groups.add((_otherDepartment, others));
  return groups;
}

/// All categories from the API, grouped into departments, each shown with a
/// photo of one of its products; picking one filters the catalog tab.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(
      catalogQueryProvider.select((query) => query.categorySlug),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('หมวดหมู่')),
      body: categories.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: AppException.from(error).message,
          onAction: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) => list.isEmpty
            ? CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessageView(
                      icon: Icons.category_outlined,
                      title: 'ยังไม่มีหมวดหมู่',
                      message: 'ยังไม่มีหมวดหมู่สินค้าในขณะนี้ ลองโหลดอีกครั้ง',
                      action: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(categoriesProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('ลองอีกครั้ง'),
                      ),
                    ),
                  ),
                ],
              )
            : _DepartmentGrid(
                departments: _groupByDepartment(list),
                selected: selected,
                onSelected: (slug) {
                  ref.read(catalogQueryProvider.notifier).setCategory(slug);
                  ref.read(homeTabProvider.notifier).select(HomeTab.catalog);
                },
              ),
      ),
    );
  }
}

/// One heading and a grid of category tiles per department.
class _DepartmentGrid extends StatelessWidget {
  const _DepartmentGrid({
    required this.departments,
    required this.selected,
    required this.onSelected,
  });

  static const _maxWidth = 960.0;
  static const _minTileWidth = 100.0;
  static const _gap = AppSpace.md;

  final List<(String, List<ProductCategory>)> departments;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, _maxWidth);
        final side = (constraints.maxWidth - width) / 2 + AppSpace.lg;
        final usable = width - AppSpace.lg * 2;
        final columns = ((usable + _gap) / (_minTileWidth + _gap))
            .floor()
            .clamp(3, 6);
        final tileWidth = (usable - _gap * (columns - 1)) / columns;
        final tileHeight =
            tileWidth * _CategoryTile.imageRatio +
            _CategoryTile.labelHeight(textScaler);

        return CustomScrollView(
          slivers: [
            for (final (title, members) in departments) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  AppSpace.lg,
                  side,
                  AppSpace.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: _gap,
                    crossAxisSpacing: _gap,
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final category = members[index];
                    return _CategoryTile(
                      category: category,
                      selected: category.slug == selected,
                      onTap: () => onSelected(category.slug),
                    );
                  },
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: AppSpace.xl)),
          ],
        );
      },
    );
  }
}

/// A category as a card: a photo of one of its products, then its name.
/// A skeleton block stands in while the photo is on its way; a category
/// without a photo (or whose photo could not be found) shows its icon on its
/// own tint instead.
class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  /// Photo height as a fraction of the tile width.
  static const imageRatio = 1.0;
  static const _labelSize = 13.0;
  static const _labelLines = 2;

  static double labelHeight(TextScaler textScaler) =>
      textScaler.scale(_labelSize) * 1.35 * _labelLines + AppSpace.sm * 2;

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tint = CategoryPalette.of(context, category.slug);
    // Covers load only while this tab is on screen; once loaded they stay
    // cached for the session.
    final cover = TickerMode.valuesOf(context).enabled
        ? ref.watch(categoryCoverProvider(category.slug))
        : const AsyncLoading<String?>();

    final skeleton = DecoratedBox(
      key: const ValueKey('skeleton'),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.thumb),
      ),
    );
    final Widget image = switch (cover) {
      AsyncData(value: final url?) => ExcludeSemantics(
        key: ValueKey(url),
        child: ProductImage(
          url: url,
          label: category.label,
          padding: AppSpace.sm,
          loading: skeleton,
        ),
      ),
      AsyncData() || AsyncError() => ColoredBox(
        key: const ValueKey('fallback'),
        color: tint.background,
        child: Center(
          child: Icon(
            _iconFor(category.slug),
            size: 30,
            color: tint.foreground,
          ),
        ),
      ),
      _ => Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.all(AppSpace.sm),
        child: skeleton,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: colors.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: selected
              ? BorderSide(color: colors.onSurface, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: image,
                    ),
                    if (selected)
                      Positioned(
                        top: AppSpace.sm,
                        right: AppSpace.sm,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.onSurface,
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: colors.surfaceContainerLowest,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The category's colour, as a small mark beside its name.
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(
                        top:
                            MediaQuery.textScalerOf(context).scale(_labelSize) *
                                1.35 /
                                2 -
                            3,
                        right: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tint.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        category.label,
                        maxLines: _labelLines,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: _labelSize,
                          height: 1.35,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String slug) => switch (slug) {
    'beauty' || 'skin-care' => Icons.face_retouching_natural,
    'fragrances' => Icons.spa_outlined,
    'furniture' => Icons.chair_outlined,
    'home-decoration' => Icons.local_florist_outlined,
    'groceries' => Icons.local_grocery_store_outlined,
    'kitchen-accessories' => Icons.kitchen_outlined,
    'laptops' => Icons.laptop_outlined,
    'smartphones' || 'mobile-accessories' => Icons.smartphone,
    'tablets' => Icons.tablet_mac_outlined,
    'motorcycle' => Icons.two_wheeler,
    'vehicle' => Icons.directions_car_outlined,
    'sports-accessories' => Icons.sports_basketball_outlined,
    'sunglasses' => Icons.wb_sunny_outlined,
    final s when s.contains('watches') => Icons.watch_outlined,
    final s when s.contains('shoes') => Icons.hiking,
    final s when s.contains('bags') => Icons.shopping_bag_outlined,
    final s when s.contains('jewellery') => Icons.diamond_outlined,
    _ => Icons.checkroom,
  };
}
