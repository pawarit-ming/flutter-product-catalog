import 'package:flutter/material.dart';

import '../../../../core/formatting/price_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/product.dart';

/// Solid "−12%" pill in the sale accent; renders nothing without a real
/// discount.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasDiscount) return const SizedBox.shrink();
    final catalog = CatalogColors.of(context);
    return Semantics(
      label: 'ลด ${product.discountBadge}%',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: catalog.sale,
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        child: Text(
          '−${product.discountBadge}%',
          style: TextStyle(
            color:
                ThemeData.estimateBrightnessForColor(catalog.sale) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Star + rating, optionally with the number of reviews.
class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.rating,
    this.reviewCount,
    this.fontSize = 12,
  });

  final double rating;
  final int? reviewCount;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = reviewCount == null ? '' : ' · $reviewCount รีวิว';
    return Semantics(
      label: 'คะแนน ${rating.toStringAsFixed(1)} จาก 5$reviews',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: fontSize + 2,
            color: CatalogColors.of(context).rating,
          ),
          const SizedBox(width: 2),
          Text(
            '${rating.toStringAsFixed(1)}$reviews',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: fontSize,
              height: ProductTextStyles.lineHeight,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stock status. Only low and sold-out stock is coloured, so a full shelf of
/// products is not covered in green. Renders an empty line of the same
/// height when the API does not report stock, so card heights stay stable.
class StockLabel extends StatelessWidget {
  const StockLabel({
    super.key,
    required this.stock,
    this.fontSize = 12,
    this.compact = false,
  });

  static const lowStockThreshold = 5;
  static const compactMaxLines = 2;

  final int? stock;
  final double fontSize;

  /// Cards show availability at a glance; detail views retain exact counts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stock = this.stock;
    final theme = Theme.of(context);
    final catalog = CatalogColors.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: fontSize,
      height: ProductTextStyles.lineHeight,
    );
    if (stock == null) return Text('', style: style);

    final (text, color, urgent) = switch (stock) {
      0 => ('สินค้าหมด', catalog.lowStock, true),
      <= lowStockThreshold => (
        'เหลือเพียง $stock ชิ้น',
        catalog.lowStock,
        true,
      ),
      _ => (
        compact ? 'มีสินค้า' : 'มีสินค้า $stock ชิ้น',
        catalog.inStock,
        false,
      ),
    };
    return Text(
      text,
      semanticsLabel: compact && stock > lowStockThreshold
          ? 'มีสินค้า $stock ชิ้น'
          : null,
      maxLines: compact ? compactMaxLines : 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(
        color: color,
        fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

/// Sale price plus the struck-through list price when discounted.
///
/// The sale price always wins the space: the list price is only shown when
/// both fit on one line, so a narrow card never truncates the real price.
class PriceRow extends StatelessWidget {
  const PriceRow({super.key, required this.product, this.large = false});

  static const _gap = 6.0;

  final Product product;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = DefaultTextStyle.of(context).style;
    final saleStyle = base.merge(
      TextStyle(
        fontSize: large ? 28.0 : ProductTextStyles.priceFontSize,
        height: ProductTextStyles.lineHeight,
        fontWeight: FontWeight.w600,
        // Prices stay ink; the discount tag carries the accent.
        color: theme.colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final listStyle = base.merge(
      TextStyle(
        fontSize: large ? 15.0 : 12.0,
        height: ProductTextStyles.lineHeight,
        color: theme.colorScheme.onSurfaceVariant,
        decoration: TextDecoration.lineThrough,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final sale = formatPrice(product.salePrice);
    final list = formatPrice(product.price);

    return LayoutBuilder(
      builder: (context, constraints) {
        double widthOf(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final showList =
            product.hasDiscount &&
            widthOf(sale, saleStyle) + _gap + widthOf(list, listStyle) <=
                constraints.maxWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                sale,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: saleStyle,
              ),
            ),
            if (showList) ...[
              const SizedBox(width: _gap),
              Text(
                list,
                maxLines: 1,
                semanticsLabel: 'ราคาปกติ $list',
                style: listStyle,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Font sizes shared by the card and its height calculation.
abstract final class ProductTextStyles {
  static const lineHeight = 1.3;

  static const metaFontSize = 12.0;
  static const titleFontSize = 14.0;
  static const priceFontSize = 16.0;
  static const stockFontSize = 12.0;
}
