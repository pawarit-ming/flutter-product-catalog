import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/add_to_cart.dart';
import '../../../wishlist/presentation/wishlist_button.dart';
import '../../data/product.dart';
import 'product_image.dart';
import 'product_labels.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  static const padding = AppSpace.md;
  static const _metaGap = 6.0;
  static const _titleGap = AppSpace.sm;
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
        line(ProductTextStyles.metaFontSize + 1);
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
    final colors = theme.colorScheme;
    final rating = product.rating;
    final metaLine =
        MediaQuery.textScalerOf(context).scale(ProductTextStyles.metaFontSize) *
        ProductTextStyles.lineHeight;

    return Card(
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
                  ProductImage(
                    url: product.cardImageUrl,
                    label: product.title,
                    padding: AppSpace.lg,
                  ),
                  Positioned(
                    top: AppSpace.sm,
                    left: AppSpace.sm,
                    child: DiscountBadge(product: product),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: WishlistButton(product: product),
                  ),
                ],
              ),
            ),
            const Divider(),
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
                            product.categoryName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: ProductTextStyles.metaFontSize,
                              height: ProductTextStyles.lineHeight,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (rating != null)
                          RatingLabel(
                            rating: rating,
                            fontSize: ProductTextStyles.metaFontSize,
                          ),
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
                            StockLabel(
                              stock: product.stock,
                              fontSize: ProductTextStyles.metaFontSize + 1,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'ใส่ตะกร้า',
                        style: IconButton.styleFrom(
                          fixedSize: const Size.square(40),
                          minimumSize: const Size.square(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                          ),
                        ),
                        iconSize: 20,
                        onPressed: product.isOutOfStock
                            ? null
                            : () => addToCart(context, ref, product),
                        icon: const Icon(Icons.add_shopping_cart_outlined),
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
