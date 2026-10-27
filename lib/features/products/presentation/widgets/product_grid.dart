import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/product.dart';
import '../product_detail_screen.dart';
import 'product_card.dart';

const maxContentWidth = 1200.0;
const _sidePadding = 16.0;
const _gridSpacing = 12.0;

/// Each product is its own card, so rows and columns share one gap.
const _rowSpacing = _gridSpacing;
const _minCardWidth = 150.0;

/// Columns that fit [contentWidth] with cards at least 150 wide, clamped 1–4.
int gridColumnCount(double contentWidth) {
  final usable = contentWidth - _sidePadding * 2 + _gridSpacing;
  return (usable / (_minCardWidth + _gridSpacing)).floor().clamp(1, 4);
}

/// Grid geometry for the available width, shared by the real grid and its
/// loading skeleton so both line up.
class ProductGridLayout {
  factory ProductGridLayout.forWidth(double width, TextScaler textScaler) {
    final contentWidth = math.min(width, maxContentWidth);
    final columns = gridColumnCount(contentWidth);
    final cardWidth =
        (contentWidth - _sidePadding * 2 - _gridSpacing * (columns - 1)) /
        columns;
    return ProductGridLayout._(
      columns: columns,
      cardHeight: ProductCard.heightFor(cardWidth, textScaler),
      horizontalPadding: (width - contentWidth) / 2 + _sidePadding,
    );
  }

  const ProductGridLayout._({
    required this.columns,
    required this.cardHeight,
    required this.horizontalPadding,
  });

  final int columns;
  final double cardHeight;
  final double horizontalPadding;

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: _rowSpacing,
    crossAxisSpacing: _gridSpacing,
    mainAxisExtent: cardHeight,
  );
}

/// Lazily built grid of product cards; tapping one opens its detail page.
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.products,
    required this.layout,
  });

  final List<Product> products;
  final ProductGridLayout layout;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: layout.delegate,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          onTap: () => ProductDetailScreen.open(context, product.id),
        );
      },
    );
  }
}

/// Static placeholder cards shown during the initial load.
class SliverProductSkeletonGrid extends StatelessWidget {
  const SliverProductSkeletonGrid({
    super.key,
    required this.layout,
    this.count = 6,
  });

  final ProductGridLayout layout;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
      ),
    );

    return SliverSemantics(
      label: 'กำลังโหลดสินค้า',
      sliver: SliverGrid.builder(
        key: const Key('product-skeleton'),
        gridDelegate: layout.delegate,
        itemCount: count,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.thumb),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ProductCard.padding),
                child: Column(
                  spacing: AppSpace.sm,
                  children: [
                    bar(0.4, 8),
                    bar(0.9, 12),
                    bar(0.7, 12),
                    const SizedBox(height: AppSpace.xs),
                    bar(0.35, 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
