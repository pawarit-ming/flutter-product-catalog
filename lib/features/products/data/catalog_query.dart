/// Sort orders supported by the API (`sortBy` + `order`).
enum ProductSort {
  recommended(null, null),
  priceLowToHigh('price', 'asc'),
  priceHighToLow('price', 'desc'),
  ratingHighToLow('rating', 'desc'),
  titleAToZ('title', 'asc');

  const ProductSort(this.sortBy, this.order);

  final String? sortBy;
  final String? order;
}

/// What the catalog is currently showing.
///
/// The API cannot combine a text search with a category filter, so at most
/// one of [search] and [categorySlug] is set.
class CatalogQuery {
  const CatalogQuery({
    this.search = '',
    this.categorySlug,
    this.sort = ProductSort.recommended,
  }) : assert(search == '' || categorySlug == null);

  final String search;
  final String? categorySlug;
  final ProductSort sort;

  bool get isSearching => search.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is CatalogQuery &&
      other.search == search &&
      other.categorySlug == categorySlug &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(search, categorySlug, sort);
}
