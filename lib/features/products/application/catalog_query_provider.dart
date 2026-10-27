import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_query.dart';

/// Search text, category and sort for the catalog. The product list watches
/// this, so every change reloads the list from the first page.
final catalogQueryProvider =
    NotifierProvider<CatalogQueryNotifier, CatalogQuery>(
      CatalogQueryNotifier.new,
    );

class CatalogQueryNotifier extends Notifier<CatalogQuery> {
  @override
  CatalogQuery build() => const CatalogQuery();

  /// Searching covers all categories (the API cannot combine the two).
  void setSearch(String text) {
    final search = text.trim();
    if (search == state.search) return;
    state = CatalogQuery(
      search: search,
      categorySlug: search.isEmpty ? state.categorySlug : null,
      sort: state.sort,
    );
  }

  /// Picking a category clears the search. `null` means all categories.
  void setCategory(String? slug) {
    if (slug == state.categorySlug && !state.isSearching) return;
    state = CatalogQuery(categorySlug: slug, sort: state.sort);
  }

  void setSort(ProductSort sort) {
    if (sort == state.sort) return;
    state = CatalogQuery(
      search: state.search,
      categorySlug: state.categorySlug,
      sort: sort,
    );
  }
}
