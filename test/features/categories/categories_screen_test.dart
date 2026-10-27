import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/app.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/core/riverpod/no_retry.dart';
import 'package:product_catalog/features/products/data/product_category.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';

import '../../helpers/fake_product_repository.dart';
import '../../helpers/fixtures.dart';

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
    repository.listRequests.single.succeed([product(1)]);
    repository.categoryRequests.single.complete(const [
      ProductCategory(slug: 'beauty', name: 'Beauty'),
      ProductCategory(slug: 'laptops', name: 'Laptops'),
    ]);
    await tester.pumpAndSettle();
  }

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('หมวดหมู่'),
      ),
    );
    await tester.pumpAndSettle();
  }

  final loading = find.byKey(const ValueKey('loading'));
  final fallback = find.byKey(const ValueKey('fallback'));

  testWidgets('covers load only once the tab is opened', (tester) async {
    await pumpApp(tester);
    expect(repository.coverRequests, isEmpty);

    await openCategories(tester);
    expect(
      repository.coverRequests.keys,
      unorderedEquals(['beauty', 'laptops']),
    );
  });

  testWidgets('shows a skeleton until each cover is known', (tester) async {
    await pumpApp(tester);
    await openCategories(tester);
    expect(loading, findsNWidgets(2));
    expect(fallback, findsNothing);

    // No photo: the category's icon on its tint replaces the skeleton.
    repository.coverRequests['beauty']!.complete(null);
    await tester.pumpAndSettle();
    expect(loading, findsOneWidget);
    expect(fallback, findsOneWidget);

    // A failed request falls back the same way.
    repository.coverRequests['laptops']!.completeError(
      AppException(AppErrorType.network),
    );
    await tester.pumpAndSettle();
    expect(loading, findsNothing);
    expect(fallback, findsNWidgets(2));
  });
}
