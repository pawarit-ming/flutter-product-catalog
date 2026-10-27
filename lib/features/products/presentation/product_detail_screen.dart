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
import '../data/thai_labels.dart';
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
              // Keeps lines of the description short enough to read easily.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: info,
                ),
              ),
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
                                ? colors.onSurface
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

/// Everything below the gallery, as one continuous page of headed sections
/// so nothing is hidden behind tabs.
class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = product.rating;
    final stock = product.stock;
    final dimensions = product.dimensions;
    final weight = product.weight;
    String number(double value) =>
        NumberFormat('#,##0.##', 'en_US').format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CategoryPill(
              slug: product.categorySlug,
              name: product.categoryName,
            ),
            if (product.brand case final brand?)
              Text(
                brand,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
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
        if (!product.isOutOfStock) ...[
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(child: Text('จำนวน', style: theme.textTheme.titleSmall)),
              QuantityStepper(
                value: quantity,
                max: CartItem.maxQuantityFor(product),
                onChanged: onQuantityChanged,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        _InfoCard(
          children: [
            if (stock != null)
              _FactRow(
                icon: Icons.inventory_2_outlined,
                label: 'สต็อก',
                child: StockLabel(stock: stock, fontSize: 14),
              ),
            if (product.shippingInformation case final shipping?)
              _FactRow(
                icon: Icons.local_shipping_outlined,
                label: 'การจัดส่ง',
                text: thaiShipping(shipping),
              ),
            if (product.warrantyInformation case final warranty?)
              _FactRow(
                icon: Icons.verified_user_outlined,
                label: 'การรับประกัน',
                text: thaiWarranty(warranty),
              ),
            if (product.returnPolicy case final returns?)
              _FactRow(
                icon: Icons.assignment_return_outlined,
                label: 'การคืนสินค้า',
                text: thaiReturnPolicy(returns),
              ),
          ],
        ),
        _Section(
          title: 'รายละเอียดสินค้า',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.description, style: theme.textTheme.bodyLarge),
              if (product.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [for (final tag in product.tags) _TagPill(tag)],
                ),
              ],
            ],
          ),
        ),
        _Section(
          title: 'ข้อมูลจำเพาะ',
          child: _SpecTable(
            rows: {
              'แบรนด์': product.brand,
              'หมวดหมู่': product.categoryName,
              'รหัสสินค้า (SKU)': product.sku,
              // The API gives no units for size and weight.
              'ขนาด (ก × ส × ล)': dimensions == null
                  ? null
                  : '${number(dimensions.width)} × '
                        '${number(dimensions.height)} × '
                        '${number(dimensions.depth)}',
              'น้ำหนัก': weight == null ? null : number(weight),
            },
          ),
        ),
        _Section(
          title: 'รีวิว (${product.reviews.length})',
          child: _Reviews(product: product),
        ),
      ],
    );
  }
}

/// The product's category in its own colour.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  Widget build(BuildContext context) {
    final tint = CategoryPalette.of(context, slug);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tint.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A titled block of the detail page, spaced well apart from the previous one.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Rows on a soft grey card, separated by hairlines. Renders nothing when
/// empty.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One key fact (stock, shipping, warranty, returns): a small label above
/// its value, so each line says what it is about.
class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    this.text,
    this.child,
  }) : assert(text != null || child != null);

  final IconData icon;
  final String label;
  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpace.md),
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
                const SizedBox(height: 2),
                child ?? Text(text!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        tag,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Key/value rows on a card. Values the API leaves out are skipped rather
/// than listed as unknown.
class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.rows});

  final Map<String, String?> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoCard(
      children: [
        for (final MapEntry(key: label, value: value) in rows.entries)
          if (value != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
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
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Five stars, filled up to [rating] rounded to whole stars.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = rating.round();
    final starColor = CatalogColors.of(context).rating;
    final emptyColor = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: 'ให้ $filled ดาว',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i <= filled ? starColor : emptyColor,
            ),
        ],
      ),
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.product});

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
    final rating = product.rating;
    final dateFormat = DateFormat('d/M/y');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rating != null) ...[
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stars(rating: rating, size: 20),
                    Text(
                      'จาก ${product.reviews.length} รีวิว',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const Divider(),
        ],
        for (final (index, review) in product.reviews.indexed) ...[
          if (index > 0) const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Builder(
                    builder: (context) {
                      // Each reviewer keeps the same colour everywhere.
                      final tint = CategoryPalette.forKey(
                        context,
                        review.reviewerName,
                      );
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: tint.background,
                        child: Text(
                          review.reviewerName.characters.firstOrNull
                                  ?.toUpperCase() ??
                              '?',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: tint.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: AppSpace.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Stars(rating: review.rating, size: 14),
                          if (review.date case final date?)
                            Text(
                              dateFormat.format(date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        review.comment,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
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

/// Adding is the primary action; viewing the cart never changes its contents.
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

    final buttons = Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: buttonStyle,
            onPressed: product.isOutOfStock
                ? null
                : () => addToCart(context, ref, product, quantity: quantity),
            icon: Icon(
              product.isOutOfStock
                  ? Icons.remove_shopping_cart_outlined
                  : Icons.add_shopping_cart_outlined,
              size: 20,
            ),
            label: Text(product.isOutOfStock ? 'สินค้าหมด' : 'ใส่ตะกร้า'),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: OutlinedButton.icon(
            style: buttonStyle,
            onPressed: () => showCart(context, ref),
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: const Text('ดูตะกร้า', textAlign: TextAlign.center),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
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
