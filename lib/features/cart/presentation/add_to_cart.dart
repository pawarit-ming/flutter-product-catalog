import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_tab_provider.dart';
import '../../products/data/product.dart';
import '../application/cart_provider.dart';

/// Adds [product] to the cart and tells the user what happened.
AddToCartResult addToCart(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  int quantity = 1,
}) {
  final result = ref
      .read(cartProvider.notifier)
      .add(product, quantity: quantity);
  final message = switch (result) {
    AddToCartResult.added => 'เพิ่ม "${product.title}" ลงตะกร้าแล้ว',
    AddToCartResult.limitedByStock =>
      'ใส่ได้สูงสุด ${CartItem.maxQuantityFor(product)} ชิ้นตามจำนวนในสต็อก',
    AddToCartResult.outOfStock => 'สินค้าหมด',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // Long product titles must not let the message cover the screen.
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
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
