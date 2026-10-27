import 'product.dart';

/// One page of products plus the cursor for the next request.
class ProductPage {
  const ProductPage({
    required this.items,
    required this.nextOffset,
    required this.total,
    required this.hasMore,
  });

  final List<Product> items;

  /// Request offset plus the number of raw items received (before any
  /// de-duplication), so retries and next pages never skip positions.
  final int nextOffset;

  /// Total number of matching products reported by the API.
  final int total;

  /// False once the cursor reaches [total] or a page comes back empty.
  final bool hasMore;
}
