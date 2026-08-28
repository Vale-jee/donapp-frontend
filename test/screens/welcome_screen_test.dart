import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el contenido aprobado', (tester) async {
    await tester.pumpWidget(_app(const WelcomeScreen()));

    expect(find.text('DonApp'), findsOneWidget);
    expect(
      find.text('Conecta lo que puedes donar con quienes lo necesitan.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.byKey(const Key('donAppBrandingImage')), findsOneWidget);
    expect(find.byKey(const Key('donAppBrandingSlot')), findsNothing);
  });

  testWidgets('carga el asset oficial sin semántica duplicada', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const WelcomeScreen()));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(const Key('donAppBrandingImage')),
    );
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/donapp_icon.png',
    );
    expect(image.fit, BoxFit.contain);
    expect(image.excludeFromSemantics, isTrue);
    expect(find.bySemanticsLabel('DonApp'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Iniciar sesión abre Login y volver regresa a Bienvenida', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const WelcomeScreen()));

    await tester.tap(find.byKey(const Key('welcomeLoginButton')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Registrarse abre Registro y volver regresa a Bienvenida', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const WelcomeScreen()));

    await tester.tap(find.byKey(const Key('welcomeRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('registro exitoso abre Login con el correo prellenado', (
    tester,
  ) async {
    final service = _SuccessfulRegisterService();
    await tester.pumpWidget(_app(WelcomeScreen(authService: service)));

    await tester.tap(find.byKey(const Key('welcomeRegisterButton')));
    await tester.pumpAndSettle();
    await _fillValidRegistration(tester, email: ' ANA@EXAMPLE.COM ');
    await _tapRegister(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final emailField = tester.widget<TextFormField>(
      find.byKey(const Key('emailField')),
    );
    expect(emailField.controller?.text, 'ana@example.com');
    expect(service.registerCalls, 1);
  });

  testWidgets('no desborda con ancho pequeño y fuente ampliada', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(240, 400),
            textScaler: TextScaler.linear(2),
          ),
          child: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('no desborda en ancho normal con texto ampliado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            textScaler: TextScaler.linear(2),
          ),
          child: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('los dos accesos tienen semántica de botón y etiqueta', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const WelcomeScreen()));

    expect(find.bySemanticsLabel('Iniciar sesión'), findsOneWidget);
    expect(find.bySemanticsLabel('Registrarse'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

Future<void> _fillValidRegistration(
  WidgetTester tester, {
  required String email,
}) async {
  await tester.enterText(
    find.byKey(const Key('registerFullNameField')),
    'Ana Prueba',
  );
  await tester.enterText(
    find.byKey(const Key('registerUsernameField')),
    'ana.prueba',
  );
  await tester.enterText(find.byKey(const Key('registerEmailField')), email);
  await tester.enterText(find.byKey(const Key('registerCityField')), 'Bogotá');
  await tester.enterText(
    find.byKey(const Key('registerPasswordField')),
    'Clave1234',
  );
  await tester.enterText(
    find.byKey(const Key('registerConfirmPasswordField')),
    'Clave1234',
  );
}

Future<void> _tapRegister(WidgetTester tester) async {
  final button = find.byKey(const Key('registerButton'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

class _SuccessfulRegisterService extends AuthService {
  int registerCalls = 0;

  @override
  Future<void> register({
    required String nombreCompleto,
    required String nombreVisible,
    required String email,
    required String password,
    required String ciudad,
  }) async {
    registerCalls++;
  }

  @override
  Future<AuthSession> login(String email, String password) {
    throw UnimplementedError();
  }
}
