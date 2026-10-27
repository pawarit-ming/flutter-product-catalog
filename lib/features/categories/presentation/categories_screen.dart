import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/application/home_tab_provider.dart';
import '../../products/application/catalog_query_provider.dart';
import '../../products/application/categories_provider.dart';
import '../../products/presentation/widgets/error_view.dart';

/// All categories from the API; picking one filters the catalog tab.
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
        data: (list) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          itemCount: list.length,
          separatorBuilder: (_, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Divider(indent: 72),
            ),
          ),
          itemBuilder: (context, index) {
            final category = list[index];
            final isSelected = category.slug == selected;
            final colors = Theme.of(context).colorScheme;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListTile(
                  minVerticalPadding: AppSpace.md,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      _iconFor(category.slug),
                      size: 20,
                      color: colors.onSurface,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  trailing: Icon(
                    isSelected ? Icons.check : Icons.chevron_right,
                    size: 20,
                  ),
                  onTap: () {
                    ref
                        .read(catalogQueryProvider.notifier)
                        .setCategory(category.slug);
                    ref.read(homeTabProvider.notifier).select(HomeTab.catalog);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static IconData _iconFor(String slug) => switch (slug) {
    'beauty' || 'skin-care' => Icons.face_retouching_natural,
    'fragrances' => Icons.spa_outlined,
    'furniture' || 'home-decoration' => Icons.chair_outlined,
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
