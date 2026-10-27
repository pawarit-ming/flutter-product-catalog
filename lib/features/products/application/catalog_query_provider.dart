import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_query.dart';

const searchDebounce = Duration(milliseconds: 400);

/// The editable search text, including input not yet sent to the API.
/// Owning the timer here lets category selection on any screen cancel it.
final catalogSearchProvider = NotifierProvider<CatalogSearchNotifier, String>(
  CatalogSearchNotifier.new,
);

class CatalogSearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return ref.read(catalogQueryProvider).search;
  }

  void setText(String text) {
    _replaceText(text);
    _debounce = Timer(searchDebounce, () {
      ref.read(catalogQueryProvider.notifier).setSearch(text);
    });
  }

  /// Replaces the draft immediately, cancelling any pending search.
  void _replaceText(String text) {
    _debounce?.cancel();
    _debounce = null;
    state = text;
  }
}

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
    ref.read(catalogSearchProvider.notifier)._replaceText(text);
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
    // Even reselecting the active category must discard uncommitted input.
    ref.read(catalogSearchProvider.notifier)._replaceText('');
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
