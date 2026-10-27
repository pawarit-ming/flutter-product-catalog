import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/riverpod/no_retry.dart';

void main() {
  runApp(const ProviderScope(retry: noRetry, child: ProductCatalogApp()));
}
