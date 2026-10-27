import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/price_format.dart';
import '../../home/application/home_tab_provider.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/widgets/error_view.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_labels.dart';
import '../application/cart_provider.dart';
import 'quantity_stepper.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'ล้างตะกร้า',
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_cart_outlined,
              title: 'ตะกร้าว่างเปล่า',
              message: 'เลือกสินค้าที่ชอบแล้วกด "ใส่ตะกร้า"',
              action: FilledButton(
                onPressed: () =>
                    ref.read(homeTabProvider.notifier).select(HomeTab.catalog),
                child: const Text('เลือกซื้อสินค้า'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _CartLine(item: items[index]),
                      ),
                    ),
                  ),
                ),
                const _CartSummary(),
              ],
            ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final theme = Theme.of(context);
    final cart = ref.read(cartProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ProductDetailScreen.open(context, product.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.square(
                  dimension: 80,
                  child: ProductImage(
                    url: product.cardImageUrl,
                    label: product.title,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    PriceRow(product: product),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        QuantityStepper(
                          value: item.quantity,
                          max: CartItem.maxQuantityFor(product),
                          onChanged: (value) =>
                              cart.setQuantity(product.id, value),
                        ),
                        Text(
                          formatPrice(item.lineTotal),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'นำออกจากตะกร้า',
                onPressed: () => cart.remove(product.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = ref.watch(cartTotalsProvider);
    final count = ref.watch(cartCountProvider);

    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryRow(label: 'จำนวนสินค้า', value: '$count ชิ้น'),
                  if (totals.savings > 0)
                    _SummaryRow(
                      label: 'ส่วนลดรวม',
                      value: '-${formatPrice(totals.savings)}',
                      color: theme.colorScheme.error,
                    ),
                  _SummaryRow(
                    label: 'ยอดรวม',
                    value: formatPrice(totals.subtotal),
                    emphasize: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'แอปตัวอย่างนี้ยังไม่มีระบบชำระเงิน',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
    final style = emphasize
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          // Large totals at big text sizes shrink instead of overflowing.
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: style?.copyWith(color: color)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
