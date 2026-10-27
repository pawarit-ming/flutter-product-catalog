import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/riverpod/no_retry.dart';
import 'core/storage/shopping_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await ShoppingStorage.open();
  runApp(
    ProviderScope(
      retry: noRetry,
      overrides: [
        shoppingStorageProvider.overrideWith((ref) {
          ref.onDispose(storage.dispose);
          return storage;
        }),
      ],
      child: const ProductCatalogApp(),
    ),
  );
}
