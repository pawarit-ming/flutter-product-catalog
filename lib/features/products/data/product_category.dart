import '../../../core/formatting/price_format.dart';

class ProductCategory {
  const ProductCategory({required this.slug, required this.name});

  factory ProductCategory.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Category must be a JSON object');
    }
    final slug = json['slug'];
    if (slug is! String || slug.trim().isEmpty) {
      throw const FormatException('Category slug must be a non-empty string');
    }
    final name = json['name'];
    return ProductCategory(
      slug: slug.trim(),
      name: name is String && name.trim().isNotEmpty
          ? name.trim()
          : humanizeSlug(slug),
    );
  }

  final String slug;
  final String name;
}
