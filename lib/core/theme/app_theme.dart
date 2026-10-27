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
  static const xxl = 32.0;
}

/// Soft, friendly corners; pills for small tags and round buttons.
abstract final class AppRadius {
  static const badge = 999.0;
  static const thumb = 12.0;
  static const control = 12.0;
  static const card = 16.0;
}

/// The bundled typeface (assets/fonts): one variable file covering Thai and
/// Latin, so [FontWeight] picks any weight from 100 to 700.
abstract final class AppFonts {
  static const family = 'Anuphan';
}

/// Clean retail palette: products sit on white cards over a light grey page.
/// Deep green is kept for buying (filled buttons), selection is shown in ink,
/// coral marks discounts and favourites, and each category has its own tint
/// (see [CategoryPalette]).
abstract final class AppTheme {
  static final light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1F5C4A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE6F1EC),
      onPrimaryContainer: Color(0xFF123B2F),
      secondary: Color(0xFF5F6670),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF1F3F4),
      onSecondaryContainer: Color(0xFF14181F),
      tertiary: Color(0xFF1F5C4A),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: Color(0xFFF2F3F5),
      onSurface: Color(0xFF14181F),
      onSurfaceVariant: Color(0xFF6B7280),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF7F8F9),
      surfaceContainer: Color(0xFFEEF0F2),
      surfaceContainerHigh: Color(0xFFE5E7EB),
      surfaceContainerHighest: Color(0xFFDDE0E4),
      outline: Color(0xFFA3A9B1),
      outlineVariant: Color(0xFFE6E8EB),
      inverseSurface: Color(0xFF1D2127),
      onInverseSurface: Color(0xFFF3F4F6),
      inversePrimary: Color(0xFF8FD1B8),
    ),
    const CatalogColors(
      sale: Color(0xFFE4572E),
      saleContainer: Color(0xFFFDEBE5),
      onSaleContainer: Color(0xFFA5311A),
      inStock: Color(0xFF6B7280),
      lowStock: Color(0xFFC2410C),
      // Photos sit straight on the white card.
      imageTile: Color(0xFFFFFFFF),
      rating: Color(0xFFE0A100),
    ),
  );

  static final dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8FD1B8),
      onPrimary: Color(0xFF0B2A20),
      primaryContainer: Color(0xFF1C3A30),
      onPrimaryContainer: Color(0xFFCDEBDF),
      secondary: Color(0xFFA9AFB8),
      onSecondary: Color(0xFF14181F),
      secondaryContainer: Color(0xFF23272D),
      onSecondaryContainer: Color(0xFFF1F2F4),
      tertiary: Color(0xFF8FD1B8),
      onTertiary: Color(0xFF0B2A20),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      surface: Color(0xFF0E1012),
      onSurface: Color(0xFFF1F2F4),
      onSurfaceVariant: Color(0xFFA9AFB8),
      surfaceContainerLowest: Color(0xFF1A1D21),
      surfaceContainerLow: Color(0xFF1E2125),
      surfaceContainer: Color(0xFF262A2F),
      surfaceContainerHigh: Color(0xFF2D3238),
      surfaceContainerHighest: Color(0xFF353A41),
      outline: Color(0xFF6F7680),
      outlineVariant: Color(0xFF2A2F35),
      inverseSurface: Color(0xFFF1F2F4),
      onInverseSurface: Color(0xFF1D2127),
      inversePrimary: Color(0xFF1F5C4A),
    ),
    const CatalogColors(
      sale: Color(0xFFFF8A65),
      saleContainer: Color(0xFF4A2117),
      onSaleContainer: Color(0xFFFFD5C7),
      inStock: Color(0xFFA9AFB8),
      lowStock: Color(0xFFF59E66),
      // Product photos have white backgrounds; a soft off-white keeps them
      // from glaring in dark mode.
      imageTile: Color(0xFFE4E7EA),
      rating: Color(0xFFF2C14E),
    ),
  );

  static ThemeData _build(ColorScheme colors, CatalogColors catalog) {
    final base = ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      fontFamily: AppFonts.family,
    );
    // ThemeData's own text theme only gains font sizes inside Theme.of, so
    // component styles below need the size geometry merged in explicitly.
    final text = Typography.material2021().englishLike.merge(base.textTheme);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );
    const buttonSize = Size(64, 48);
    final hairline = BorderSide(color: colors.outlineVariant);

    final textTheme = text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: text.labelSmall?.copyWith(
        letterSpacing: 0.6,
        fontWeight: FontWeight.w500,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      extensions: [catalog],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
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
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: const StadiumBorder(),
          foregroundColor: colors.onSurface,
          // White fill and a mid-grey edge keep it visible on the grey page
          // and on white bars alike.
          backgroundColor: colors.surfaceContainerLowest,
          side: BorderSide(color: colors.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
          foregroundColor: colors.onSurface,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: colors.surfaceContainerLowest,
        // Selection is shown in ink; green is kept for buying.
        selectedColor: colors.onSurface,
        labelStyle: text.labelLarge?.copyWith(color: colors.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: colors.surfaceContainerLowest,
        ),
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.onSurface, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.surfaceContainerHigh,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.surfaceContainerHigh,
        selectedIconTheme: IconThemeData(color: colors.onSurface),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
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
        color: colors.onSurface,
        linearTrackColor: colors.surfaceContainerHigh,
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
        shadowColor: colors.shadow.withValues(alpha: 0.18),
        menuPadding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: hairline,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card + 8),
        ),
      ),
    );
  }
}

/// A light tint and a readable ink per product category, so each category is
/// recognisable at a glance. Unlisted categories get a stable colour derived
/// from their slug.
abstract final class CategoryPalette {
  static const _light = [
    (Color(0xFFFCE7F3), Color(0xFFBE185D)), // pink
    (Color(0xFFEDE9FE), Color(0xFF6D28D9)), // violet
    (Color(0xFFFEF3C7), Color(0xFFB45309)), // amber
    (Color(0xFFDCFCE7), Color(0xFF15803D)), // green
    (Color(0xFFDBEAFE), Color(0xFF1D4ED8)), // blue
    (Color(0xFFCCFBF1), Color(0xFF0F766E)), // teal
    (Color(0xFFFFEDD5), Color(0xFFC2410C)), // orange
    (Color(0xFFE0F2FE), Color(0xFF0369A1)), // sky
  ];
  static const _dark = [
    (Color(0xFF3B1426), Color(0xFFF9A8D4)),
    (Color(0xFF2A1F4D), Color(0xFFC4B5FD)),
    (Color(0xFF3A2A0B), Color(0xFFFCD34D)),
    (Color(0xFF0F2E1A), Color(0xFF86EFAC)),
    (Color(0xFF172554), Color(0xFF93C5FD)),
    (Color(0xFF0B2E2A), Color(0xFF5EEAD4)),
    (Color(0xFF3B1D0B), Color(0xFFFDBA74)),
    (Color(0xFF0C2A3D), Color(0xFF7DD3FC)),
  ];

  static int _index(String slug) => switch (slug) {
    'beauty' || 'skin-care' || 'tops' => 0,
    'fragrances' => 1,
    'furniture' || 'home-decoration' => 2,
    'groceries' => 3,
    'laptops' || 'tablets' || 'smartphones' || 'mobile-accessories' => 4,
    'sports-accessories' => 5,
    'kitchen-accessories' || 'sunglasses' => 6,
    'motorcycle' || 'vehicle' => 7,
    final s when s.startsWith('womens-') => 0,
    final s when s.startsWith('mens-') => 7,
    _ => _hash(slug),
  };

  static int _hash(String key) =>
      key.codeUnits.fold(0, (sum, unit) => sum + unit) % _light.length;

  static ({Color background, Color foreground}) _pick(
    BuildContext context,
    int index,
  ) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    final (background, foreground) = palette[index];
    return (background: background, foreground: foreground);
  }

  static ({Color background, Color foreground}) of(
    BuildContext context,
    String slug,
  ) => _pick(context, _index(slug));

  /// A stable tint for any other [key], such as a reviewer's name.
  static ({Color background, Color foreground}) forKey(
    BuildContext context,
    String key,
  ) => _pick(context, _hash(key));
}
