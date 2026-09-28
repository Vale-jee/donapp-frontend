import 'dart:ui' as ui;

import 'package:donapp_mobile/config/api_config.dart';
import 'package:donapp_mobile/main.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/services/donation_gallery_picker.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/widgets/donation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';

// Real app, real REST, real secure storage, real outbox and image upload.
// Only the OS image selector is replaced with a deterministic non-personal PNG.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'E2E: iniciar sesión, guardar una donación y verla publicada en Mis donaciones',
    (tester) async {
      const email = String.fromEnvironment('E2E_EMAIL');
      const password = String.fromEnvironment('E2E_PASSWORD');
      const category = String.fromEnvironment(
        'E2E_CATEGORY',
        defaultValue: 'Muebles',
      );
      if (ApiConfig.environment != 'test' ||
          !const bool.fromEnvironment('E2E_ALLOW_WRITES') ||
          email.isEmpty ||
          password.isEmpty) {
        fail(
          'Configure APP_ENV=test, E2E_ALLOW_WRITES=true, E2E_EMAIL y E2E_PASSWORD en un entorno desechable.',
        );
      }
      ApiConfig.endpoint('/api/donaciones');
      if (await TokenStorage().readAccessToken() != null) {
        fail(
          'Use una instalación de pruebas sin sesión previa. No se borran datos automáticamente.',
        );
      }
      final title = 'P15 E2E ${DateTime.now().microsecondsSinceEpoch}';
      const description =
          'Artículo sintético para validar la publicación del Prototipo 15.';
      final picker = _PreparedImagePicker(await _preparedImage());
      await tester.pumpWidget(DonApp(galleryPicker: picker));
      await _waitFor(tester, find.byKey(const Key('welcomeLoginButton')));
      await tester.tap(find.byKey(const Key('welcomeLoginButton')));
      await _waitFor(tester, find.byKey(const Key('emailField')));
      await tester.enterText(find.byKey(const Key('emailField')), email);
      await tester.enterText(find.byKey(const Key('passwordField')), password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(find.byKey(const Key('loginButton')));
      await _waitFor(tester, find.byKey(const Key('homeDonateAction')));
      await tester.tap(find.byKey(const Key('homeDonateAction')));
      await _waitFor(tester, find.byKey(const Key('donationTitleField')));
      await tester.enterText(
        find.byKey(const Key('donationTitleField')),
        title,
      );
      await tester.enterText(
        find.byKey(const Key('donationDescriptionField')),
        description,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final categoryField = find.byKey(const Key('donationCategoryField'));
      final dropdown = tester.widget<DropdownButton<int>>(
        find.descendant(
          of: categoryField,
          matching: find.byType(DropdownButton<int>),
        ),
      );
      // Each item uses the screen's category option widget, with its public name.
      final matchingItems = dropdown.items!
          .where((item) => (item.child as dynamic).name == category)
          .toList();
      expect(
        matchingItems,
        hasLength(1),
        reason:
            'El catálogo del selector debe incluir la categoría "$category".',
      );
      final expectedCategoryId = matchingItems.single.value;
      await tester.ensureVisible(categoryField);
      await tester.tap(categoryField);
      final menu = find.byType(ListView);
      await _waitFor(tester, menu);
      expect(
        menu,
        findsOneWidget,
        reason: 'Debe abrirse la lista del Dropdown.',
      );
      final menuScrollable = find.descendant(
        of: menu,
        matching: find.byType(Scrollable),
      );
      expect(menuScrollable, findsOneWidget);
      final option = find.descendant(of: menu, matching: find.text(category));
      const maxCategoryScrolls = 20;
      for (
        var attempt = 0;
        attempt < maxCategoryScrolls && option.hitTestable().evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(menuScrollable, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(
        option.hitTestable(),
        findsOneWidget,
        reason:
            'No apareció "$category" en el menú tras $maxCategoryScrolls desplazamientos.',
      );
      await tester.tap(option.hitTestable());
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.state<FormFieldState<int>>(categoryField).value,
        expectedCategoryId,
      );
      final gallery = find.byKey(const Key('pickDonationImagesButton'));
      await tester.ensureVisible(gallery);
      await tester.tap(gallery);
      await _waitFor(tester, find.text('Galería (1/5)'));
      final publish = find.byKey(const Key('publishDonationButton'));
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await _waitFor(tester, find.byKey(const Key('homeMyDonationsAction')));
      await tester.tap(find.byKey(const Key('homeMyDonationsAction')));
      await _waitFor(tester, find.byKey(const Key('myDonationsList')));

      final card = find.byWidgetPredicate(
        (widget) => widget is DonationCard && widget.title == title,
      );
      final elapsed = Stopwatch()..start();
      while (card.evaluate().isEmpty &&
          elapsed.elapsed < const Duration(minutes: 3)) {
        await tester.pump(const Duration(seconds: 2));
        if (find.byType(RefreshIndicator).evaluate().isNotEmpty) {
          var completed = false;
          final refresh = tester.state<RefreshIndicatorState>(
            find.byType(RefreshIndicator),
          );
          final refreshing = refresh.show().whenComplete(
            () => completed = true,
          );
          final refreshWatch = Stopwatch()..start();
          while (!completed &&
              refreshWatch.elapsed < const Duration(seconds: 55)) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          expect(
            completed,
            isTrue,
            reason: 'La actualización de Mis donaciones no terminó.',
          );
          await refreshing;
        }
      }
      expect(
        card,
        findsOneWidget,
        reason:
            'Guardar localmente no basta: falta confirmación remota visible.',
      );
      final published = tester.widget<DonationCard>(card);
      expect(published.status, 'Publicada');
      expect(published.category, category);
      expect(published.image, isNotNull);
      expect(published.subtitle, '1 imagen');
      await tester.ensureVisible(card);
      await tester.tap(card);
      await _waitFor(tester, find.byKey(const Key('donationDetailScroll')));
      expect(find.byType(DonationDetailScreen), findsOneWidget);
      expect(find.text(title), findsWidgets);
      expect(find.text(description), findsOneWidget);
      expect(find.text('Estado: Publicada'), findsOneWidget);
      expect(find.byKey(const Key('donationImageGallery')), findsOneWidget);
      expect(tester.takeException(), isNull);
      binding.reportData = {
        'case': 'P15-E2E',
        'result': 'published',
        'testDonationTitle': title,
      };
      // Keep remote fixture and local state for inspection; cleanup is documented.
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final elapsed = Stopwatch()..start();
  while (finder.evaluate().isEmpty &&
      elapsed.elapsed < const Duration(seconds: 55)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(
    finder,
    findsWidgets,
    reason: 'No apareció el estado esperado en 55 segundos.',
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<XFile> _preparedImage() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 64, 64),
    Paint()..color = const Color(0xFF26734D),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return XFile.fromData(
    bytes!.buffer.asUint8List(),
    name: 'p15-fixture.png',
    mimeType: 'image/png',
  );
}

class _PreparedImagePicker implements DonationGalleryPicker {
  _PreparedImagePicker(this.image);
  final XFile image;
  @override
  Future<List<XFile>> pickImages() async => [image];
  @override
  Future<List<XFile>> retrieveLostImages() async => const [];
}
