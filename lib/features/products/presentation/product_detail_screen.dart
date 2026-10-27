import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/price_format.dart';
import '../../../core/theme/app_theme.dart';
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
              const SizedBox(width: 40),
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
              const SizedBox(height: AppSpace.xl),
              info,
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xl,
          ),
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
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.outlineVariant),
          ),
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
                      padding: AppSpace.xl,
                    ),
                  ),
                Positioned(
                  top: AppSpace.md,
                  left: AppSpace.md,
                  child: DiscountBadge(product: product),
                ),
                if (images.length > 1)
                  Positioned(
                    right: AppSpace.md,
                    bottom: AppSpace.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.inverseSurface,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        '${_page + 1} / ${images.length}',
                        style: TextStyle(
                          color: colors.onInverseSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpace.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppSpace.sm,
              children: [
                for (var i = 0; i < images.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _page,
                    label: 'ดูรูปที่ ${i + 1}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.thumb),
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
                          borderRadius: BorderRadius.circular(AppRadius.thumb),
                          border: Border.all(
                            width: i == _page ? 1.5 : 1,
                            color: i == _page
                                ? colors.primary
                                : colors.outlineVariant,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: ProductImage(
                            url: images[i],
                            label: '',
                            padding: AppSpace.xs,
                          ),
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
    final stock = product.stock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [?product.brand, product.categoryName].join(' · ').toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(product.title, style: theme.textTheme.headlineSmall),
        if (rating != null) ...[
          const SizedBox(height: AppSpace.sm),
          RatingLabel(
            rating: rating,
            reviewCount: product.reviews.length,
            fontSize: 14,
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        PriceRow(product: product, large: true),
        if (product.hasDiscount) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            'ประหยัด ${formatPrice(product.savings)} '
            '(${product.discountBadge}%)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CatalogColors.of(context).sale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        const Divider(),
        if (stock != null)
          _FactRow(
            icon: Icons.inventory_2_outlined,
            child: StockLabel(stock: stock, fontSize: 14),
          ),
        if (product.shippingInformation case final shipping?)
          _FactRow(icon: Icons.local_shipping_outlined, text: shipping),
        if (product.warrantyInformation case final warranty?)
          _FactRow(icon: Icons.verified_user_outlined, text: warranty),
        if (!product.isOutOfStock) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: Text('จำนวน', style: theme.textTheme.titleSmall)),
              QuantityStepper(
                value: widget.quantity,
                max: CartItem.maxQuantityFor(product),
                onChanged: widget.onQuantityChanged,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        _SectionTabs(
          selected: _tab,
          labels: {
            _InfoTab.details: 'รายละเอียด',
            _InfoTab.shipping: 'การจัดส่งและคืนสินค้า',
            _InfoTab.reviews: 'รีวิว (${product.reviews.length})',
          },
          onSelected: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpace.lg),
        switch (_tab) {
          _InfoTab.details => _DetailsTab(product: product),
          _InfoTab.shipping => _ShippingTab(product: product),
          _InfoTab.reviews => _ReviewsTab(product: product),
        },
      ],
    );
  }
}

/// One line of key facts under the price (stock, shipping, warranty).
class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, this.text, this.child})
    : assert(text != null || child != null);

  final IconData icon;
  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: child ?? Text(text!, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Text tabs with an underline, for switching the sections below.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final _InfoTab selected;
  final Map<_InfoTab, String> labels;
  final ValueChanged<_InfoTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final MapEntry(key: tab, value: label) in labels.entries)
              Semantics(
                selected: tab == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(tab),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: tab == selected
                              ? colors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tab == selected
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontWeight: tab == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
        const SizedBox(height: AppSpace.xl),
        Text('ข้อมูลจำเพาะ', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpace.xs),
        _SpecTable(
          rows: {
            'แบรนด์': product.brand,
            'หมวดหมู่': product.categoryName,
            'SKU': product.sku,
            // The API gives no units for size and weight.
            'ขนาด (ก × ส × ล)': dimensions == null
                ? null
                : '${number(dimensions.width)} × '
                      '${number(dimensions.height)} × '
                      '${number(dimensions.depth)}',
            'น้ำหนัก': weight == null ? null : number(weight),
          },
        ),
        if (product.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              for (final tag in product.tags)
                Text(
                  '#$tag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
    return _SpecTable(
      rows: {
        'การจัดส่ง': product.shippingInformation,
        'การรับประกัน': product.warrantyInformation,
        'การคืนสินค้า': product.returnPolicy,
      },
    );
  }
}

/// Two-column key/value list separated by hairlines.
class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.rows});

  final Map<String, String?> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final MapEntry(key: label, value: value) in rows.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  flex: 3,
                  child: Text(
                    value ?? 'ไม่ระบุ',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
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
    final colors = theme.colorScheme;
    if (product.reviews.isEmpty) {
      return Text(
        'ยังไม่มีรีวิว',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }
    final dateFormat = DateFormat('d/M/y');
    final starColor = CatalogColors.of(context).rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final review in product.reviews) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (review.date case final date?)
                      Text(
                        dateFormat.format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Semantics(
                  label: 'ให้ ${review.rating.round()} ดาว',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: i <= review.rating.round()
                              ? starColor
                              : colors.outline,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(review.comment, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const Divider(),
        ],
      ],
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
    final colors = Theme.of(context).colorScheme;
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
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
              label: const Text('ใส่ตะกร้า'),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: FilledButton(
              style: buttonStyle,
              onPressed: () {
                final result = ref
                    .read(cartProvider.notifier)
                    .add(product, quantity: quantity);
                if (result != AddToCartResult.outOfStock) {
                  showCart(context, ref);
                }
              },
              child: const Text('ซื้อเลย'),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
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
