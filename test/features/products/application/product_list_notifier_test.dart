import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/core/errors/app_exception.dart';
import 'package:product_catalog/core/riverpod/no_retry.dart';
import 'package:product_catalog/features/products/application/product_list_notifier.dart';
import 'package:product_catalog/features/products/application/product_list_state.dart';
import 'package:product_catalog/features/products/data/product_repository.dart';

import '../../../helpers/fake_product_repository.dart';
import '../../../helpers/fixtures.dart';

void main() {
  late FakeProductRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeProductRepository();
    container = ProviderContainer.test(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
      retry: noRetry,
    );
    container.listen(productListProvider, (_, _) {});
  });

  ProductListNotifier notifier() =>
      container.read(productListProvider.notifier);
  ProductListState state() => container.read(productListProvider).requireValue;
  List<int> ids() => state().items.map((p) => p.id).toList();

  /// Completes the initial load with products 1–20 (a full first page).
  Future<void> loadFirstPage() async {
    final future = container.read(productListProvider.future);
    repository.listRequests.single.succeed(products(1, 20));
    await future;
  }

  group('initial load', () {
    test('requests offset 0 with the page size', () async {
      await loadFirstPage();

      final request = repository.listRequests.single;
      expect(request.offset, 0);
      expect(request.limit, productPageSize);
      expect(ids(), List.generate(20, (i) => i + 1));
      expect(state().nextOffset, 20);
      expect(state().hasMore, isTrue);
    });

    test('a failure becomes an error, not an empty list', () async {
      final future = container.read(productListProvider.future);
      repository.listRequests.single.fail(AppErrorType.server);

      await expectLater(future, throwsA(isA<AppException>()));
      final value = container.read(productListProvider);
      expect(value.hasError, isTrue);
      expect(value.hasValue, isFalse);
    });

    test('an empty response is an empty state with nothing more', () async {
      final future = container.read(productListProvider.future);
      repository.listRequests.single.succeed([]);
      await future;

      expect(state().isEmpty, isTrue);
      expect(state().hasMore, isFalse);
    });
  });

  group('load more', () {
    test('appends the next page and skips duplicate IDs', () async {
      await loadFirstPage();

      final loading = notifier().loadMore();
      expect(state().isLoadingMore, isTrue);
      final request = repository.listRequests.last;
      expect(request.offset, 20);
      // 20 raw items; ID 20 is already loaded.
      request.succeed(products(20, 39));
      await loading;

      expect(ids(), List.generate(39, (i) => i + 1));
      expect(state().nextOffset, 40, reason: 'cursor uses the raw count');
      expect(state().isLoadingMore, isFalse);
      expect(state().hasMore, isTrue);
    });

    test('stops when a page has fewer items than the limit', () async {
      await loadFirstPage();

      final loading = notifier().loadMore();
      repository.listRequests.last.succeed(products(21, 25));
      await loading;

      expect(state().hasMore, isFalse);
      await notifier().loadMore();
      expect(repository.listRequests, hasLength(2));
    });

    test(
      'a full last page is followed by an empty page that ends it',
      () async {
        await loadFirstPage();

        var loading = notifier().loadMore();
        repository.listRequests.last.succeed(products(21, 40));
        await loading;
        expect(state().hasMore, isTrue);

        loading = notifier().loadMore();
        repository.listRequests.last.succeed([]);
        await loading;

        expect(state().hasMore, isFalse);
        expect(state().items, hasLength(40));
      },
    );

    test('ignores calls while a load more is running', () async {
      await loadFirstPage();

      final loading = notifier().loadMore();
      await notifier().loadMore();
      await notifier().loadMore();
      expect(repository.listRequests, hasLength(2));

      repository.listRequests.last.succeed(products(21, 40));
      await loading;
    });

    test('a failure keeps items and retry uses the same offset', () async {
      await loadFirstPage();

      var loading = notifier().loadMore();
      repository.listRequests.last.fail(AppErrorType.network);
      await loading;

      expect(state().items, hasLength(20));
      expect(state().isLoadingMore, isFalse);
      expect(state().loadMoreError?.type, AppErrorType.network);
      expect(state().nextOffset, 20);

      loading = notifier().loadMore();
      expect(state().loadMoreError, isNull);
      expect(repository.listRequests.last.offset, 20);
      repository.listRequests.last.succeed(products(21, 40));
      await loading;
      expect(state().items, hasLength(40));
    });
  });

  group('refresh', () {
    test('replaces items with the first page and resets the cursor', () async {
      await loadFirstPage();
      var loading = notifier().loadMore();
      repository.listRequests.last.succeed(products(21, 40));
      await loading;

      final refreshing = notifier().refresh();
      expect(state().isRefreshing, isTrue);
      expect(state().items, hasLength(40), reason: 'old items stay visible');
      final request = repository.listRequests.last;
      expect(request.offset, 0);
      request.succeed(products(101, 120));
      await refreshing;

      expect(ids().first, 101);
      expect(state().items, hasLength(20));
      expect(state().nextOffset, 20);
      expect(state().isRefreshing, isFalse);
    });

    test('a failure keeps the old list and reports the error', () async {
      await loadFirstPage();

      final refreshing = notifier().refresh();
      repository.listRequests.last.fail(AppErrorType.timeout);
      await refreshing; // completes normally

      expect(state().items, hasLength(20));
      expect(state().nextOffset, 20);
      expect(state().isRefreshing, isFalse);
      expect(state().isLoadingMore, isFalse);
      expect(state().refreshError?.type, AppErrorType.timeout);
    });

    test('concurrent calls share one request', () async {
      await loadFirstPage();

      final first = notifier().refresh();
      final second = notifier().refresh();
      expect(identical(first, second), isTrue);
      expect(repository.listRequests, hasLength(2));

      repository.listRequests.last.succeed(products(1, 20));
      await first;

      // A new refresh after completion sends a new request.
      final third = notifier().refresh();
      expect(repository.listRequests, hasLength(3));
      repository.listRequests.last.succeed(products(1, 20));
      await third;
    });

    test('load more is ignored while refreshing', () async {
      await loadFirstPage();

      final refreshing = notifier().refresh();
      await notifier().loadMore();
      expect(repository.listRequests, hasLength(2));

      repository.listRequests.last.succeed(products(1, 20));
      await refreshing;
    });

    test('cancels an in-flight load more', () async {
      await loadFirstPage();

      final loading = notifier().loadMore();
      final loadMoreRequest = repository.listRequests.last;
      final refreshing = notifier().refresh();

      expect(loadMoreRequest.isCancelled, isTrue);
      expect(state().isLoadingMore, isFalse);

      loadMoreRequest.fail(AppErrorType.cancelled);
      await loading;
      expect(state().loadMoreError, isNull, reason: 'cancel is not an error');
      expect(state().isRefreshing, isTrue);

      repository.listRequests.last.succeed(products(101, 120));
      await refreshing;
    });

    test(
      'a stale load more that succeeds late does not touch new state',
      () async {
        await loadFirstPage();

        final loading = notifier().loadMore();
        final staleRequest = repository.listRequests.last;
        final refreshing = notifier().refresh();
        final refreshRequest = repository.listRequests.last;

        // The old request ignores cancellation and finishes while refreshing.
        staleRequest.succeed(products(21, 40));
        await loading;
        expect(state().isRefreshing, isTrue);
        expect(state().items, hasLength(20));

        refreshRequest.succeed(products(101, 120));
        await refreshing;

        expect(ids().first, 101);
        expect(state().items, hasLength(20));
        expect(state().nextOffset, 20);
      },
    );

    test(
      'a stale load more that fails late does not touch new state',
      () async {
        await loadFirstPage();

        final loading = notifier().loadMore();
        final staleRequest = repository.listRequests.last;
        final refreshing = notifier().refresh();
        final refreshRequest = repository.listRequests.last;

        refreshRequest.succeed(products(101, 120));
        await refreshing;

        // Starts a new load more for the refreshed list.
        final newLoading = notifier().loadMore();
        expect(state().isLoadingMore, isTrue);

        staleRequest.fail(AppErrorType.server);
        await loading;
        expect(state().loadMoreError, isNull);
        expect(state().isLoadingMore, isTrue, reason: 'finally must not reset');

        repository.listRequests.last.succeed(products(121, 140));
        await newLoading;
        expect(state().items, hasLength(40));
      },
    );

    test(
      'after a failed refresh, load more resumes from the old cursor',
      () async {
        await loadFirstPage();

        final loading = notifier().loadMore();
        final refreshing = notifier().refresh();
        repository.listRequests.last.fail(AppErrorType.network);
        await refreshing;
        await Future<void>.delayed(Duration.zero);

        expect(state().items, hasLength(20));
        expect(state().nextOffset, 20);
        expect(state().isLoadingMore, isFalse);

        final retry = notifier().loadMore();
        expect(repository.listRequests.last.offset, 20);
        repository.listRequests.last.succeed(products(21, 40));
        await retry;
        expect(state().items, hasLength(40));

        // The cancelled request never completed; let it finish harmlessly.
        repository.listRequests[1].fail(AppErrorType.cancelled);
        await loading;
        expect(state().items, hasLength(40));
      },
    );
  });
}
