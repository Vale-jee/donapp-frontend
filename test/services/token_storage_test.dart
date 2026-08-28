import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('guarda y lee conjuntamente ambos tokens', () async {
    final storage = TokenStorage();
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    final tokens = await storage.readTokens();
    expect(tokens?.accessToken, 'access-token');
    expect(tokens?.refreshToken, 'refresh-token');
  });

  test(
    'lectura conjunta devuelve null si el almacenamiento está parcial',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'donapp_access_token': 'access-token',
      });

      expect(await TokenStorage().readTokens(), isNull);
    },
  );

  test('borra ambos tokens', () async {
    final storage = TokenStorage();
    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    await storage.clearTokens();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });
}
