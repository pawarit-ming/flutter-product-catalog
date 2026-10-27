import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/add_to_cart.dart';
import '../../../wishlist/presentation/wishlist_button.dart';
import '../../data/product.dart';
import 'product_image.dart';
import 'product_labels.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  static const padding = 10.0;
  static const _metaGap = 4.0;
  static const _titleGap = 6.0;
  static const _priceGap = 2.0;
  static const _buttonSize = 48.0;

  /// Height of a card [width] wide: a square image plus the text rows at the
  /// current text scale, so nothing is clipped when fonts are enlarged.
  static double heightFor(double width, TextScaler textScaler) {
    double line(double fontSize) =>
        textScaler.scale(fontSize) * ProductTextStyles.lineHeight;
    final priceAndStock =
        line(ProductTextStyles.priceFontSize) +
        _priceGap +
        line(ProductTextStyles.metaFontSize);
    return width +
        padding * 2 +
        line(ProductTextStyles.metaFontSize) +
        _metaGap +
        line(ProductTextStyles.titleFontSize) * 2 +
        _titleGap +
        math.max(priceAndStock, _buttonSize) +
        // A few pixels of slack absorb font metric rounding.
        4;
  }

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rating = product.rating;
    final metaLine =
        MediaQuery.textScalerOf(context).scale(ProductTextStyles.metaFontSize) *
        ProductTextStyles.lineHeight;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.cardImageUrl, label: product.title),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DiscountBadge(product: product),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: WishlistButton(product: product, onImage: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: metaLine,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: ProductTextStyles.metaFontSize,
                              height: ProductTextStyles.lineHeight,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (rating != null) RatingLabel(rating: rating),
                      ],
                    ),
                  ),
                  const SizedBox(height: _metaGap),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: ProductTextStyles.titleFontSize,
                      height: ProductTextStyles.lineHeight,
                    ),
                  ),
                  const SizedBox(height: _titleGap),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PriceRow(product: product),
                            const SizedBox(height: _priceGap),
                            StockLabel(stock: product.stock),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'ใส่ตะกร้า',
                        onPressed: product.isOutOfStock
                            ? null
                            : () => addToCart(context, ref, product),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
