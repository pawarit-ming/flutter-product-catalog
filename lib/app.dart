import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/storage/shopping_storage_notice.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_shell.dart';

class ProductCatalogApp extends StatelessWidget {
  const ProductCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'แคตตาล็อกสินค้า',
      debugShowCheckedModeBanner: false,
      locale: const Locale('th'),
      supportedLocales: const [Locale('th')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) =>
          ShoppingStorageNotice(child: child ?? const SizedBox.shrink()),
      home: const HomeShell(),
    );
  }
}
