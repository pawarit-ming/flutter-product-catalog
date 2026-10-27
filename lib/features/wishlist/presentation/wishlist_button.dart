import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';
import '../application/wishlist_provider.dart';

/// Heart toggle for a product. [onImage] adds a background so it stays
/// visible on top of product photos.
class WishlistButton extends ConsumerWidget {
  const WishlistButton({
    super.key,
    required this.product,
    this.onImage = false,
  });

  final Product product;
  final bool onImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final saved = ref.watch(isInWishlistProvider(product.id));
    return IconButton(
      tooltip: saved ? 'นำออกจากรายการโปรด' : 'เพิ่มในรายการโปรด',
      isSelected: saved,
      style: onImage
          ? IconButton.styleFrom(
              backgroundColor: colors.surface.withValues(alpha: 0.85),
            )
          : null,
      onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite, color: colors.error),
    );
  }
}
