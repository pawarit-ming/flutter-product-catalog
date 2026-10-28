import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../products/data/product.dart';
import '../application/wishlist_provider.dart';

/// Heart toggle for a product.
class WishlistButton extends ConsumerWidget {
  const WishlistButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final saved = ref.watch(isInWishlistProvider(product.id));
    return IconButton(
      tooltip: saved ? 'นำออกจากรายการโปรด' : 'เพิ่มในรายการโปรด',
      isSelected: saved,
      iconSize: 22,
      onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
      icon: Icon(Icons.favorite_border, color: colors.onSurfaceVariant),
      selectedIcon: Icon(Icons.favorite, color: CatalogColors.of(context).sale),
    );
  }
}
