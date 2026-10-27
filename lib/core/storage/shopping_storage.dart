import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const cartStorageKey = 'catalog.cart.v1';
const wishlistStorageKey = 'catalog.wishlist.v1';

/// A memory store keeps isolated ProviderScopes independent of native plugins.
/// main() overrides it with the store loaded from this device before runApp.
final shoppingStorageProvider = Provider<ShoppingStorage>((ref) {
  final storage = ShoppingStorage.memory();
  ref.onDispose(storage.dispose);
  return storage;
});

class ShoppingStorage {
  ShoppingStorage._(this._preferences, this._values, this._unreadableKeys);

  factory ShoppingStorage.memory() => ShoppingStorage._(null, {}, {});

  final SharedPreferencesAsync? _preferences;
  final Map<String, String> _values;
  final Set<String> _unreadableKeys;
  final issue = ValueNotifier<String?>(null);
  Future<void> _pendingWrite = Future.value();
  bool _disposed = false;

  /// Finish restoring both collections before they can be edited. Failed reads
  /// are never written back as empty collections over existing device data.
  static Future<ShoppingStorage> open() async {
    final preferences = SharedPreferencesAsync();
    final values = <String, String>{};
    final unreadableKeys = <String>{};
    for (final key in [cartStorageKey, wishlistStorageKey]) {
      try {
        final value = await preferences.getString(key);
        if (value != null) values[key] = value;
      } catch (_) {
        unreadableKeys.add(key);
      }
    }
    final storage = ShoppingStorage._(preferences, values, unreadableKeys);
    if (unreadableKeys.isNotEmpty) {
      storage.issue.value =
          'โหลดข้อมูลในเครื่องบางส่วนไม่สำเร็จ การเปลี่ยนแปลงส่วนนั้นจะเก็บไว้เฉพาะครั้งนี้';
    }
    return storage;
  }

  List<Object?> readList(String key) {
    final encoded = _values[key];
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) throw const FormatException('Expected a list');
      return decoded;
    } on FormatException {
      _unreadableKeys.add(key);
      _report(
        'ข้อมูลที่บันทึกไว้บางส่วนอ่านไม่ได้ การเปลี่ยนแปลงส่วนนั้นจะเก็บไว้เฉพาะครั้งนี้',
      );
      return const [];
    }
  }

  void reportInvalidData() => _report(
    'ข้อมูลที่บันทึกไว้บางรายการอ่านไม่ได้ จึงแสดงเฉพาะรายการที่กู้คืนได้',
  );

  /// Capture the snapshot now, then serialize writes so a slow older save
  /// cannot restore removed items or overwrite a more recent quantity.
  void writeList(String key, List<Object?> values) {
    final encoded = jsonEncode(values);
    _values[key] = encoded;
    final preferences = _preferences;
    if (preferences == null || _unreadableKeys.contains(key)) return;
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await preferences.setString(key, encoded);
      } catch (_) {
        _report(
          'บันทึกข้อมูลลงเครื่องไม่สำเร็จ การเปลี่ยนแปลงล่าสุดอาจหายเมื่อปิดแอป',
        );
      }
    });
  }

  void _report(String message) {
    // Restoring providers can happen during a widget build.
    scheduleMicrotask(() {
      if (!_disposed) issue.value = message;
    });
  }

  void dismissIssue() => issue.value = null;

  void dispose() {
    _disposed = true;
    issue.dispose();
  }
}
