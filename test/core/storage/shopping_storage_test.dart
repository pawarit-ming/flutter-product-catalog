import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/core/storage/shopping_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Device storage whose reads of [failingKey] throw while [failReads] is set.
final class _FlakyPreferences extends InMemorySharedPreferencesAsync {
  _FlakyPreferences(super.data, this.failingKey) : super.withData();

  final String failingKey;
  bool failReads = true;

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failReads && key == failingKey) throw StateError('read failed');
    return super.getString(key, options);
  }
}

void main() {
  test('a key that could not be read is never overwritten', () async {
    final device = _FlakyPreferences({
      cartStorageKey: '[{"saved":true}]',
    }, cartStorageKey);
    SharedPreferencesAsyncPlatform.instance = device;

    final storage = await ShoppingStorage.open();
    expect(storage.issue.value, isNotNull);

    storage.writeList(cartStorageKey, const []);
    storage.writeList(wishlistStorageKey, const [1]);
    await pumpEventQueue();

    device.failReads = false;
    const options = SharedPreferencesOptions();
    expect(await device.getString(cartStorageKey, options), '[{"saved":true}]');
    // Readable keys are still saved as usual.
    expect(await device.getString(wishlistStorageKey, options), '[1]');
    storage.dispose();
  });
}
