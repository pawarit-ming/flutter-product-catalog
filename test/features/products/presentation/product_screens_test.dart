import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/app.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/core/riverpod/no_retry.dart';
import 'package:product_catalog/features/products/application/catalog_query_provider.dart';
import 'package:product_catalog/features/products/data/catalog_query.dart';
import 'package:product_catalog/features/products/data/product.dart';
import 'package:product_catalog/features/products/data/product_category.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';
import 'package:product_catalog/features/products/presentation/product_list_screen.dart';
import 'package:product_catalog/features/products/presentation/widgets/product_card.dart';
import 'package:product_catalog/features/products/presentation/widgets/product_grid.dart';

import '../../../helpers/fake_product_repository.dart';
import '../../../helpers/fixtures.dart';

void main() {
  late FakeProductRepository repository;

  setUp(() => repository = FakeProductRepository());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        retry: noRetry,
        child: const ProductCatalogApp(),
      ),
    );
  }

  /// Starts the app and completes the first page with [items].
  Future<void> pumpLoaded(WidgetTester tester, List<Product> items) async {
    await pumpApp(tester);
    repository.listRequests.single.succeed(items);
    await tester.pumpAndSettle();
  }

  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Scrolls the catalog until [finder] is fully on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ProductListScreen),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Scrolls whatever contains [finder] until it is on screen, then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  /// The cart buttons on product cards. Found by icon rather than tooltip,
  /// because a tooltip's reported centre need not lie on its button.
  final addToCartButtons = find.widgetWithIcon(
    IconButton,
    Icons.add_shopping_cart_outlined,
  );

  /// Finishes a page transition without waiting for a loading spinner, which
  /// never settles while its request is pending.
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  ScrollPosition listPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ProductListScreen),
              matching: find.byType(Scrollable),
            )
            .last,
      )
      .position;

  Finder navItem(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  group('product list', () {
    testWidgets('shows a skeleton, then names, prices and the count', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('product-skeleton')), findsOneWidget);

      repository.listRequests.single.succeed([
        product(1, price: 100, discount: 12),
        product(2, price: 9.5),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text(r'$88.00'), findsOneWidget);
      // The struck-through list price only shows when it fits beside the
      // sale price; the wide test font hides it here (checked on detail).
      expect(find.text('-12%'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
      expect(find.text(r'$9.50'), findsOneWidget);
      expect(find.text('แสดง 2 จาก 2 รายการ'), findsOneWidget);
      expect(find.text('มีสินค้า'), findsNWidgets(2));
      await scrollTo(tester, find.text('แสดงครบทุกรายการแล้ว'));
    });

    testWidgets('error state retries the initial load', (tester) async {
      await pumpApp(tester);
      repository.listRequests.single.fail(AppErrorType.network);
      await tester.pumpAndSettle();

      expect(
        find.text(AppException(AppErrorType.network).message),
        findsOneWidget,
      );

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pump();
      expect(repository.listRequests, hasLength(2));
      expect(find.byKey(const Key('product-skeleton')), findsOneWidget);

      repository.listRequests.last.succeed(products(1, 3));
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
    });

    testWidgets('error state can be pulled to refresh', (tester) async {
      await pumpApp(tester);
      repository.listRequests.single.fail(AppErrorType.server);
      await tester.pumpAndSettle();

      await pullToRefresh(tester);
      expect(repository.listRequests, hasLength(2));

      repository.listRequests.last.succeed(products(1, 3));
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
    });

    testWidgets('empty state can be refreshed; a failure shows once', (
      tester,
    ) async {
      await pumpLoaded(tester, []);
      expect(find.text('ไม่พบสินค้า'), findsOneWidget);

      await pullToRefresh(tester);
      expect(repository.listRequests, hasLength(2));
      repository.listRequests.last.fail(AppErrorType.timeout);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('รีเฟรชไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ไม่พบสินค้า'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('load more shows a spinner, then retry after a failure', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 20));

      await scrollTo(tester, find.text('โหลดเพิ่มเติม'));
      await tester.tap(find.text('โหลดเพิ่มเติม'));
      await tester.pump();
      expect(repository.listRequests.last.offset, 20);

      repository.listRequests.last.fail(AppErrorType.network);
      await tester.pumpAndSettle();
      expect(find.text('Product 20'), findsOneWidget, reason: 'items kept');
      await scrollTo(tester, find.text('ลองอีกครั้ง'));

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pump();
      expect(repository.listRequests.last.offset, 20);
      repository.listRequests.last.succeed(products(21, 25));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Product 25'));
      expect(find.text('โหลดเพิ่มเติม'), findsNothing);
    });
  });

  group('search, category and sort', () {
    testWidgets('clearing a pending search cancels it immediately', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 3));
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byTooltip('ล้างการค้นหา'));
      await tester.pump(searchDebounce);

      expect(repository.listRequests, hasLength(1));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byTooltip('ล้างการค้นหา'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('disposing the app cancels a pending search', (tester) async {
      await pumpLoaded(tester, products(1, 3));
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(searchDebounce);

      expect(repository.listRequests, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('category tab cancels a pending search', (tester) async {
      await pumpLoaded(tester, products(1, 3));
      repository.categoryRequests.single.complete(const [
        ProductCategory(slug: 'beauty', name: 'Beauty'),
      ]);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(navItem('หมวดหมู่'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ListTile, 'Beauty'));
      await tester.pump();
      repository.listRequests.last.succeed(products(4, 6));
      await tester.pump(searchDebounce);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductCatalogApp)),
      );
      final query = container.read(catalogQueryProvider);
      expect(query.categorySlug, 'beauty');
      expect(query.search, isEmpty);
      expect(repository.listRequests, hasLength(2));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Product 4'), findsOneWidget);
    });

    testWidgets('sort preserves a pending search and its debounce', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 3));
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 50));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductCatalogApp)),
      );
      // The same action as the sort menu, before its search is committed.
      container
          .read(catalogQueryProvider.notifier)
          .setSort(ProductSort.priceLowToHigh);
      await tester.pump();
      final draft = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      repository.listRequests.last.succeed(products(1, 3));
      await tester.pump(searchDebounce);
      expect(repository.listRequests.last.query.search, 'phone');
      expect(
        repository.listRequests.last.query.sort,
        ProductSort.priceLowToHigh,
      );
      repository.listRequests.last.succeed(products(7, 8));
      await tester.pumpAndSettle();
      expect(draft, 'phone');
      expect(find.text('phone'), findsOneWidget);
      expect(find.text('Product 7'), findsOneWidget);
    });

    testWidgets('reselecting the same category cancels a pending search', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 3));
      repository.categoryRequests.single.complete(const [
        ProductCategory(slug: 'beauty', name: 'Beauty'),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Beauty'));
      await tester.pump();
      repository.listRequests.last.succeed(products(4, 6));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(navItem('หมวดหมู่'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ListTile, 'Beauty'));
      await tester.pump(searchDebounce);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductCatalogApp)),
      );
      expect(container.read(catalogQueryProvider).categorySlug, 'beauty');
      expect(repository.listRequests, hasLength(2));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('search is debounced and can be cleared', (tester) async {
      await pumpLoaded(tester, products(1, 3));

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.listRequests, hasLength(1));

      await tester.pump(searchDebounce);
      expect(repository.listRequests, hasLength(2));
      expect(repository.listRequests.last.query.search, 'phone');

      repository.listRequests.last.succeed([]);
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบสินค้าที่ตรงกับ "phone"'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'ล้างการค้นหา'));
      await tester.pump();
      expect(repository.listRequests.last.query.search, isEmpty);
      expect(find.text('phone'), findsNothing);
      repository.listRequests.last.succeed(products(1, 3));
      await tester.pumpAndSettle();
    });

    testWidgets('category chips and sort reload the list', (tester) async {
      await pumpLoaded(tester, products(1, 3));
      repository.categoryRequests.single.complete(const [
        ProductCategory(slug: 'beauty', name: 'Beauty'),
        ProductCategory(slug: 'laptops', name: 'Laptops'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Laptops'));
      await tester.pump();
      expect(repository.listRequests.last.query.categorySlug, 'laptops');
      repository.listRequests.last.succeed([]);
      await tester.pumpAndSettle();
      expect(find.text('ไม่มีสินค้าในหมวดนี้'), findsOneWidget);

      await tester.tap(find.byTooltip('เรียงลำดับ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ราคาปกติต่ำไปสูง'));
      await tester.pumpAndSettle();

      final request = repository.listRequests.last;
      expect(request.query.sort, ProductSort.priceLowToHigh);
      expect(request.query.categorySlug, 'laptops');
      request.succeed(products(1, 2));
      await tester.pumpAndSettle();
      expect(find.text('ราคาปกติ ↑'), findsOneWidget);
    });

    testWidgets('picking a category tab filters the catalog', (tester) async {
      await pumpLoaded(tester, products(1, 3));
      repository.categoryRequests.single.complete(const [
        ProductCategory(slug: 'skin-care', name: 'Skin Care'),
      ]);

      await tester.tap(navItem('หมวดหมู่'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Skin Care'));
      await tester.pump();

      expect(repository.listRequests.last.query.categorySlug, 'skin-care');
      repository.listRequests.last.succeed(products(7, 8));
      await tester.pumpAndSettle();
      expect(find.text('Product 7'), findsOneWidget);
    });
  });

  group('cart and wishlist', () {
    testWidgets('adding from a card updates the badge and the cart', (
      tester,
    ) async {
      await pumpLoaded(tester, [product(1, price: 20), product(2)]);

      // The first row's buttons start just under the navigation bar.
      await tapVisible(tester, addToCartButtons.first);
      await tester.pumpAndSettle();
      // Keep the confirmation from covering the button for the second tap.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(addToCartButtons.first);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget,
      );

      await tester.tap(navItem('ตะกร้า'));
      await tester.pumpAndSettle();
      expect(find.text('ตะกร้าสินค้า'), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('ยอดรวม · 2 ชิ้น'), findsOneWidget);
      // Line total, list-price subtotal, summary total and the total bar.
      expect(find.text(r'$40.00'), findsNWidgets(4));

      await tester.tap(find.byTooltip('นำออกจากตะกร้า'));
      await tester.pumpAndSettle();
      expect(find.text('ตะกร้าว่างเปล่า'), findsOneWidget);
    });

    testWidgets('heart button saves to the wishlist', (tester) async {
      await pumpLoaded(tester, [product(1), product(2)]);

      await tester.tap(find.byTooltip('เพิ่มในรายการโปรด').last);
      await tester.pumpAndSettle();
      expect(find.byTooltip('นำออกจากรายการโปรด'), findsOneWidget);

      await tester.tap(navItem('รายการโปรด'));
      await tester.pumpAndSettle();
      final wishlist = find.byType(CustomScrollView).last;
      expect(
        find.descendant(of: wishlist, matching: find.text('Product 2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: wishlist, matching: find.text('Product 1')),
        findsNothing,
      );
    });
  });

  group('product detail', () {
    testWidgets('opens the tapped product and returns to the same place', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 20));

      await scrollTo(tester, find.text('Product 9'));
      final offset = listPosition(tester).pixels;
      expect(offset, greaterThan(0));

      await tester.tap(find.text('Product 9'));
      await pumpRouteTransition(tester);
      expect(repository.detailRequests.single.id, 9);

      repository.detailRequests.single.succeed(
        Product.fromJson({
          ...productJsonWithoutImages(9),
          'price': 100,
          'discountPercentage': 10,
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Product 9'), findsWidgets);
      expect(find.text(r'$90.00'), findsOneWidget);
      expect(find.text(r'$100.00'), findsOneWidget);
      expect(find.textContaining('ประหยัด'), findsOneWidget);
      expect(find.textContaining('SKU-9'), findsOneWidget);
      expect(find.text('Description of product 9'), findsOneWidget);

      // All sections are on the page at once, with no tabs to switch.
      expect(find.text('30 days return policy'), findsOneWidget);
      expect(find.text('รีวิว (1)'), findsOneWidget);
      expect(find.text('Great!'), findsOneWidget);

      // pageBack() looks for an English "Back" tooltip; the app is in Thai.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(repository.listRequests, hasLength(1), reason: 'no reload');
      expect(listPosition(tester).pixels, offset);
      expect(find.text('Product 9'), findsOneWidget);
    });

    testWidgets('quantity, add to cart and view cart', (tester) async {
      await pumpLoaded(tester, [product(1)]);
      await tester.tap(find.text('Product 1'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.succeed(product(1, stock: 3));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byTooltip('เพิ่มจำนวน'));
      await tester.pump();
      await tester.tap(find.text('ใส่ตะกร้า'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ลงตะกร้าแล้ว'), findsOneWidget);

      // Viewing the cart must not add the selected quantity a second time.
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is OutlinedButton),
          matching: find.text('ดูตะกร้า'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ตะกร้าสินค้า'), findsOneWidget);
      expect(find.text('ยอดรวม · 2 ชิ้น'), findsOneWidget);
    });

    testWidgets('out of stock disables buying', (tester) async {
      await pumpLoaded(tester, [product(1)]);
      await tester.tap(find.text('Product 1'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.succeed(product(1, stock: 0));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate(
          (widget) => widget is FilledButton && widget.onPressed == null,
        ),
      );
      expect(button.onPressed, isNull);
      // The stock fact also reads "สินค้าหมด"; check the button's own label.
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('สินค้าหมด'),
        ),
        findsOneWidget,
      );
      expect(find.text('ดูตะกร้า'), findsOneWidget);
    });

    testWidgets('error retries only that product', (tester) async {
      await pumpLoaded(tester, products(1, 2));

      await tester.tap(find.text('Product 2'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.fail(AppErrorType.timeout);
      await tester.pumpAndSettle();
      expect(
        find.text(AppException(AppErrorType.timeout).message),
        findsOneWidget,
      );

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.detailRequests, hasLength(2));
      expect(repository.detailRequests.last.id, 2);

      repository.detailRequests.last.succeed(product(2));
      await tester.pumpAndSettle();
      expect(find.text('Description of product 2'), findsOneWidget);
    });

    testWidgets('missing product shows not found and can go back', (
      tester,
    ) async {
      await pumpLoaded(tester, products(1, 2));

      await tester.tap(find.text('Product 1'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.fail(AppErrorType.notFound);
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบสินค้า'), findsOneWidget);
      await tester.tap(find.text('กลับไปหน้ารายการ'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductListScreen), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget);
    });
  });

  group('responsive layout', () {
    test('column count follows the available width', () {
      expect(gridColumnCount(320), 1);
      expect(gridColumnCount(360), 2);
      expect(gridColumnCount(600), 3);
      expect(gridColumnCount(800), 4);
      expect(gridColumnCount(1200), 4);
    });

    const sizes = [Size(360, 800), Size(800, 1280), Size(1280, 800)];
    for (final size in sizes) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()} '
          'with text scale $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearAllTestValues);

            const longTitle =
                'A very long product title that keeps going and going so '
                'it must be truncated with an ellipsis';
            await pumpApp(tester);
            repository.listRequests.single.succeed([
              for (var id = 1; id <= 20; id++)
                Product.fromJson({
                  ...productJsonWithoutImages(id),
                  'title': '$longTitle $id',
                  'price': 123456.78,
                  'stock': 3,
                }),
            ]);
            repository.categoryRequests.single.complete([
              for (final name in ['Beauty', 'Home Decoration', 'Laptops'])
                ProductCategory(slug: name.toLowerCase(), name: name),
            ]);
            await tester.pumpAndSettle();
            // The open menu must also fit narrow screens and enlarged text.
            await tester.tap(find.byTooltip('เรียงลำดับ'));
            await tester.pumpAndSettle();
            expect(find.text('เรียงลำดับสินค้า'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(find.text('เรียงลำดับสินค้า'), findsNothing);
            await scrollTo(tester, find.text('โหลดเพิ่มเติม'));

            await tester.tap(addToCartButtons.hitTestable().first);
            await tester.pumpAndSettle();
            tester
                .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
                .removeCurrentSnackBar();
            listPosition(tester).jumpTo(0);
            await tester.pumpAndSettle();

            await tapVisible(
              tester,
              find
                  .descendant(
                    of: find.byType(ProductCard),
                    matching: find.textContaining('very long'),
                  )
                  .first,
            );
            await pumpRouteTransition(tester);
            repository.detailRequests.single.succeed(
              Product.fromJson({
                ...productJsonWithoutImages(
                  repository.detailRequests.single.id,
                ),
                'title': 'A very long product title ' * 4,
                'price': 123456.78,
                'description': 'Lorem ipsum dolor sit amet. ' * 40,
              }),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Great!'));
            await tester.pumpAndSettle();

            // The cart screen with a long line item.
            await tester.tap(find.text('ดูตะกร้า'));
            await tester.pumpAndSettle();
            expect(find.text('ตะกร้าสินค้า'), findsOneWidget);

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}

/// Full fixture data without image URLs, so tests never load images.
Map<String, Object?> productJsonWithoutImages(int id) => {
  ...productJson(id),
  'images': <String>[],
  'thumbnail': null,
};
