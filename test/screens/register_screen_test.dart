import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza los campos principales del registro', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.text('DonApp'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Ciudad'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
  });

  testWidgets('valida todos los campos obligatorios', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _tapRegister(tester);

    expect(find.text('El nombre completo es obligatorio.'), findsOneWidget);
    expect(find.text('El nombre de usuario es obligatorio.'), findsOneWidget);
    expect(find.text('El correo electrónico es obligatorio.'), findsOneWidget);
    expect(find.text('La ciudad es obligatoria.'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
    expect(find.text('Confirma la contraseña.'), findsOneWidget);
  });

  testWidgets('rechaza correo inválido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _fillValidForm(tester, email: 'correo-mal');
    await _tapRegister(tester);
    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
  });

  testWidgets('rechaza nombre de usuario con espacios', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _fillValidForm(tester, username: 'ana prueba');
    await _tapRegister(tester);
    expect(
      find.text('Usa solo letras, números, punto y guion bajo.'),
      findsOneWidget,
    );
  });

  testWidgets('rechaza contraseña menor a ocho caracteres', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _fillValidForm(tester, password: 'Abc123', confirmation: 'Abc123');
    await _tapRegister(tester);
    expect(find.text('Debe tener al menos 8 caracteres.'), findsOneWidget);
  });

  testWidgets('rechaza contraseña sin número', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _fillValidForm(
      tester,
      password: 'SoloLetras',
      confirmation: 'SoloLetras',
    );
    await _tapRegister(tester);
    expect(find.text('Debe incluir al menos un número.'), findsOneWidget);
  });

  testWidgets('rechaza confirmación diferente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await _fillValidForm(tester, confirmation: 'OtraClave2');
    await _tapRegister(tester);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('registro exitoso vuelve al Login y prellena el correo', (
    tester,
  ) async {
    final service = _SuccessfulRegisterService();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authService: service)),
    );
    await tester.tap(find.byKey(const Key('openRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await _fillValidForm(tester, email: ' ANA@EXAMPLE.COM ');
    await _tapRegister(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Cuenta creada correctamente. Ahora puedes iniciar sesión.'),
      findsOneWidget,
    );
    final emailField = tester.widget<TextFormField>(
      find.byKey(const Key('emailField')),
    );
    expect(emailField.controller?.text, 'ana@example.com');
    expect(service.registerCalls, 1);
    expect(service.passwordReceived, 'Clave1234');
  });
}

Future<void> _fillValidForm(
  WidgetTester tester, {
  String username = 'ana.prueba',
  String email = 'ana@example.com',
  String password = 'Clave1234',
  String confirmation = 'Clave1234',
}) async {
  await tester.enterText(
    find.byKey(const Key('registerFullNameField')),
    'Ana Prueba',
  );
  await tester.enterText(
    find.byKey(const Key('registerUsernameField')),
    username,
  );
  await tester.enterText(find.byKey(const Key('registerEmailField')), email);
  await tester.enterText(find.byKey(const Key('registerCityField')), 'Bogotá');
  await tester.enterText(
    find.byKey(const Key('registerPasswordField')),
    password,
  );
  await tester.enterText(
    find.byKey(const Key('registerConfirmPasswordField')),
    confirmation,
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
  String? passwordReceived;

  @override
  Future<void> register({
    required String nombreCompleto,
    required String nombreVisible,
    required String email,
    required String password,
    required String ciudad,
  }) async {
    registerCalls++;
    passwordReceived = password;
  }

  @override
  Future<AuthSession> login(String email, String password) {
    throw UnimplementedError();
  }
}
