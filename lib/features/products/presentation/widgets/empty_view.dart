import 'package:flutter/material.dart';

import 'error_view.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.inventory_2_outlined,
      title: 'No products found',
      message: 'Pull down to refresh, or try again.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}
