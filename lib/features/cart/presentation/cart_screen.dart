import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/price_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/application/home_tab_provider.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/widgets/divided_card.dart';
import '../../products/presentation/widgets/error_view.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_labels.dart';
import '../application/cart_provider.dart';
import 'cart_feedback.dart';
import 'quantity_stepper.dart';

const _maxCartWidth = 720.0;
const _thumbSize = 72.0;

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างตะกร้า?'),
        content: const Text('สินค้าทั้งหมดในตะกร้าจะถูกนำออก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ล้างตะกร้า'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) ref.read(cartProvider.notifier).clear();
  }

  void _keepShopping(WidgetRef ref) =>
      ref.read(homeTabProvider.notifier).select(HomeTab.catalog);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('ล้างตะกร้า'),
            ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_bag_outlined,
              title: 'ตะกร้าว่างเปล่า',
              message: 'เลือกสินค้าที่ชอบแล้วกด "ใส่ตะกร้า"',
              action: FilledButton(
                onPressed: () => _keepShopping(ref),
                child: const Text('เลือกซื้อสินค้า'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    children: [
                      _Constrained(
                        child: DividedCard(
                          indent: AppSpace.md,
                          children: [
                            for (final item in items) _CartLine(item: item),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      const _Constrained(child: _OrderSummary()),
                      const SizedBox(height: AppSpace.md),
                      const _Constrained(child: _CheckoutNote()),
                    ],
                  ),
                ),
                _TotalBar(onKeepShopping: () => _keepShopping(ref)),
              ],
            ),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxCartWidth),
      child: child,
    ),
  );
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  void _remove(BuildContext context, WidgetRef ref) {
    // Capture root-owned objects: this line's WidgetRef is disposed on remove.
    final cart = ref.read(cartProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
    final removal = cart.removeWithUndo(item.product.id);
    if (removal == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          padding: cartFeedbackPadding,
          content: CartFeedbackContent(
            product: item.product,
            headline: 'นำออกจากตะกร้าแล้ว',
          ),
          duration: const Duration(seconds: 5),
          persist: accessibleNavigation,
          action: cartFeedbackAction(
            context,
            label: 'เลิกทำ',
            onPressed: () {
              if (!cart.undoRemoval(removal) && messenger.mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ตะกร้ามีการเปลี่ยนแปลงแล้ว จึงคงรายการปัจจุบันไว้',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cart = ref.read(cartProvider.notifier);

    return InkWell(
      onTap: () => ProductDetailScreen.open(context, product.id),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _thumbSize,
              height: _thumbSize,
              clipBehavior: Clip.antiAlias,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.thumb),
                border: Border.all(color: colors.outlineVariant),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.thumb),
              ),
              child: ProductImage(
                url: product.cardImageUrl,
                label: product.title,
                padding: AppSpace.sm,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 48,
                        child: IconButton(
                          tooltip: 'นำออกจากตะกร้า',
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          onPressed: () => _remove(context, ref),
                          icon: Icon(
                            Icons.close,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  PriceRow(product: product),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      QuantityStepper(
                        dense: true,
                        value: item.quantity,
                        max: CartItem.maxQuantityFor(product),
                        onChanged: (value) =>
                            cart.setQuantity(product.id, value),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatPrice(item.lineTotal),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Price breakdown right below the items.
class _OrderSummary extends ConsumerWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = ref.watch(cartTotalsProvider);
    final count = ref.watch(cartCountProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปยอด',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _AmountRow(
            label: 'ราคาสินค้า ($count ชิ้น)',
            value: formatPrice(totals.listTotal),
          ),
          if (totals.savings > 0)
            _AmountRow(
              label: 'ส่วนลด',
              value: '-${formatPrice(totals.savings)}',
              color: CatalogColors.of(context).sale,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Divider(),
          ),
          _AmountRow(
            label: 'ยอดรวม',
            value: formatPrice(totals.subtotal),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _CheckoutNote extends StatelessWidget {
  const _CheckoutNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: muted),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            'แอปตัวอย่างนี้ยังไม่มีขั้นตอนชำระเงิน ตะกร้าจะบันทึกไว้ในเครื่องนี้',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// Always-visible total with a way back to the catalog.
class _TotalBar extends ConsumerWidget {
  const _TotalBar({required this.onKeepShopping});

  final VoidCallback onKeepShopping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totals = ref.watch(cartTotalsProvider);
    final count = ref.watch(cartCountProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: _Constrained(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยอดรวม · $count ชิ้น',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPrice(totals.subtotal),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                OutlinedButton(
                  onPressed: onKeepShopping,
                  child: const Text('เลือกซื้อต่อ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = emphasize
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
    final valueStyle =
        (emphasize
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  )
                : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: AppSpace.sm),
          // Large totals at big text sizes shrink instead of overflowing.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: valueStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
