import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Product photo on a neutral tile. Photos are shown whole (`contain`) with a
/// little breathing room instead of being cropped, and fall back to a
/// placeholder when the URL is missing or fails to load.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    required this.label,
    this.padding = AppSpace.md,
  });

  final String? url;
  final String label;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final tile = CatalogColors.of(context).imageTile;

    return ColoredBox(
      color: tile,
      child: url == null
          ? _Placeholder(label: label)
          : Padding(
              padding: EdgeInsets.all(padding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pixelRatio = MediaQuery.devicePixelRatioOf(context);
                  return Image(
                    image: ResizeImage(
                      CachedNetworkImageProvider(url),
                      width: _decodeExtent(constraints.maxWidth, pixelRatio),
                      height: _decodeExtent(constraints.maxHeight, pixelRatio),
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.contain,
                    semanticLabel: label,
                    frameBuilder: (context, child, frame, wasSync) =>
                        wasSync || MediaQuery.disableAnimationsOf(context)
                        ? child
                        : AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: child,
                          ),
                    errorBuilder: (context, error, stackTrace) =>
                        _Placeholder(label: label),
                  );
                },
              ),
            ),
    );
  }

  // Bound unbounded axes too, so even a loose parent cannot decode an enormous
  // image into the in-memory cache. The fit policy preserves the source ratio.
  static int _decodeExtent(double logicalExtent, double pixelRatio) =>
      logicalExtent.isFinite
      ? (logicalExtent * pixelRatio).ceil().clamp(1, 2048)
      : 2048;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ไม่มีรูปภาพ',
      image: true,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
