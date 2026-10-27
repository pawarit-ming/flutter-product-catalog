import 'package:flutter/material.dart';

import '../../../../core/formatting/price_format.dart';
import '../../data/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  static const padding = 12.0;
  static const gap = 6.0;
  static const titleFontSize = 14.0;
  static const priceFontSize = 16.0;
  static const lineHeight = 1.3;

  /// Height of a card [width] wide: a square image plus two title lines and
  /// one price line at the current text scale, so text never gets clipped.
  static double heightFor(double width, TextScaler textScaler) {
    final titleLine = textScaler.scale(titleFontSize) * lineHeight;
    final priceLine = textScaler.scale(priceFontSize) * lineHeight;
    // A few pixels of slack absorb font metric rounding.
    return width + padding * 2 + titleLine * 2 + gap + priceLine + 4;
  }

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: ProductImage(url: product.imageUrl, label: product.title),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: titleFontSize,
                      height: lineHeight,
                    ),
                  ),
                  const SizedBox(height: gap),
                  Text(
                    formatPrice(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: priceFontSize,
                      height: lineHeight,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
