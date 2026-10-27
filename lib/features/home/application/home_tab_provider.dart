import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { catalog, categories, wishlist, cart }

/// The selected tab, so other screens (e.g. opening the cart, picking a category)
/// can switch tabs.
final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.catalog;

  void select(HomeTab tab) => state = tab;
}
