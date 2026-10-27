import 'package:product_catalog/features/products/data/product.dart';

/// Test-only data. The app itself always loads products from the API.
Map<String, Object?> productJson(int id, {Object? price = 10}) => {
  'id': id,
  'title': 'Product $id',
  'price': price,
  'description': 'Description of product $id',
  'category': 'home-decoration',
  'discountPercentage': 12.4,
  'rating': 4.56,
  'stock': 45,
  'brand': 'Acme',
  'sku': 'SKU-$id',
  'weight': 4,
  'dimensions': {'width': 10, 'height': 20.5, 'depth': 3},
  'warrantyInformation': '1 year warranty',
  'shippingInformation': 'Ships in 1-2 business days',
  'returnPolicy': '30 days return policy',
  'tags': ['home', 'decor'],
  'reviews': [
    {
      'rating': 5,
      'comment': 'Great!',
      'date': '2025-04-30T09:41:02.053Z',
      'reviewerName': 'Ann',
      'reviewerEmail': 'ann@x.test',
    },
  ],
  'thumbnail': 'https://x.test/$id/thumb.webp',
  'images': ['https://x.test/$id/1.webp', 'https://x.test/$id/2.webp'],
};

Product product(
  int id, {
  double price = 10,
  double discount = 0,
  int? stock = 50,
  double? rating = 4.5,
  List<ProductReview> reviews = const [],
}) => Product(
  id: id,
  title: 'Product $id',
  price: price,
  description: 'Description of product $id',
  categorySlug: 'home-decoration',
  discountPercentage: discount,
  rating: rating,
  stock: stock,
  reviews: reviews,
  // No images, so widget tests never hit the network.
);

/// Products with IDs from [from] to [to], inclusive.
List<Product> products(int from, int to) => [
  for (var id = from; id <= to; id++) product(id),
];
