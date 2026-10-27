import 'package:flutter/material.dart';

/// Retail colours that are not part of [ColorScheme].
@immutable
class CatalogColors extends ThemeExtension<CatalogColors> {
  const CatalogColors({
    required this.sale,
    required this.saleContainer,
    required this.onSaleContainer,
    required this.inStock,
    required this.lowStock,
    required this.imageTile,
    required this.rating,
  });

  /// Discounts and savings.
  final Color sale;
  final Color saleContainer;
  final Color onSaleContainer;
  final Color inStock;
  final Color lowStock;

  /// Behind product photos, which mostly have white backgrounds.
  final Color imageTile;
  final Color rating;

  static CatalogColors of(BuildContext context) =>
      Theme.of(context).extension<CatalogColors>()!;

  @override
  CatalogColors copyWith({
    Color? sale,
    Color? saleContainer,
    Color? onSaleContainer,
    Color? inStock,
    Color? lowStock,
    Color? imageTile,
    Color? rating,
  }) => CatalogColors(
    sale: sale ?? this.sale,
    saleContainer: saleContainer ?? this.saleContainer,
    onSaleContainer: onSaleContainer ?? this.onSaleContainer,
    inStock: inStock ?? this.inStock,
    lowStock: lowStock ?? this.lowStock,
    imageTile: imageTile ?? this.imageTile,
    rating: rating ?? this.rating,
  );

  @override
  CatalogColors lerp(CatalogColors? other, double t) {
    if (other == null) return this;
    return CatalogColors(
      sale: Color.lerp(sale, other.sale, t)!,
      saleContainer: Color.lerp(saleContainer, other.saleContainer, t)!,
      onSaleContainer: Color.lerp(onSaleContainer, other.onSaleContainer, t)!,
      inStock: Color.lerp(inStock, other.inStock, t)!,
      lowStock: Color.lerp(lowStock, other.lowStock, t)!,
      imageTile: Color.lerp(imageTile, other.imageTile, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
    );
  }
}

/// Spacing and corner radii used across the app.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

abstract final class AppRadius {
  static const badge = 4.0;
  static const thumb = 8.0;
  static const control = 10.0;
  static const card = 12.0;
}

/// Neutral "paper and ink" palette with one warm accent for prices on sale.
abstract final class AppTheme {
  static final light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1F1D1A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE9E5DE),
      onPrimaryContainer: Color(0xFF1F1D1A),
      secondary: Color(0xFF6B665E),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE9E5DE),
      onSecondaryContainer: Color(0xFF1F1D1A),
      tertiary: Color(0xFFA63A26),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: Color(0xFFF7F5F1),
      onSurface: Color(0xFF1F1D1A),
      onSurfaceVariant: Color(0xFF6B665E),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF3F0EB),
      surfaceContainer: Color(0xFFEEEAE4),
      surfaceContainerHigh: Color(0xFFE9E5DE),
      surfaceContainerHighest: Color(0xFFE3DED6),
      outline: Color(0xFF9C968C),
      outlineVariant: Color(0xFFE0DBD3),
      inverseSurface: Color(0xFF2F2D2A),
      onInverseSurface: Color(0xFFF4F1EC),
      inversePrimary: Color(0xFFF0C9BE),
    ),
    const CatalogColors(
      sale: Color(0xFFA63A26),
      saleContainer: Color(0xFFF6E2DC),
      onSaleContainer: Color(0xFF7A2716),
      inStock: Color(0xFF6B665E),
      lowStock: Color(0xFFA63A26),
      imageTile: Color(0xFFFFFFFF),
      rating: Color(0xFFB7862B),
    ),
  );

  static final dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFF2EFE9),
      onPrimary: Color(0xFF1F1D1A),
      primaryContainer: Color(0xFF34322E),
      onPrimaryContainer: Color(0xFFF2EFE9),
      secondary: Color(0xFFB4AEA4),
      onSecondary: Color(0xFF1F1D1A),
      secondaryContainer: Color(0xFF34322E),
      onSecondaryContainer: Color(0xFFF2EFE9),
      tertiary: Color(0xFFF0A18F),
      onTertiary: Color(0xFF4A1408),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      surface: Color(0xFF151413),
      onSurface: Color(0xFFF2EFE9),
      onSurfaceVariant: Color(0xFFB4AEA4),
      surfaceContainerLowest: Color(0xFF1C1B19),
      surfaceContainerLow: Color(0xFF201F1D),
      surfaceContainer: Color(0xFF252422),
      surfaceContainerHigh: Color(0xFF2C2A27),
      surfaceContainerHighest: Color(0xFF34322E),
      outline: Color(0xFF7D776E),
      outlineVariant: Color(0xFF3A3834),
      inverseSurface: Color(0xFFF2EFE9),
      onInverseSurface: Color(0xFF2F2D2A),
      inversePrimary: Color(0xFFA63A26),
    ),
    const CatalogColors(
      sale: Color(0xFFF0A18F),
      saleContainer: Color(0xFF4E2219),
      onSaleContainer: Color(0xFFFFDAD2),
      inStock: Color(0xFFB4AEA4),
      lowStock: Color(0xFFF0A18F),
      // Product photos have white backgrounds; a soft off-white keeps them
      // from glaring in dark mode.
      imageTile: Color(0xFFECE9E4),
      rating: Color(0xFFE2B866),
    ),
  );

  static ThemeData _build(ColorScheme colors, CatalogColors catalog) {
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    // ThemeData's own text theme only gains font sizes inside Theme.of, so
    // component styles below need the size geometry merged in explicitly.
    final text = Typography.material2021().englishLike.merge(base.textTheme);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );
    const buttonSize = Size(64, 48);

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      extensions: [catalog],
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.25,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.55),
        labelSmall: text.labelSmall?.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: controlShape,
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
          foregroundColor: colors.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
        ),
        side: BorderSide(color: colors.outlineVariant),
        backgroundColor: colors.surfaceContainerLowest,
        selectedColor: colors.primary,
        labelStyle: text.labelLarge?.copyWith(color: colors.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: colors.onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.secondaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.secondaryContainer,
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        // Neutral, bold action instead of a tinted one.
        actionTextColor: colors.onInverseSurface,
        actionOverflowThreshold: 0.35,
        elevation: 2,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.outlineVariant,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: colors.onSurface,
        iconColor: colors.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: colors.shadow.withValues(alpha: 0.25),
        menuPadding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
