import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Rows on a white card, separated by hairlines. A [Material], so the rows'
/// ink ripples show on it. Renders nothing when empty.
class DividedCard extends StatelessWidget {
  const DividedCard({
    super.key,
    required this.children,
    this.indent = AppSpace.lg,
  });

  final List<Widget> children;

  /// Inset of the hairlines from both sides.
  final double indent;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(indent: indent, endIndent: indent),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
