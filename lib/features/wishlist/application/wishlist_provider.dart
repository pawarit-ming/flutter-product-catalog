import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';

/// Favourite products, newest first. Kept in memory for this app session.
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
  List<Product> build() => const [];

  /// Adds or removes [product]; returns true when it is now in the wishlist.
  bool toggle(Product product) {
    if (_contains(state, product.id)) {
      state = [
        for (final p in state)
          if (p.id != product.id) p,
      ];
      return false;
    }
    state = [product, ...state];
    return true;
  }
}
