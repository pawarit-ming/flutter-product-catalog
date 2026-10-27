import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/features/cart/application/cart_provider.dart';
import 'package:product_catalog/features/products/application/catalog_query_provider.dart';
import 'package:product_catalog/features/products/data/catalog_query.dart';
import 'package:product_catalog/features/wishlist/application/wishlist_provider.dart';

import '../../helpers/fixtures.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer.test());

  group('cart', () {
    CartNotifier cart() => container.read(cartProvider.notifier);
    List<CartItem> items() => container.read(cartProvider);

    test('adding the same product merges into one line', () {
      expect(cart().add(product(1)), AddToCartResult.added);
      expect(cart().add(product(1), quantity: 2), AddToCartResult.added);

      expect(items().single.quantity, 3);
      expect(container.read(cartCountProvider), 3);
    });

    test('never goes above the available stock', () {
      final limited = product(1, stock: 3);

      expect(cart().add(limited, quantity: 2), AddToCartResult.added);
      expect(cart().add(limited, quantity: 5), AddToCartResult.limitedByStock);
      expect(items().single.quantity, 3);
      expect(cart().add(limited), AddToCartResult.limitedByStock);
      expect(items().single.quantity, 3);
    });

    test('ignores products that are out of stock', () {
      expect(cart().add(product(1, stock: 0)), AddToCartResult.outOfStock);
      expect(items(), isEmpty);
    });

    test('caps unknown stock at $maxQuantityWithoutStock', () {
      cart().add(product(1, stock: null), quantity: 500);
      expect(items().single.quantity, maxQuantityWithoutStock);
    });

    test('setQuantity clamps, and 0 removes the line', () {
      cart().add(product(1, stock: 5));
      cart().setQuantity(1, 9);
      expect(items().single.quantity, 5);

      cart().setQuantity(1, 0);
      expect(items(), isEmpty);
    });

    test('totals use the discounted price', () {
      cart().add(product(1, price: 100, discount: 10), quantity: 2);
      cart().add(product(2, price: 50));

      final totals = container.read(cartTotalsProvider);
      expect(totals.subtotal, 230);
      expect(totals.savings, 20);
      expect(totals.listTotal, 250);
    });

    test('remove and clear', () {
      cart().add(product(1));
      cart().add(product(2));
      cart().remove(1);
      expect(items().map((i) => i.product.id), [2]);

      cart().clear();
      expect(items(), isEmpty);
      expect(container.read(cartCountProvider), 0);
    });
  });

  group('wishlist', () {
    test('toggle adds newest first and removes again', () {
      final wishlist = container.read(wishlistProvider.notifier);

      expect(wishlist.toggle(product(1)), isTrue);
      expect(wishlist.toggle(product(2)), isTrue);
      expect(container.read(wishlistProvider).map((p) => p.id), [2, 1]);
      expect(container.read(isInWishlistProvider(1)), isTrue);

      expect(wishlist.toggle(product(1)), isFalse);
      expect(container.read(isInWishlistProvider(1)), isFalse);
      expect(container.read(wishlistProvider).map((p) => p.id), [2]);
    });
  });

  group('catalog query', () {
    CatalogQueryNotifier query() =>
        container.read(catalogQueryProvider.notifier);
    CatalogQuery state() => container.read(catalogQueryProvider);

    test('search clears the category and trims the text', () {
      query().setCategory('beauty');
      query().setSearch('  lipstick ');

      expect(state().search, 'lipstick');
      expect(state().categorySlug, isNull);
    });

    test('choosing a category clears the search but keeps the sort', () {
      query().setSort(ProductSort.priceHighToLow);
      query().setSearch('phone');
      query().setCategory('laptops');

      expect(state().search, isEmpty);
      expect(state().categorySlug, 'laptops');
      expect(state().sort, ProductSort.priceHighToLow);
    });

    test('clearing the search keeps the current category', () {
      query().setCategory('laptops');
      query().setSearch('');
      expect(state().categorySlug, 'laptops');
    });
  });
}
