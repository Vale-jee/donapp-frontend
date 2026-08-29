import 'dart:async';

import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra loading inicial', (tester) async {
    final pending = Completer<DonationDetail>();
    await tester.pumpWidget(_app(_DetailService((_) => pending.future)));
    await tester.pump();
    expect(find.byKey(const Key('donationDetailLoading')), findsOneWidget);
    pending.complete(_detail());
  });

  testWidgets('muestra todos los campos reales del detalle', (tester) async {
    await tester.pumpWidget(_app(_DetailService((_) async => _detail())));
    await tester.pumpAndSettle();
    expect(find.text('Mesa auxiliar'), findsOneWidget);
    expect(find.text('Categoría: Muebles'), findsOneWidget);
    expect(find.text('Ciudad: Bogotá'), findsOneWidget);
    expect(find.text('Estado: Publicada'), findsOneWidget);
    expect(find.text('En buen estado.'), findsOneWidget);
    expect(find.textContaining('Publicada:'), findsOneWidget);
    expect(find.text('Solicitar'), findsNothing);
  });

  testWidgets('ordena y permite recorrer varias imágenes', (tester) async {
    await tester.pumpWidget(
      _app(
        _DetailService(
          (_) async => _detail(
            images: const [
              DonationImage(id: 2, referencia: 'invalid-two', orden: 2),
              DonationImage(id: 1, referencia: 'invalid-one', orden: 1),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('donationImageGallery')), findsOneWidget);
    expect(
      find.byKey(const Key('donationDetailImagePlaceholder')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const Key('donationImageGallery')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final caseData in const [
    (name: 'vertical', reference: 'https://images.test/vertical.jpg'),
    (name: 'horizontal', reference: 'https://images.test/horizontal.jpg'),
    (name: 'cuadrada', reference: 'https://images.test/square.jpg'),
  ]) {
    testWidgets('imagen ${caseData.name} se muestra completa sin deformarse', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _DetailService(
            (_) async => _detail(
              images: [
                DonationImage(id: 1, referencia: caseData.reference, orden: 1),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final imageFinder = find.byKey(const ValueKey('donationDetailImage-0'));
      expect(imageFinder, findsOneWidget);
      expect(tester.widget<Image>(imageFinder).fit, BoxFit.contain);
      expect(
        find.descendant(
          of: find.byKey(const Key('donationImageViewport')),
          matching: find.byType(AspectRatio),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('muestra 404 como no disponible y permite reintentar', (
    tester,
  ) async {
    var calls = 0;
    final service = _DetailService((_) async {
      calls++;
      if (calls == 1) {
        throw const ApiException(
          ApiErrorType.notFound,
          'No encontrada',
          statusCode: 404,
        );
      }
      return _detail();
    });
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('donationDetailNotFound')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Mesa auxiliar'), findsOneWidget);
  });

  testWidgets('muestra error recuperable', (tester) async {
    await tester.pumpWidget(
      _app(
        _DetailService(
          (_) async => throw const ApiException(
            ApiErrorType.network,
            'No pudimos conectarnos.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('donationDetailError')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('no desborda a 240 px con texto $scale×', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        _app(
          _DetailService((_) async => _detail()),
          mediaQuery: MediaQueryData(
            size: const Size(240, 640),
            textScaler: TextScaler.linear(scale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('En buen estado.'), 250);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(DonationService service, {MediaQueryData? mediaQuery}) {
  final screen = DonationDetailScreen(donationId: 4, donationService: service);
  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null
        ? screen
        : MediaQuery(data: mediaQuery, child: screen),
  );
}

class _DetailService extends DonationService {
  _DetailService(this.response);
  final Future<DonationDetail> Function(int id) response;
  @override
  Future<DonationDetail> getDonationById(int id) => response(id);
}

DonationDetail _detail({List<DonationImage> images = const []}) =>
    DonationDetail(
      id: 4,
      titulo: 'Mesa auxiliar',
      descripcion: 'En buen estado.',
      ciudad: 'Bogotá',
      estado: DonationStatus.publicada,
      createdAt: DateTime.utc(2026, 8, 20),
      updatedAt: DateTime.utc(2026, 8, 21),
      categoriaId: 4,
      categoriaNombre: 'Muebles',
      imagenes: images,
    );
