import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_tab_provider.dart';
import '../../products/presentation/widgets/error_view.dart';
import '../../products/presentation/widgets/product_grid.dart';
import '../application/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: products.isEmpty
          ? CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: MessageView(
                    icon: Icons.favorite_border,
                    title: 'ยังไม่มีรายการโปรด',
                    message: 'กดรูปหัวใจบนสินค้าเพื่อบันทึกไว้ที่นี่',
                    action: FilledButton.icon(
                      onPressed: () => ref
                          .read(homeTabProvider.notifier)
                          .select(HomeTab.catalog),
                      icon: const Icon(Icons.storefront_outlined, size: 20),
                      label: const Text('เลือกดูสินค้า'),
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final layout = ProductGridLayout.forWidth(
                      constraints.crossAxisExtent,
                      MediaQuery.textScalerOf(context),
                    );
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.horizontalPadding,
                        vertical: 16,
                      ),
                      sliver: SliverProductGrid(
                        products: products,
                        layout: layout,
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
