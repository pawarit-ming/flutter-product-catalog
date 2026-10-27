import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/app.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/core/riverpod/no_retry.dart';
import 'package:product_catalog/features/products/data/product.dart';
import 'package:product_catalog/features/products/data/product_category.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';
import 'package:product_catalog/features/products/presentation/product_list_screen.dart';

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

  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Scrolls the list until [finder] is fully on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Finishes a page transition without waiting for a loading spinner, which
  /// never settles while its request is pending.
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  ScrollPosition listPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  group('product list', () {
    testWidgets('shows loading, then names and prices', (tester) async {
      await pumpApp(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.listRequests.single.succeed([
        product(1, price: 44),
        product(2, price: 9.5),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text(r'$44.00'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
      expect(find.text(r'$9.50'), findsOneWidget);
      expect(find.text("You've reached the end"), findsOneWidget);
    });

    testWidgets('error state retries the initial load', (tester) async {
      await pumpApp(tester);
      repository.listRequests.single.fail(AppErrorType.network);
      await tester.pumpAndSettle();

      expect(
        find.text(AppException(AppErrorType.network).message),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(repository.listRequests, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

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
      await pumpApp(tester);
      repository.listRequests.single.succeed([]);
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);

      await pullToRefresh(tester);
      expect(repository.listRequests, hasLength(2));
      repository.listRequests.last.fail(AppErrorType.timeout);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining("Couldn't refresh"), findsOneWidget);
      expect(find.text('No products found'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('load more shows a spinner, then retry after a failure', (
      tester,
    ) async {
      await pumpApp(tester);
      repository.listRequests.single.succeed(products(1, 20));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await tester.pump();
      expect(repository.listRequests.last.offset, 20);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.listRequests.last.fail(AppErrorType.network);
      await tester.pumpAndSettle();
      expect(find.text('Product 20'), findsOneWidget, reason: 'items kept');
      await scrollTo(tester, find.text('Retry'));

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(repository.listRequests.last.offset, 20);
      repository.listRequests.last.succeed(products(21, 25));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Product 25'));
      expect(find.text('Load more'), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('opens the tapped product and returns to the same place', (
      tester,
    ) async {
      await pumpApp(tester);
      repository.listRequests.single.succeed(products(1, 20));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Product 9'));
      await tester.pumpAndSettle();
      final offset = listPosition(tester).pixels;
      expect(offset, greaterThan(0));

      await tester.tap(find.text('Product 9'));
      await pumpRouteTransition(tester);
      expect(repository.detailRequests.single.id, 9);

      repository.detailRequests.single.succeed(
        const Product(
          id: 9,
          title: 'Detailed product',
          price: 12.5,
          description: 'A long description',
          category: ProductCategory(name: 'Shoes'),
          images: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detailed product'), findsWidgets);
      expect(find.text(r'$12.50'), findsOneWidget);
      expect(find.text('A long description'), findsOneWidget);
      expect(find.text('Shoes'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repository.listRequests, hasLength(1), reason: 'no reload');
      expect(listPosition(tester).pixels, offset);
      expect(find.text('Product 9'), findsOneWidget);
    });

    testWidgets('detail error retries only that product', (tester) async {
      await pumpApp(tester);
      repository.listRequests.single.succeed(products(1, 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Product 2'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.fail(AppErrorType.timeout);
      await tester.pumpAndSettle();
      expect(
        find.text(AppException(AppErrorType.timeout).message),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
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
      await pumpApp(tester);
      repository.listRequests.single.succeed(products(1, 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Product 1'));
      await pumpRouteTransition(tester);
      repository.detailRequests.single.fail(AppErrorType.notFound);
      await tester.pumpAndSettle();

      expect(find.text('Product not found'), findsOneWidget);
      await tester.tap(find.text('Back to products'));
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

            await pumpApp(tester);
            repository.listRequests.single.succeed([
              for (var id = 1; id <= 20; id++)
                Product.fromJson({
                  'id': id,
                  'title':
                      'A very long product title that keeps going and '
                      'going so it must be truncated with an ellipsis $id',
                  'price': 123456.78,
                  'images': <String>[],
                }),
            ]);
            await tester.pumpAndSettle();
            await scrollTo(tester, find.text('Load more'));

            await tester.tap(
              find.textContaining('very long').hitTestable().first,
            );
            await pumpRouteTransition(tester);
            repository.detailRequests.single.succeed(
              Product.fromJson({
                'id': repository.detailRequests.single.id,
                'title': 'A very long product title ' * 4,
                'price': 123456.78,
                'description': 'Lorem ipsum dolor sit amet. ' * 40,
              }),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
