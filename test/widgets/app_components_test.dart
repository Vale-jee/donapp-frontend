import 'dart:convert';
import 'dart:typed_data';

import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:donapp_mobile/widgets/app_bottom_navigation_bar.dart';
import 'package:donapp_mobile/widgets/app_content_state.dart';
import 'package:donapp_mobile/widgets/app_primary_button.dart';
import 'package:donapp_mobile/widgets/app_text_field.dart';
import 'package:donapp_mobile/widgets/donation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTextField muestra etiqueta y error de validación', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _themedApp(
        Form(
          child: AppTextField(
            label: 'Título',
            controller: controller,
            validator: (value) => value == null || value.isEmpty
                ? 'El título es obligatorio.'
                : null,
          ),
        ),
      ),
    );

    expect(find.text('Título'), findsOneWidget);
    final form = tester.state<FormState>(find.byType(Form));
    form.validate();
    await tester.pump();
    expect(find.text('El título es obligatorio.'), findsOneWidget);
  });

  testWidgets('AppPrimaryButton bloquea interacción mientras carga', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _themedApp(
        AppPrimaryButton(
          text: 'Guardar',
          onPressed: () => presses++,
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppPrimaryButton));
    expect(presses, 0);
  });

  testWidgets('AppContentState permite ejecutar una acción de error', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      _themedApp(
        AppContentState(
          type: AppContentStateType.error,
          title: 'No pudimos cargar las donaciones',
          message: 'Verifica tu conexión e intenta nuevamente.',
          actionText: 'Reintentar',
          onAction: () => retried = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('DonationCard presenta datos y delega la pulsación', (
    tester,
  ) async {
    var tapped = false;
    final image = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(
      _themedApp(
        SizedBox(
          width: 360,
          child: DonationCard(
            image: image,
            title: 'Bicicleta infantil',
            category: 'Deportes',
            location: 'Bogotá',
            status: 'Publicada',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Bicicleta infantil'), findsOneWidget);
    expect(find.text('Publicada'), findsOneWidget);
    await tester.tap(find.byType(DonationCard));
    expect(tapped, isTrue);
  });

  testWidgets('DonationCard usa placeholder cuando falla la imagen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themedApp(
        SizedBox(
          width: 360,
          child: DonationCard(
            image: MemoryImage(Uint8List.fromList(const [0, 1, 2, 3])),
            title: 'Mesa',
            category: 'Muebles',
            location: 'Bogotá',
            status: 'Publicada',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('donationImagePlaceholder')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AppBottomNavigationBar conserva cinco destinos y delega índice',
    (tester) async {
      int? selectedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: 0,
              onDestinationSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.text('Mensajes'));
      expect(selectedIndex, 3);
    },
  );
}

Widget _themedApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}
