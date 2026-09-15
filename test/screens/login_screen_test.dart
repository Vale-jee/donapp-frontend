import 'package:donapp_mobile/repositories/session_repository.dart';
import 'package:donapp_mobile/repositories/profile_repository.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/repositories/auth_repository.dart';
import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dispose aborta perfil de login sin borrar tokens ni mostrar error',
    (tester) async {
      final transport = _AbortProfileClient();
      final storage = _FakeTokenStorage();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authRepository: AuthRepository.fromService(_FakeAuthService()),
            profileRepository: ProfileRepository.fromService(
              ProfileService(
                apiClient: ApiClient(
                  client: transport,
                  endpointBuilder: (path) =>
                      Uri.parse('https://donapp.test$path'),
                ),
              ),
            ),
            sessionRepository: SessionRepository.fromStorage(storage),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'ana@example.com',
      );
      await tester.enterText(find.byKey(const Key('passwordField')), 'secreto');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();
      expect(transport.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(transport.aborted, isTrue);
      expect(storage.clears, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('renderiza los elementos principales del login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('DonApp'), findsOneWidget);
    expect(
      find.text('Conecta lo que puedes donar con quienes lo necesitan.'),
      findsOneWidget,
    );
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('valida correo y contraseña obligatorios', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('El correo electrónico es obligatorio.'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
  });

  testWidgets('rechaza un correo con formato inválido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(find.byKey(const Key('emailField')), 'correo-mal');
    await tester.enterText(find.byKey(const Key('passwordField')), 'secreto');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
  });

  testWidgets('navega al Home cuando login y perfil son válidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authRepository: AuthRepository.fromService(_FakeAuthService()),
          profileRepository: ProfileRepository.fromService(
            _FakeProfileService(),
          ),
          sessionRepository: SessionRepository.fromStorage(_FakeTokenStorage()),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ana@example.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secreto');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, ana! 👋'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

class _FakeAuthService extends AuthService {
  @override
  Future<AuthSession> login(String email, String password) async {
    return const AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresIn: 2592000,
      usuario: AuthUser(
        id: 1,
        nombreVisible: 'ana',
        fotoPerfil: null,
        rol: AuthRole(codigo: 'USUARIO', nombre: 'Usuario'),
      ),
    );
  }
}

class _AbortProfileClient extends http.BaseClient {
  int calls = 0;
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    calls++;
    expect(request.url.path, '/api/usuarios/perfil');
    final abort = request as http.Abortable;
    return abort.abortTrigger!.then((_) {
      aborted = true;
      throw http.RequestAbortedException(request.url);
    });
  }
}

class _FakeProfileService extends ProfileService {
  @override
  Future<UserProfile> getProfile(String accessToken) async {
    return UserProfile(
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
  }
}

class _FakeTokenStorage extends TokenStorage {
  int clears = 0;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {
    clears++;
  }
}
