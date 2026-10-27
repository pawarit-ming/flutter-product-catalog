import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/features/products/data/product.dart';
import 'package:product_catalog/features/products/data/product_category.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('Product.fromJson', () {
    test('parses every field the UI uses', () {
      final product = Product.fromJson(productJson(7, price: 44));

      expect(product.id, 7);
      expect(product.title, 'Product 7');
      expect(product.price, 44.0);
      expect(product.price, isA<double>());
      expect(product.categorySlug, 'home-decoration');
      expect(product.categoryName, 'Home Decoration');
      expect(product.discountPercentage, 12.4);
      expect(product.rating, 4.56);
      expect(product.stock, 45);
      expect(product.brand, 'Acme');
      expect(product.sku, 'SKU-7');
      expect(product.weight, 4);
      expect(product.dimensions?.height, 20.5);
      expect(product.warrantyInformation, '1 year warranty');
      expect(product.returnPolicy, '30 days return policy');
      expect(product.tags, ['home', 'decor']);
      expect(product.cardImageUrl, 'https://x.test/7/thumb.webp');
      expect(product.galleryImages, hasLength(2));
      expect(product.reviews.single.reviewerName, 'Ann');
      expect(
        product.reviews.single.date,
        DateTime.utc(2025, 4, 30, 9, 41, 2, 53),
      );
    });

    test('computes the sale price from the list price and discount', () {
      final product = Product.fromJson({
        ...productJson(1, price: 100),
        'discountPercentage': 12.4,
      });

      expect(product.salePrice, 87.6);
      expect(product.savings, closeTo(12.4, 0.001));
      expect(product.discountBadge, 12);
      expect(product.hasDiscount, isTrue);
    });

    test('treats a discount that rounds to 0% as no discount', () {
      final product = Product.fromJson({
        ...productJson(1),
        'discountPercentage': 0.04,
      });
      expect(product.hasDiscount, isFalse);
    });

    test('uses defaults for missing optional fields', () {
      final product = Product.fromJson({'id': 1, 'title': 'Bare', 'price': 5});

      expect(product.description, Product.defaultDescription);
      expect(product.categorySlug, Product.uncategorized);
      expect(product.discountPercentage, 0);
      expect(product.salePrice, 5);
      expect(product.rating, isNull);
      expect(product.stock, isNull);
      expect(product.isOutOfStock, isFalse);
      expect(product.brand, isNull);
      expect(product.dimensions, isNull);
      expect(product.images, isEmpty);
      expect(product.cardImageUrl, isNull);
      expect(product.galleryImages, isEmpty);
      expect(product.reviews, isEmpty);
    });

    test('stock 0 means out of stock', () {
      final product = Product.fromJson({...productJson(1), 'stock': 0});
      expect(product.isOutOfStock, isTrue);
    });

    test('falls back to the thumbnail when there are no images', () {
      final product = Product.fromJson({...productJson(1), 'images': []});
      expect(product.galleryImages, ['https://x.test/1/thumb.webp']);
    });

    test('keeps only absolute http/https image URLs', () {
      final product = Product.fromJson({
        ...productJson(1),
        'images': [
          'not a url',
          42,
          'ftp://x.test/a.png',
          '/relative.png',
          'http://x.test/b.png',
        ],
      });

      expect(product.images, ['http://x.test/b.png']);
    });

    test('skips malformed reviews but keeps the product', () {
      final product = Product.fromJson({
        ...productJson(1),
        'reviews': [
          {'rating': 'five'},
          {'rating': 4, 'comment': 'Nice', 'reviewerName': 'Bo'},
        ],
      });
      expect(product.reviews.single.reviewerName, 'Bo');
    });

    final invalid = <String, Map<String, Object?>>{
      'missing id': {...productJson(1)}..remove('id'),
      'string id': {...productJson(1), 'id': '1'},
      'missing title': {...productJson(1)}..remove('title'),
      'blank title': {...productJson(1), 'title': '  '},
      'missing price': {...productJson(1)}..remove('price'),
      'string price': {...productJson(1), 'price': '10'},
      'negative price': {...productJson(1), 'price': -1},
    };
    invalid.forEach((name, json) {
      test('rejects $name instead of inventing a value', () {
        expect(() => Product.fromJson(json), throwsFormatException);
      });
    });

    test('rejects a non-object', () {
      expect(() => Product.fromJson([1]), throwsFormatException);
    });
  });

  group('ProductCategory.fromJson', () {
    test('reads slug and name', () {
      final category = ProductCategory.fromJson({
        'slug': 'skin-care',
        'name': 'Skin Care',
      });
      expect(category.slug, 'skin-care');
      expect(category.name, 'Skin Care');
    });

    test('derives a name from the slug when missing', () {
      expect(
        ProductCategory.fromJson({'slug': 'mens-shoes'}).name,
        'Mens Shoes',
      );
    });

    test('rejects a missing slug', () {
      expect(
        () => ProductCategory.fromJson({'name': 'X'}),
        throwsFormatException,
      );
    });
  });
}
