import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/price_format.dart';
import '../application/product_detail_provider.dart';
import '../data/product.dart';
import 'product_list_screen.dart' show maxContentWidth;
import 'widgets/error_view.dart';
import 'widgets/product_image.dart';

/// Content at least this wide shows the image and details side by side.
const _twoPaneMinWidth = 840.0;

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productDetailProvider(productId);
    final asyncProduct = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: Text(asyncProduct.value?.title ?? 'Product')),
      body: asyncProduct.when(
        // Show the spinner again when Retry invalidates the provider.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final appError = AppException.from(error);
          if (appError.type == AppErrorType.notFound) {
            return ErrorView(
              icon: Icons.search_off,
              title: 'Product not found',
              message: 'This product may have been removed.',
              actionLabel: 'Back to products',
              onAction: () => Navigator.of(context).maybePop(),
            );
          }
          return ErrorView(
            message: appError.message,
            onAction: () => ref.invalidate(provider),
          );
        },
        data: (product) => _ProductDetailBody(product: product),
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth, maxContentWidth);
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: ProductImage(url: product.imageUrl, label: product.title),
          ),
        );
        final details = _ProductInfo(product: product);

        final Widget content;
        if (contentWidth >= _twoPaneMinWidth) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: image),
              const SizedBox(width: 32),
              Expanded(child: details),
            ],
          );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: image,
                ),
              ),
              const SizedBox(height: 24),
              details,
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: const Icon(Icons.sell_outlined, size: 18),
          label: Text(product.category.name),
        ),
        const SizedBox(height: 12),
        Text(product.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          formatPrice(product.price),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text('Description', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
