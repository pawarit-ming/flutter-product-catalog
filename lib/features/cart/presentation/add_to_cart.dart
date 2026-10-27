import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_tab_provider.dart';
import '../../products/data/product.dart';
import '../application/cart_provider.dart';
import 'cart_feedback.dart';

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
        padding: cartFeedbackPadding,
        content: CartFeedbackContent(product: product, headline: headline),
        // A SnackBar with an action stays until dismissed by default; this one
        // is only a confirmation, so let it time out.
        persist: false,
        duration: const Duration(seconds: 3),
        action: result == AddToCartResult.outOfStock
            ? null
            : cartFeedbackAction(
                context,
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
