import '../../../core/formatting/price_format.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.categorySlug,
    this.discountPercentage = 0,
    this.rating,
    this.stock,
    this.brand,
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.returnPolicy,
    this.tags = const [],
    this.thumbnail,
    this.images = const [],
    this.reviews = const [],
  });

  static const defaultDescription = 'ไม่มีคำอธิบายสินค้า';
  static const uncategorized = 'uncategorized';

  /// Parses one product from the API.
  ///
  /// `id`, `title` and `price` are required: if any is missing or has the
  /// wrong type a [FormatException] is thrown instead of inventing a value.
  /// Everything else is optional and falls back to "unknown" or a default.
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

    final discount = _num(json['discountPercentage']);
    final rating = _num(json['rating']);
    final stock = json['stock'];
    final reviews = json['reviews'];

    return Product(
      id: id,
      title: title.trim(),
      price: price.toDouble(),
      description: _string(json['description']) ?? defaultDescription,
      categorySlug: _string(json['category']) ?? uncategorized,
      discountPercentage: discount == null ? 0 : discount.clamp(0.0, 100.0),
      rating: rating?.clamp(0.0, 5.0),
      stock: stock is int && stock >= 0 ? stock : null,
      brand: _string(json['brand']),
      sku: _string(json['sku']),
      weight: _num(json['weight']),
      dimensions: ProductDimensions.fromJson(json['dimensions']),
      warrantyInformation: _string(json['warrantyInformation']),
      shippingInformation: _string(json['shippingInformation']),
      returnPolicy: _string(json['returnPolicy']),
      tags: [
        if (json['tags'] case final List tags)
          for (final tag in tags)
            if (tag is String && tag.trim().isNotEmpty) tag.trim(),
      ],
      thumbnail: parseImageUrls([json['thumbnail']]).firstOrNull,
      images: parseImageUrls(json['images']),
      reviews: [
        if (reviews is List)
          for (final review in reviews) ?ProductReview.fromJson(review),
      ],
    );
  }

  final int id;
  final String title;

  /// List price from the API, before the discount.
  final double price;
  final String description;
  final String categorySlug;
  final double discountPercentage;
  final double? rating;

  /// `null` when the API does not say; 0 means out of stock.
  final int? stock;
  final String? brand;
  final String? sku;
  final double? weight;
  final ProductDimensions? dimensions;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? returnPolicy;
  final List<String> tags;
  final String? thumbnail;

  /// Only absolute http/https URLs; may be empty.
  final List<String> images;
  final List<ProductReview> reviews;

  String get categoryName => humanizeSlug(categorySlug);

  /// Whole-percent discount shown on badges; 0 when there is no real discount.
  int get discountBadge => discountPercentage.round();

  bool get hasDiscount => discountBadge > 0;

  /// Price after the discount, rounded to cents (the API's own carts compute
  /// discounted totals the same way).
  double get salePrice =>
      (price * (1 - discountPercentage / 100) * 100).round() / 100;

  double get savings => price - salePrice;

  bool get isOutOfStock => stock == 0;

  /// Card image: the thumbnail if present, otherwise the first image.
  String? get cardImageUrl => thumbnail ?? images.firstOrNull;

  /// Images for the detail gallery, falling back to the thumbnail.
  List<String> get galleryImages => images.isNotEmpty ? images : [?thumbnail];

  /// Keeps only strings that are absolute http/https URLs with a host.
  static List<String> parseImageUrls(Object? raw) {
    if (raw is! List) return const [];
    final urls = <String>[];
    for (final item in raw) {
      if (item is! String) continue;
      final cleaned = item.trim();
      final uri = Uri.tryParse(cleaned);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty) {
        urls.add(cleaned);
      }
    }
    return List.unmodifiable(urls);
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static double? _num(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}

class ProductDimensions {
  const ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  static ProductDimensions? fromJson(Object? json) {
    if (json is! Map) return null;
    final width = json['width'];
    final height = json['height'];
    final depth = json['depth'];
    if (width is! num || height is! num || depth is! num) return null;
    return ProductDimensions(
      width: width.toDouble(),
      height: height.toDouble(),
      depth: depth.toDouble(),
    );
  }

  final double width;
  final double height;
  final double depth;
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  /// Reviews are optional extras: a malformed one is skipped (returns null)
  /// rather than failing the whole product.
  static ProductReview? fromJson(Object? json) {
    if (json is! Map) return null;
    final rating = json['rating'];
    final comment = json['comment'];
    final name = json['reviewerName'];
    if (rating is! num || comment is! String || name is! String) return null;
    final date = json['date'];
    return ProductReview(
      rating: rating.toDouble().clamp(0.0, 5.0),
      comment: comment.trim(),
      reviewerName: name.trim(),
      date: date is String ? DateTime.tryParse(date) : null,
    );
  }

  final double rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;
}
