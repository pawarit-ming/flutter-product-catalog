import 'package:intl/intl.dart';

// The API does not return a currency, so the app assumes USD.
final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

String formatPrice(double price) => _usd.format(price);

/// "home-decoration" -> "Home Decoration".
String humanizeSlug(String slug) => slug
    .split(RegExp(r'[-_\s]+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');
