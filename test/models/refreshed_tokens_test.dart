import 'package:donapp_mobile/models/refreshed_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea la respuesta real de renovación', () {
    final tokens = RefreshedTokens.fromJson({
      'accessToken': 'new-access',
      'refreshToken': 'new-refresh',
      'accessTokenExpiresIn': 900,
      'refreshTokenExpiresIn': 604800,
    });

    expect(tokens.accessToken, 'new-access');
    expect(tokens.refreshToken, 'new-refresh');
    expect(tokens.accessTokenExpiresIn, 900);
    expect(tokens.refreshTokenExpiresIn, 604800);
  });

  test('rechaza una respuesta de renovación incompleta', () {
    expect(
      () => RefreshedTokens.fromJson({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
        'accessTokenExpiresIn': 900,
      }),
      throwsFormatException,
    );
  });
}
