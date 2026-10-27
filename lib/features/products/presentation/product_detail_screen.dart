import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/price_format.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/add_to_cart.dart';
import '../../cart/presentation/quantity_stepper.dart';
import '../../wishlist/presentation/wishlist_button.dart';
import '../application/product_detail_provider.dart';
import '../data/product.dart';
import 'widgets/error_view.dart';
import 'widgets/product_grid.dart' show maxContentWidth;
import 'widgets/product_image.dart';
import 'widgets/product_labels.dart';

/// Content at least this wide shows the gallery and details side by side.
const _twoPaneMinWidth = 840.0;

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  static Future<void> open(BuildContext context, int productId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(productId: productId),
        ),
      );

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final provider = productDetailProvider(widget.productId);
    final asyncProduct = ref.watch(provider);
    final product = asyncProduct.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสินค้า'),
        actions: [if (product != null) WishlistButton(product: product)],
      ),
      body: asyncProduct.when(
        // Show the spinner again when Retry invalidates the provider.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final appError = AppException.from(error);
          if (appError.type == AppErrorType.notFound) {
            return ErrorView(
              icon: Icons.search_off,
              title: 'ไม่พบสินค้า',
              message: 'สินค้านี้อาจถูกนำออกไปแล้ว',
              actionLabel: 'กลับไปหน้ารายการ',
              actionIcon: Icons.arrow_back,
              onAction: () => Navigator.of(context).maybePop(),
            );
          }
          return ErrorView(
            message: appError.message,
            onAction: () => ref.invalidate(provider),
          );
        },
        data: (product) => _ProductDetailBody(
          product: product,
          quantity: _quantity,
          onQuantityChanged: (value) => setState(() => _quantity = value),
        ),
      ),
      bottomNavigationBar: product == null || asyncProduct.isLoading
          ? null
          : _PurchaseBar(product: product, quantity: _quantity),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth, maxContentWidth);
        final gallery = _Gallery(product: product);
        final info = _ProductInfo(
          product: product,
          quantity: quantity,
          onQuantityChanged: onQuantityChanged,
        );

        final Widget content;
        if (contentWidth >= _twoPaneMinWidth) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: gallery),
              const SizedBox(width: 32),
              Expanded(child: info),
            ],
          );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: gallery,
                ),
              ),
              const SizedBox(height: 20),
              info,
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

/// Swipeable images with a page counter and tappable thumbnails.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.galleryImages;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  ProductImage(url: null, label: product.title)
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) => ProductImage(
                      url: images[index],
                      label: '${product.title} รูปที่ ${index + 1}',
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: DiscountBadge(product: product),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.inverseSurface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_page + 1}/${images.length}',
                        style: TextStyle(
                          color: colors.onInverseSurface,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (var i = 0; i < images.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _page,
                    label: 'ดูรูปที่ ${i + 1}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 2,
                            color: i == _page
                                ? colors.primary
                                : colors.outlineVariant,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: ProductImage(url: images[i], label: ''),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _InfoTab { details, shipping, reviews }

class _ProductInfo extends StatefulWidget {
  const _ProductInfo({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  State<_ProductInfo> createState() => _ProductInfoState();
}

class _ProductInfoState extends State<_ProductInfo> {
  _InfoTab _tab = _InfoTab.details;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final rating = product.rating;
    final shipping = product.shippingInformation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            ?product.brand,
            product.categoryName,
            if (product.sku case final sku?) 'SKU: $sku',
          ].join(' • '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(product.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (rating != null)
              RatingLabel(
                rating: rating,
                reviewCount: product.reviews.length,
                fontSize: 14,
              ),
            if (product.warrantyInformation case final warranty?)
              _InfoChip(icon: Icons.verified_user_outlined, text: warranty),
          ],
        ),
        const SizedBox(height: 16),
        PriceRow(product: product, large: true),
        if (product.hasDiscount) ...[
          const SizedBox(height: 6),
          _InfoChip(
            icon: Icons.local_offer_outlined,
            text:
                'ประหยัด ${formatPrice(product.savings)} '
                '(${product.discountBadge}%)',
            highlight: true,
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StockLabel(stock: product.stock, fontSize: 14),
            if (shipping != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(shipping, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
          ],
        ),
        if (!product.isOutOfStock) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('จำนวน', style: theme.textTheme.titleMedium),
              ),
              QuantityStepper(
                value: widget.quantity,
                max: CartItem.maxQuantityFor(product),
                onChanged: widget.onQuantityChanged,
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tab in _InfoTab.values)
              ChoiceChip(
                label: Text(switch (tab) {
                  _InfoTab.details => 'รายละเอียด',
                  _InfoTab.shipping => 'การจัดส่งและคืนสินค้า',
                  _InfoTab.reviews => 'รีวิว (${product.reviews.length})',
                }),
                selected: _tab == tab,
                onSelected: (_) => setState(() => _tab = tab),
              ),
          ],
        ),
        const SizedBox(height: 16),
        switch (_tab) {
          _InfoTab.details => _DetailsTab(product: product),
          _InfoTab.shipping => _ShippingTab(product: product),
          _InfoTab.reviews => _ReviewsTab(product: product),
        },
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = product.dimensions;
    final weight = product.weight;
    String number(double value) =>
        NumberFormat('#,##0.##', 'en_US').format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        _SpecRow(label: 'แบรนด์', value: product.brand),
        _SpecRow(label: 'หมวดหมู่', value: product.categoryName),
        // The API gives no units for size and weight.
        _SpecRow(
          label: 'ขนาด (กว้าง × สูง × ลึก)',
          value: dimensions == null
              ? null
              : '${number(dimensions.width)} × ${number(dimensions.height)} '
                    '× ${number(dimensions.depth)}',
        ),
        _SpecRow(
          label: 'น้ำหนัก',
          value: weight == null ? null : number(weight),
        ),
        if (product.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in product.tags)
                Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ShippingTab extends StatelessWidget {
  const _ShippingTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SpecRow(
          icon: Icons.local_shipping_outlined,
          label: 'การจัดส่ง',
          value: product.shippingInformation,
        ),
        _SpecRow(
          icon: Icons.verified_user_outlined,
          label: 'การรับประกัน',
          value: product.warrantyInformation,
        ),
        _SpecRow(
          icon: Icons.assignment_return_outlined,
          label: 'การคืนสินค้า',
          value: product.returnPolicy,
        ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (product.reviews.isEmpty) {
      return Text('ยังไม่มีรีวิว', style: theme.textTheme.bodyMedium);
    }
    final dateFormat = DateFormat('d/M/y');
    return Column(
      children: [
        for (final review in product.reviews)
          Card.outlined(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        review.reviewerName,
                        style: theme.textTheme.titleSmall,
                      ),
                      RatingLabel(rating: review.rating),
                      if (review.date case final date?)
                        Text(
                          dateFormat.format(date),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review.comment, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value, this.icon});

  final String label;
  final String? value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value ?? 'ไม่ระบุ', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = highlight
        ? colors.onErrorContainer
        : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar with "Add to cart" and "Buy now" (adds, then opens the cart).
class _PurchaseBar extends ConsumerWidget {
  const _PurchaseBar({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(0, 52)),
    );

    final Widget buttons;
    if (product.isOutOfStock) {
      buttons = FilledButton(
        onPressed: null,
        style: buttonStyle,
        child: const Text('สินค้าหมด'),
      );
    } else {
      buttons = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: buttonStyle,
              onPressed: () =>
                  addToCart(context, ref, product, quantity: quantity),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('ใส่ตะกร้า'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: buttonStyle,
              onPressed: () {
                final result = ref
                    .read(cartProvider.notifier)
                    .add(product, quantity: quantity);
                if (result != AddToCartResult.outOfStock) {
                  showCart(context, ref);
                }
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('ซื้อเลย'),
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: 3,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: buttons,
            ),
          ),
        ),
      ),
    );
  }
}
