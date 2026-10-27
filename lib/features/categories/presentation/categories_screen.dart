import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
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
        data: (list) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final category = list[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconFor(category.slug), size: 20),
                  ),
                  title: Text(category.name),
                  selected: category.slug == selected,
                  trailing: const Icon(Icons.chevron_right),
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
