import 'package:flutter/material.dart';

/// Network image with a loading placeholder and a fallback when the URL is
/// missing or the image fails to load. Fills the space given by its parent.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, required this.label});

  final String? url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) return _Placeholder(label: label);

    return Image.network(
      url,
      fit: BoxFit.cover,
      semanticLabel: label,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _Background(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _Placeholder(label: label),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, image unavailable',
      image: true,
      child: _Background(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: child),
    );
  }
}
