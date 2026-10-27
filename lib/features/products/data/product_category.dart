import '../../../core/formatting/price_format.dart';
import 'thai_labels.dart';

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

  /// The name the API sends, in English.
  final String name;

  /// What the app shows: the Thai name when the category is known.
  String get label => thaiCategoryName(slug, fallback: name);
}
