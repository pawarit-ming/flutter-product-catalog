import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/features/products/data/product.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a full product and converts an int price to double', () {
      final product = Product.fromJson(productJson(7, price: 44));

      expect(product.id, 7);
      expect(product.title, 'Product 7');
      expect(product.price, 44.0);
      expect(product.price, isA<double>());
      expect(product.description, 'Description of product 7');
      expect(product.category.name, 'Clothes');
      expect(product.imageUrl, 'https://x.test/7.png');
    });

    test('parses a decimal price', () {
      expect(Product.fromJson(productJson(1, price: 19.99)).price, 19.99);
    });

    test('uses defaults for missing optional fields', () {
      final product = Product.fromJson({'id': 1, 'title': 'Bare', 'price': 5});

      expect(product.description, Product.defaultDescription);
      expect(product.category.name, 'Uncategorized');
      expect(product.images, isEmpty);
      expect(product.imageUrl, isNull);
    });

    test('uses defaults for blank description and nameless category', () {
      final product = Product.fromJson({
        ...productJson(1),
        'description': '   ',
        'category': {'id': 3},
      });

      expect(product.description, Product.defaultDescription);
      expect(product.category.name, 'Uncategorized');
    });

    test('keeps only absolute http/https image URLs', () {
      final product = Product.fromJson({
        ...productJson(1),
        'images': [
          'not a url',
          42,
          'ftp://x.test/a.png',
          '/relative.png',
          '["https://x.test/wrapped.png"]',
          'http://x.test/b.png',
        ],
      });

      expect(product.images, [
        'https://x.test/wrapped.png',
        'http://x.test/b.png',
      ]);
    });

    test('treats non-list images as no images', () {
      final product = Product.fromJson({...productJson(1), 'images': 'x'});
      expect(product.images, isEmpty);
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
}
