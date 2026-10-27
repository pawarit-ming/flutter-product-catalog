import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';

/// Upper bound when the API does not report stock.
const maxQuantityWithoutStock = 99;

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.salePrice * quantity;
  double get lineSavings => product.savings * quantity;

  /// How many of this product the cart may hold.
  static int maxQuantityFor(Product product) =>
      product.stock ?? maxQuantityWithoutStock;
}

/// Result of adding to the cart, so the UI can explain what happened.
enum AddToCartResult { added, limitedByStock, outOfStock }

/// Shopping cart kept in memory for this app session. There is no checkout:
/// placing orders is outside the scope of this app.
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity),
);

class CartTotals {
  const CartTotals({required this.subtotal, required this.savings});

  /// What the customer pays (discounted prices).
  final double subtotal;
  final double savings;

  /// Sum of list prices before discounts.
  double get listTotal => subtotal + savings;
}

final cartTotalsProvider = Provider<CartTotals>((ref) {
  final items = ref.watch(cartProvider);
  return CartTotals(
    subtotal: items.fold(0, (sum, item) => sum + item.lineTotal),
    savings: items.fold(0, (sum, item) => sum + item.lineSavings),
  );
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Adds [quantity] units, merging with an existing line and never going
  /// above the available stock.
  AddToCartResult add(Product product, {int quantity = 1}) {
    assert(quantity > 0);
    final max = CartItem.maxQuantityFor(product);
    if (max == 0) return AddToCartResult.outOfStock;

    final current = quantityOf(product.id);
    final wanted = current + quantity;
    final next = wanted.clamp(1, max);
    if (next == current) return AddToCartResult.limitedByStock;

    _put(product, next);
    return next < wanted
        ? AddToCartResult.limitedByStock
        : AddToCartResult.added;
  }

  /// Sets a line's quantity, clamped to stock; 0 or less removes it.
  void setQuantity(int productId, int quantity) {
    final item = _find(productId);
    if (item == null) return;
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    _put(
      item.product,
      quantity.clamp(1, CartItem.maxQuantityFor(item.product)),
    );
  }

  void remove(int productId) {
    state = [
      for (final item in state)
        if (item.product.id != productId) item,
    ];
  }

  void clear() => state = const [];

  int quantityOf(int productId) => _find(productId)?.quantity ?? 0;

  CartItem? _find(int productId) {
    for (final item in state) {
      if (item.product.id == productId) return item;
    }
    return null;
  }

  void _put(Product product, int quantity) {
    final line = CartItem(product: product, quantity: quantity);
    final exists = _find(product.id) != null;
    state = exists
        ? [
            for (final item in state)
              item.product.id == product.id ? line : item,
          ]
        : [...state, line];
  }
}
