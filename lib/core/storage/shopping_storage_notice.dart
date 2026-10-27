import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shopping_storage.dart';

/// A persistent, dismissible notice if device storage cannot be used reliably.
class ShoppingStorageNotice extends ConsumerWidget {
  const ShoppingStorageNotice({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(shoppingStorageProvider);
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<String?>(
      valueListenable: storage.issue,
      child: child,
      builder: (context, issue, child) {
        if (issue == null) return child!;
        return ColoredBox(
          color: colors.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MaterialBanner(
                  backgroundColor: colors.errorContainer,
                  content: Text(issue),
                  leading: const Icon(Icons.info_outline),
                  actions: [
                    TextButton(
                      onPressed: storage.dismissIssue,
                      child: const Text('ปิดข้อความ'),
                    ),
                  ],
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: child!,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
