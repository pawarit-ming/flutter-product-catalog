import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../application/product_list_notifier.dart';
import '../application/product_list_state.dart';
import 'product_detail_screen.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/product_card.dart';

const maxContentWidth = 1200.0;
const _sidePadding = 16.0;
const _gridSpacing = 12.0;
const _minCardWidth = 150.0;

/// Columns that fit [contentWidth] with cards at least 150 wide, clamped 1–4.
int gridColumnCount(double contentWidth) {
  final usable = contentWidth - _sidePadding * 2 + _gridSpacing;
  return (usable / (_minCardWidth + _gridSpacing)).floor().clamp(1, 4);
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  // Created once so the scroll position survives opening a product.
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (ref.read(productListProvider).value == null) {
      await _retryInitialLoad();
      return;
    }
    await ref.read(productListProvider.notifier).refresh();
  }

  Future<void> _retryInitialLoad() {
    ref.invalidate(productListProvider);
    // Errors are rendered from the provider state; only wait for completion.
    return ref
        .read(productListProvider.future)
        .then<void>((_) {}, onError: (Object _) {});
  }

  void _openProduct(int productId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productListProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      // One message per failed refresh request.
      if (before != null &&
          before.isRefreshing &&
          after != null &&
          !after.isRefreshing &&
          after.refreshError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text("Couldn't refresh. ${after.refreshError!.message}"),
            ),
          );
      }
    });

    final asyncState = ref.watch(productListProvider);
    final data = asyncState.value;

    final Widget child;
    if (data != null) {
      child = data.isEmpty
          ? _FillRemaining(child: EmptyView(onRetry: _onRefresh))
          : _ProductGrid(
              state: data,
              onOpen: _openProduct,
              onLoadMore: () =>
                  ref.read(productListProvider.notifier).loadMore(),
            );
    } else if (asyncState.hasError && !asyncState.isLoading) {
      child = _FillRemaining(
        child: ErrorView(
          message: AppException.from(asyncState.error!).message,
          onAction: _retryInitialLoad,
        ),
      );
    } else {
      child = const _FillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          key: const PageStorageKey('product-list'),
          controller: _scrollController,
          // Pull-to-refresh must work even when the list is short or empty.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [child],
        ),
      ),
    );
  }
}

class _FillRemaining extends StatelessWidget {
  const _FillRemaining({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.state,
    required this.onOpen,
    required this.onLoadMore,
  });

  final ProductListState state;
  final ValueChanged<int> onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final contentWidth = math.min(width, maxContentWidth);
        final horizontal = (width - contentWidth) / 2 + _sidePadding;
        final columns = gridColumnCount(contentWidth);
        final cardWidth =
            (contentWidth - _sidePadding * 2 - _gridSpacing * (columns - 1)) /
            columns;
        final cardHeight = ProductCard.heightFor(
          cardWidth,
          MediaQuery.textScalerOf(context),
        );

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final product = state.items[index];
                  return ProductCard(
                    key: ValueKey(product.id),
                    product: product,
                    onTap: () => onOpen(product.id),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: _ListFooter(state: state, onLoadMore: onLoadMore),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state, required this.onLoadMore});

  final ProductListState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadMoreError = state.loadMoreError;

    final Widget content;
    if (state.isLoadingMore) {
      content = const SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (loadMoreError != null) {
      content = Column(
        children: [
          Text(
            loadMoreError.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: state.isRefreshing ? null : onLoadMore,
            style: _buttonStyle,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    } else if (state.hasMore) {
      content = OutlinedButton(
        onPressed: state.isRefreshing ? null : onLoadMore,
        style: _buttonStyle,
        child: const Text('Load more'),
      );
    } else {
      content = Text(
        "You've reached the end",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(child: content),
    );
  }

  static final _buttonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(160, 48)),
  );
}
