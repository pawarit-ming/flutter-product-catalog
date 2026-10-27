import 'product_category.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.images,
  });

  static const defaultDescription = 'No description available';

  /// Parses one product from the API.
  ///
  /// `id`, `title` and `price` are required: if any is missing or has the
  /// wrong type a [FormatException] is thrown instead of inventing a value.
  /// Optional fields fall back to safe defaults.
  factory Product.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Product must be a JSON object');
    }

    final id = json['id'];
    if (id is! int) throw const FormatException('Product id must be an int');

    final title = json['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Product title must be a non-empty string');
    }

    final price = json['price'];
    if (price is! num || !price.isFinite || price < 0) {
      throw const FormatException('Product price must be a non-negative num');
    }

    final description = json['description'];

    return Product(
      id: id,
      title: title.trim(),
      price: price.toDouble(),
      description: description is String && description.trim().isNotEmpty
          ? description.trim()
          : defaultDescription,
      category: ProductCategory.fromJson(json['category']),
      images: parseImageUrls(json['images']),
    );
  }

  final int id;
  final String title;
  final double price;
  final String description;
  final ProductCategory category;

  /// Only absolute http/https URLs; may be empty.
  final List<String> images;

  String? get imageUrl => images.isEmpty ? null : images.first;

  /// Keeps only strings that are absolute http/https URLs with a host.
  ///
  /// Some records on the public API wrap URLs in stray brackets or quotes
  /// (for example `["https://..."]`), so those characters are trimmed first.
  static List<String> parseImageUrls(Object? raw) {
    if (raw is! List) return const [];
    final urls = <String>[];
    for (final item in raw) {
      if (item is! String) continue;
      final cleaned = item.trim().replaceAll(_wrapperChars, '');
      final uri = Uri.tryParse(cleaned);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty) {
        urls.add(cleaned);
      }
    }
    return List.unmodifiable(urls);
  }

  static final _wrapperChars = RegExp(r'^[\[\s"]+|[\]\s"]+$');
}
