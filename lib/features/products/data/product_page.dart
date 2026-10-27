import 'product.dart';

/// One page of products, built by the repository from the response and the
/// request parameters (the API itself only returns a JSON array).
class ProductPage {
  const ProductPage({
    required this.items,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<Product> items;

  /// Request offset plus the number of raw items received (before any
  /// de-duplication), so retries and next pages never skip positions.
  final int nextOffset;

  /// False once a page returns fewer items than requested (including empty).
  final bool hasMore;
}
