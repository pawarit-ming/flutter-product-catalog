import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shopping_storage.dart';
import '../../products/data/product.dart';

/// Favourite products, newest first, restored from this device.
final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(
  WishlistNotifier.new,
);

/// Whether one product is in the wishlist; rebuilds only when that changes.
final isInWishlistProvider = Provider.family<bool, int>(
  (ref, productId) =>
      ref.watch(wishlistProvider.select((list) => _contains(list, productId))),
);

bool _contains(List<Product> list, int id) => list.any((p) => p.id == id);

class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    final storage = ref.watch(shoppingStorageProvider);
    final products = <Product>[];
    final seen = <int>{};
    for (final raw in storage.readList(wishlistStorageKey)) {
      try {
        final product = Product.fromJson(raw);
        if (seen.add(product.id)) products.add(product);
      } on FormatException {
        storage.reportInvalidData();
      }
    }
    return List.unmodifiable(products);
  }

  void _commit(List<Product> products) {
    state = List.unmodifiable(products);
    ref.read(shoppingStorageProvider).writeList(wishlistStorageKey, [
      for (final product in products) product.toJson(),
    ]);
  }

  /// Adds or removes [product]; returns true when it is now in the wishlist.
  bool toggle(Product product) {
    if (_contains(state, product.id)) {
      _commit([
        for (final p in state)
          if (p.id != product.id) p,
      ]);
      return false;
    }
    _commit([product, ...state]);
    return true;
  }
}
