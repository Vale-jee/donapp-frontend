import 'package:donapp_mobile/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea el perfil real del usuario', () {
    final profile = UserProfile.fromJson({
      'id': 7,
      'nombreCompleto': 'Ana Pérez',
      'nombreVisible': 'ana',
      'email': 'ana@example.com',
      'ciudad': 'Bogotá',
      'telefono': null,
      'fotoPerfil': null,
      'activo': true,
      'createdAt': '2026-08-15T12:00:00.000Z',
      'updatedAt': '2026-08-15T13:00:00.000Z',
      'rol': {'codigo': 'USUARIO', 'nombre': 'Usuario'},
    });

    expect(profile.nombreCompleto, 'Ana Pérez');
    expect(profile.ciudad, 'Bogotá');
    expect(profile.createdAt.isUtc, isTrue);
  });

  test('rechaza una fecha de perfil inválida', () {
    expect(
      () => UserProfile.fromJson({
        'id': 7,
        'nombreCompleto': 'Ana Pérez',
        'nombreVisible': 'ana',
        'email': 'ana@example.com',
        'ciudad': 'Bogotá',
        'telefono': null,
        'fotoPerfil': null,
        'activo': true,
        'createdAt': 'fecha-inválida',
        'updatedAt': '2026-08-15T13:00:00.000Z',
        'rol': {'codigo': 'USUARIO', 'nombre': 'Usuario'},
      }),
      throwsFormatException,
    );
  });
}
