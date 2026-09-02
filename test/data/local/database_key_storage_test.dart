import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/database_key_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'genera una clave de 32 bytes y reutiliza únicamente esa clave',
    () async {
      final storage = DatabaseKeyStorage();
      final first = await storage.getOrCreateKey();
      final second = await storage.getOrCreateKey();

      expect(first, hasLength(32));
      expect(second, orderedEquals(first));
      expect(
        const FlutterSecureStorage().read(key: DatabaseKeyStorage.storageKey),
        completion(isNotEmpty),
      );
      expect(
        const FlutterSecureStorage().read(key: 'donapp_access_token'),
        completion(isNull),
      );
      expect(
        const FlutterSecureStorage().read(key: 'donapp_refresh_token'),
        completion(isNull),
      );
    },
  );
}
