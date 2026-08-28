import 'dart:async';

import 'package:donapp_mobile/main.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/session_gate.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra loading inicial y no anticipa Home', (tester) async {
    final pending = Completer<SessionRestoreResult>();
    final coordinator = _FakeSessionCoordinator([pending.future]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));

    expect(find.byKey(const Key('sessionLoading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('sesión válida muestra Home con el perfil real', (tester) async {
    final coordinator = _FakeSessionCoordinator([
      Future.value(SessionRestoreResult.valid(_profile)),
    ]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('¡Hola, ana! 👋'), findsOneWidget);
  });

  testWidgets('sin sesión muestra el acceso transitorio', (tester) async {
    final coordinator = _FakeSessionCoordinator([
      Future.value(const SessionRestoreResult.noSession()),
    ]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('sesión inválida muestra el acceso transitorio', (tester) async {
    final coordinator = _FakeSessionCoordinator([
      Future.value(const SessionRestoreResult.invalid()),
    ]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('error recuperable muestra mensaje y Reintentar', (tester) async {
    const message = 'No pudimos conectarnos. Verifica tu conexión.';
    final coordinator = _FakeSessionCoordinator([
      Future.value(const SessionRestoreResult.recoverableError(message)),
    ]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sessionError')), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reintentar'), findsOneWidget);
  });

  testWidgets('Reintentar ejecuta una nueva restauración', (tester) async {
    final retry = Completer<SessionRestoreResult>();
    final coordinator = _FakeSessionCoordinator([
      Future.value(
        const SessionRestoreResult.recoverableError('Sin conexión.'),
      ),
      retry.future,
    ]);

    await tester.pumpWidget(_app(SessionGate(coordinator: coordinator)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(coordinator.restoreCount, 2);
    expect(find.byKey(const Key('sessionLoading')), findsOneWidget);

    retry.complete(SessionRestoreResult.valid(_profile));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('un rebuild no duplica la restauración', (tester) async {
    final pending = Completer<SessionRestoreResult>();
    final coordinator = _FakeSessionCoordinator([pending.future]);
    final gate = SessionGate(coordinator: coordinator);

    await tester.pumpWidget(_app(gate));
    await tester.pumpWidget(_app(gate));
    await tester.pump();

    expect(coordinator.restoreCount, 1);
  });

  testWidgets('DonApp inicia en SessionGate', (tester) async {
    final pending = Completer<SessionRestoreResult>();
    final coordinator = _FakeSessionCoordinator([pending.future]);

    await tester.pumpWidget(DonApp(sessionCoordinator: coordinator));

    expect(find.byType(SessionGate), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

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

class _FakeSessionCoordinator extends SessionCoordinator {
  _FakeSessionCoordinator(this.results);

  final List<Future<SessionRestoreResult>> results;
  int restoreCount = 0;

  @override
  Future<SessionRestoreResult> restoreSession() {
    final index = restoreCount++;
    return results[index];
  }
}
