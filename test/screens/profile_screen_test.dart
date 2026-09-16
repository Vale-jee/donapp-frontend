import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/repositories/profile_repository.dart';
import 'package:donapp_mobile/screens/profile_screen.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('carga y actualiza el perfil autenticado', (tester) async {
    final service = _FakeProfileService(_profile);
    final repository = ProfileRepository.fromService(service);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileScreen(
          profile: _profile,
          profileRepository: repository,
        ),
      ),
    );
    expect(find.text('Cargando perfil'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Información personal'), findsOneWidget);
    expect(find.text('Nombre completo'), findsNWidgets(2));
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsNWidgets(2));
    expect(find.text('El correo no se puede editar aquí.'), findsOneWidget);
    expect(find.byKey(const Key('profileCurrentPassword')), findsNothing);
    expect(find.text('Foto de perfil (URL o ruta)'), findsNothing);
    expect(service.getCount, 1);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Ana Pérez actualizada',
    );
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(service.updateCount, 1);
    expect(service.lastChanges, {'nombreCompleto': 'Ana Pérez actualizada'});
    expect(find.text('Perfil actualizado correctamente.'), findsOneWidget);
    expect(find.text('Información personal'), findsOneWidget);
  });

  testWidgets('el correo es de solo lectura y no muestra contraseña', (
    tester,
  ) async {
    final service = _FakeProfileService(_profile);
    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    final emailField = find.byKey(const Key('profileEmailField'));
    expect(tester.widget<TextFormField>(emailField).enabled, isFalse);
    expect(
      tester.widget<TextFormField>(emailField).controller?.text,
      _profile.email,
    );
    expect(find.byKey(const Key('profileCurrentPassword')), findsNothing);
    expect(service.updateCount, 0);
  });

  testWidgets('Cambiar contraseña muestra una acción controlada', (
    tester,
  ) async {
    final service = _FakeProfileService(_profile);
    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    final changePasswordButton = find.byKey(const Key('changePasswordButton'));
    await tester.ensureVisible(changePasswordButton);
    await tester.tap(changePasswordButton);
    await tester.pumpAndSettle();

    expect(
      find.text('El cambio de contraseña estará disponible próximamente.'),
      findsOneWidget,
    );
  });

  testWidgets('cambiar teléfono no envía email', (tester) async {
    final service = _FakeProfileService(_profile);
    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(4), '0981618712');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(service.lastChanges, {'telefono': '0981618712'});
  });

  testWidgets('cambiar nombre visible no envía email', (tester) async {
    final service = _FakeProfileService(_profile);
    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Vale');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(service.lastChanges, {'nombreVisible': 'vale'});
  });

  testWidgets('sin cambios no genera PATCH', (tester) async {
    final service = _FakeProfileService(_profile);
    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(service.updateCount, 0);
    expect(find.text('No hay cambios para guardar.'), findsOneWidget);
  });
}

Widget _profileApp(_FakeProfileService service) => MaterialApp(
  theme: AppTheme.light,
  home: ProfileScreen(
    profile: _profile,
    profileRepository: ProfileRepository.fromService(service),
  ),
);

final _profile = UserProfile(
  id: 1,
  nombreCompleto: 'Ana Pérez',
  nombreVisible: 'ana',
  email: 'ana@example.com',
  ciudad: 'Bogotá',
  telefono: null,
  fotoPerfil: null,
  activo: true,
  createdAt: DateTime.utc(2026, 8, 15),
  updatedAt: DateTime.utc(2026, 8, 15),
  rol: const ProfileRole(codigo: 'USUARIO', nombre: 'Usuario'),
);

class _FakeProfileService extends ProfileService {
  _FakeProfileService(this.profile);

  UserProfile profile;
  int getCount = 0;
  int updateCount = 0;
  Map<String, dynamic>? lastChanges;

  @override
  Future<UserProfile> getAuthenticatedProfile() async {
    getCount++;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required Map<String, dynamic> changes,
  }) async {
    updateCount++;
    lastChanges = Map.of(changes);
    profile = UserProfile(
      id: profile.id,
      nombreCompleto: changes['nombreCompleto'] as String? ?? profile.nombreCompleto,
      nombreVisible: changes['nombreVisible'] as String? ?? profile.nombreVisible,
      email: changes['email'] as String? ?? profile.email,
      ciudad: changes['ciudad'] as String? ?? profile.ciudad,
      telefono: changes.containsKey('telefono')
          ? changes['telefono'] as String?
          : profile.telefono,
      fotoPerfil: profile.fotoPerfil,
      activo: profile.activo,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      rol: profile.rol,
    );
    return profile;
  }
}
