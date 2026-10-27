import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/application/home_tab_provider.dart';
import '../../products/data/product.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../application/cart_provider.dart';

/// Adds [product] to the cart and confirms it with a compact SnackBar
/// showing the product thumbnail, what happened, and a shortcut to the cart.
AddToCartResult addToCart(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  int quantity = 1,
}) {
  final result = ref
      .read(cartProvider.notifier)
      .add(product, quantity: quantity);
  final headline = switch (result) {
    AddToCartResult.added =>
      quantity > 1 ? 'เพิ่มลงตะกร้าแล้ว · $quantity ชิ้น' : 'เพิ่มลงตะกร้าแล้ว',
    AddToCartResult.limitedByStock =>
      'ใส่ได้สูงสุด ${CartItem.maxQuantityFor(product)} ชิ้นตามสต็อก',
    AddToCartResult.outOfStock => 'สินค้าหมด',
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.xs,
          AppSpace.sm,
        ),
        content: _CartConfirmation(product: product, headline: headline),
        // A SnackBar with an action stays until dismissed by default; this one
        // is only a confirmation, so let it time out.
        persist: false,
        duration: const Duration(seconds: 3),
        action: result == AddToCartResult.outOfStock
            ? null
            : SnackBarAction(
                label: 'ดูตะกร้า',
                onPressed: () => showCart(context, ref),
              ),
      ),
    );
  return result;
}

/// Switches to the cart tab and closes any pushed pages.
void showCart(BuildContext context, WidgetRef ref) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ref.read(homeTabProvider.notifier).select(HomeTab.cart);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class _CartConfirmation extends StatelessWidget {
  const _CartConfirmation({required this.product, required this.headline});

  final Product product;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onInverseSurface;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
          child: SizedBox.square(
            dimension: 44,
            child: ExcludeSemantics(
              child: ProductImage(
                url: product.cardImageUrl,
                label: product.title,
                padding: AppSpace.xs,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
