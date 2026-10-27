class ProductCategory {
  const ProductCategory({required this.name, this.id, this.image});

  static const uncategorized = ProductCategory(name: 'Uncategorized');

  /// Falls back to [uncategorized] when the category is missing or has no
  /// usable name, because it is optional information for the UI.
  factory ProductCategory.fromJson(Object? json) {
    if (json is! Map) return uncategorized;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return uncategorized;
    final id = json['id'];
    final image = json['image'];
    return ProductCategory(
      id: id is int ? id : null,
      name: name.trim(),
      image: image is String ? image : null,
    );
  }

  final int? id;
  final String name;
  final String? image;
}
