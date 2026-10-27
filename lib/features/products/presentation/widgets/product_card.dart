import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/add_to_cart.dart';
import '../../../wishlist/presentation/wishlist_button.dart';
import '../../data/product.dart';
import 'product_image.dart';
import 'product_labels.dart';

/// A product on its own white card: the photo on top, then the details and a
/// round add-to-cart button beside the price.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  static const imageGap = 8.0;

  /// Inset of the text below the photo, at the sides and bottom.
  static const padding = 10.0;
  static const _metaGap = 2.0;
  static const _titleGap = 6.0;
  static const _buttonSize = 48.0;
  static const _titleLines = 2;

  /// Height of a card [width] wide: a square image plus the text rows at the
  /// current text scale, so nothing is clipped when fonts are enlarged.
  static double heightFor(double width, TextScaler textScaler) {
    double line(double fontSize) =>
        textScaler.scale(fontSize) * ProductTextStyles.lineHeight;
    return width +
        imageGap +
        line(ProductTextStyles.metaFontSize) +
        _metaGap +
        line(ProductTextStyles.titleFontSize) * _titleLines +
        _titleGap +
        _footerHeight(textScaler) +
        padding +
        // A few pixels of slack absorb font metric rounding.
        4;
  }

  /// Price and stock stacked on the left, the button on the right. The
  /// price row aligns two sizes on a baseline, which can run a pixel past
  /// its line height, hence the extra 2.
  static double _footerHeight(TextScaler textScaler) => math.max(
    textScaler.scale(ProductTextStyles.priceFontSize) *
            ProductTextStyles.lineHeight +
        textScaler.scale(ProductTextStyles.stockFontSize) *
            ProductTextStyles.lineHeight *
            StockLabel.compactMaxLines +
        2,
    _buttonSize,
  );

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = product.rating;
    final textScaler = MediaQuery.textScalerOf(context);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: ProductTextStyles.metaFontSize,
      height: ProductTextStyles.lineHeight,
      color: colors.onSurfaceVariant,
    );
    final categoryColor = CategoryPalette.of(
      context,
      product.categorySlug,
    ).foreground;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.card),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                padding,
                imageGap,
                padding,
                padding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height:
                        textScaler.scale(ProductTextStyles.metaFontSize) *
                        ProductTextStyles.lineHeight,
                    child: Row(
                      children: [
                        if (rating != null) ...[
                          RatingLabel(
                            rating: rating,
                            fontSize: ProductTextStyles.metaFontSize,
                          ),
                          Text(' · ', style: metaStyle),
                        ],
                        Expanded(
                          child: Text(
                            product.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _metaGap),
                  SizedBox(
                    height:
                        textScaler.scale(ProductTextStyles.titleFontSize) *
                        ProductTextStyles.lineHeight *
                        _titleLines,
                    child: Text(
                      product.title,
                      maxLines: _titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: ProductTextStyles.titleFontSize,
                        height: ProductTextStyles.lineHeight,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: _titleGap),
                  SizedBox(
                    height: _footerHeight(textScaler),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PriceRow(product: product),
                              StockLabel(
                                stock: product.stock,
                                fontSize: ProductTextStyles.stockFontSize,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'ใส่ตะกร้า',
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(40),
                            minimumSize: const Size.square(40),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.standard,
                            shape: const CircleBorder(),
                          ),
                          iconSize: 22,
                          onPressed: product.isOutOfStock
                              ? null
                              : () => addToCart(context, ref, product),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
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
