import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// "−  2  +" control. The regular size has 48 dp touch targets; [dense] is a
/// visually 40 dp pill with the same 48 dp touch targets for cart lines.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.dense = false,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final buttonStyle = dense
        ? IconButton.styleFrom(
            fixedSize: const Size.square(48),
            minimumSize: const Size.square(48),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
          )
        : null;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'ลดจำนวน',
          iconSize: 18,
          style: buttonStyle,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: dense ? 20 : 24),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            semanticsLabel: 'จำนวน $value',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          tooltip: 'เพิ่มจำนวน',
          iconSize: 18,
          style: buttonStyle,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
    final decoration = BoxDecoration(
      // Dense steppers sit on white cart cards; the regular one sits on the
      // grey page, so it is white with an edge.
      color: dense ? colors.surfaceContainer : colors.surfaceContainerLowest,
      border: dense ? null : Border.all(color: colors.outline),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    );
    if (!dense) return DecoratedBox(decoration: decoration, child: controls);
    // Only the background is inset. Both buttons still receive the full hit
    // area, and the row can grow naturally with larger accessibility fonts.
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          top: AppSpace.xs,
          bottom: AppSpace.xs,
          child: DecoratedBox(decoration: decoration),
        ),
        controls,
      ],
    );
  }
}
