import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shopping_storage.dart';
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

/// A removal can be undone once, until a newer removal or clear supersedes it.
class CartRemoval {
  const CartRemoval._(this.item, this.index, this._revision);

  final CartItem item;
  final int index;
  final int _revision;
}

/// Result of adding to the cart, so the UI can explain what happened.
enum AddToCartResult { added, limitedByStock, outOfStock }

/// Shopping cart restored from this device. There is no checkout:
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
  int _removalRevision = 0;

  @override
  List<CartItem> build() {
    final storage = ref.watch(shoppingStorageProvider);
    final restored = <int, CartItem>{};
    for (final raw in storage.readList(cartStorageKey)) {
      try {
        if (raw is! Map || raw['quantity'] is! int) {
          throw const FormatException('Invalid saved cart item');
        }
        final product = Product.fromJson(raw['product']);
        final quantity = raw['quantity'] as int;
        if (quantity <= 0) throw const FormatException('Invalid quantity');
        final max = CartItem.maxQuantityFor(product);
        if (max == 0) continue;
        final previous = restored[product.id]?.quantity ?? 0;
        restored[product.id] = CartItem(
          product: product,
          quantity: (previous + quantity).clamp(1, max),
        );
      } on FormatException {
        storage.reportInvalidData();
      }
    }
    return List.unmodifiable(restored.values);
  }

  void _commit(List<CartItem> items) {
    state = List.unmodifiable(items);
    ref.read(shoppingStorageProvider).writeList(cartStorageKey, [
      for (final item in items)
        {'product': item.product.toJson(), 'quantity': item.quantity},
    ]);
  }

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
    _removalRevision++;
    _commit([
      for (final item in state)
        if (item.product.id != productId) item,
    ]);
  }

  CartRemoval? removeWithUndo(int productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index < 0) return null;
    final item = state[index];
    remove(productId);
    return CartRemoval._(item, index, _removalRevision);
  }

  /// Preserve later edits and re-added products instead of replacing them
  /// with an older snapshot. Clearing the cart also invalidates pending Undo.
  bool undoRemoval(CartRemoval removal) {
    if (removal._revision != _removalRevision) return false;
    _removalRevision++;
    final product = removal.item.product;
    if (_find(product.id) != null) return false;
    final max = CartItem.maxQuantityFor(product);
    if (max <= 0) return false;
    final restored = CartItem(
      product: product,
      quantity: removal.item.quantity.clamp(1, max),
    );
    final items = [...state];
    items.insert(removal.index.clamp(0, items.length), restored);
    _commit(items);
    return true;
  }

  void clear() {
    _removalRevision++;
    _commit(const []);
  }

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
    _commit(
      exists
          ? [
              for (final item in state)
                item.product.id == product.id ? line : item,
            ]
          : [...state, line],
    );
  }
}
