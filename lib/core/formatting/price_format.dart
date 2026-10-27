import 'package:intl/intl.dart';

// The API does not return a currency, so the app assumes USD.
final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

String formatPrice(double price) => _usd.format(price);
