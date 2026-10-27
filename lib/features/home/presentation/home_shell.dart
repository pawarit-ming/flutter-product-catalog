import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../wishlist/presentation/wishlist_screen.dart';
import '../application/home_tab_provider.dart';

/// Wide enough to swap the bottom bar for a side navigation rail.
const _railMinWidth = 840.0;

/// Top-level tabs. An IndexedStack keeps every tab's state (scroll position,
/// search text) while switching.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    final cartCount = ref.watch(cartCountProvider);
    void select(int index) =>
        ref.read(homeTabProvider.notifier).select(HomeTab.values[index]);

    final cartIcon = Badge(
      isLabelVisible: cartCount > 0,
      label: Text('$cartCount'),
      child: const Icon(Icons.shopping_cart_outlined),
    );
    final destinations = [
      (Icons.grid_view_outlined, Icons.grid_view, 'แคตตาล็อก'),
      (Icons.category_outlined, Icons.category, 'หมวดหมู่'),
      (Icons.favorite_border, Icons.favorite, 'รายการโปรด'),
    ];

    const body = [
      ProductListScreen(),
      CategoriesScreen(),
      WishlistScreen(),
      CartScreen(),
    ];
    final stack = IndexedStack(
      index: tab.index,
      children: [
        // Hidden tabs keep their state but stop animating.
        for (var i = 0; i < body.length; i++)
          TickerMode(enabled: i == tab.index, child: body[i]),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _railMinWidth) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: tab.index,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final (icon, selectedIcon, label) in destinations)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(selectedIcon),
                          label: Text(label),
                        ),
                      NavigationRailDestination(
                        icon: cartIcon,
                        label: const Text('ตะกร้า'),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: stack),
              ],
            ),
          );
        }
        return Scaffold(
          body: stack,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: select,
            destinations: [
              for (final (icon, selectedIcon, label) in destinations)
                NavigationDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: label,
                ),
              NavigationDestination(icon: cartIcon, label: 'ตะกร้า'),
            ],
          ),
        );
      },
    );
  }
}
