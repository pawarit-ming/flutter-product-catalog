import 'package:product_catalog/features/products/data/product.dart';
import 'package:product_catalog/features/products/data/product_category.dart';

/// Test-only data. The app itself always loads products from the API.
Map<String, Object?> productJson(int id, {Object? price = 10}) => {
  'id': id,
  'title': 'Product $id',
  'price': price,
  'description': 'Description of product $id',
  'category': {'id': 1, 'name': 'Clothes', 'image': 'https://x.test/c.png'},
  'images': ['https://x.test/$id.png'],
};

Product product(int id, {double price = 10}) => Product(
  id: id,
  title: 'Product $id',
  price: price,
  description: 'Description of product $id',
  category: const ProductCategory(name: 'Clothes'),
  // No images, so widget tests never hit the network.
  images: const [],
);

/// Products with IDs from [from] to [to], inclusive.
List<Product> products(int from, int to) => [
  for (var id = from; id <= to; id++) product(id),
];
