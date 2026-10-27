import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../products/data/product.dart';
import '../../products/presentation/widgets/product_image.dart';

const cartFeedbackPadding = EdgeInsetsDirectional.fromSTEB(
  AppSpace.md,
  10,
  AppSpace.sm,
  10,
);

/// One confirmation style for adding and removing products.
class CartFeedbackContent extends StatelessWidget {
  const CartFeedbackContent({
    super.key,
    required this.product,
    required this.headline,
  });

  final Product product;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onInverseSurface;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
          child: SizedBox.square(
            dimension: 44,
            child: ExcludeSemantics(
              child: ProductImage(
                url: product.cardImageUrl,
                label: product.title,
                padding: AppSpace.xs,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.78),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

SnackBarAction cartFeedbackAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  final foreground = Theme.of(context).colorScheme.onInverseSurface;
  return SnackBarAction(
    label: label,
    textColor: foreground,
    backgroundColor: foreground.withValues(alpha: 0.12),
    onPressed: onPressed,
  );
}
