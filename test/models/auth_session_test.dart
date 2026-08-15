import 'package:donapp_mobile/models/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea una sesión de autenticación real', () {
    final session = AuthSession.fromJson({
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'accessTokenExpiresIn': 900,
      'refreshTokenExpiresIn': 2592000,
      'usuario': {
        'id': 7,
        'nombreVisible': 'ana',
        'fotoPerfil': null,
        'rol': {'codigo': 'USUARIO', 'nombre': 'Usuario'},
      },
    });

    expect(session.accessToken, 'access-token');
    expect(session.usuario.id, 7);
    expect(session.usuario.rol.codigo, 'USUARIO');
  });

  test('rechaza una sesión con tipos incorrectos', () {
    expect(
      () => AuthSession.fromJson({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'accessTokenExpiresIn': '900',
        'refreshTokenExpiresIn': 2592000,
        'usuario': <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });
}
