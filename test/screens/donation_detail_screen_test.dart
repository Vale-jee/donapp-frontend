import 'dart:async';

import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  testWidgets('muestra acción solo con permiso explícito', (tester) async {
    await tester.pumpWidget(
      _app(_DetailService((_) async => _detail(canRequest: true))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solicitar donación'), findsOneWidget);
  });

  testWidgets('confirma y cancelar no ejecuta POST', (tester) async {
    final requests = _RequestService();
    await tester.pumpWidget(
      _app(
        _DetailService((_) async => _detail(canRequest: true)),
        requestService: requests,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitar donación'), 300);
    await tester.tap(find.text('Solicitar donación'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quieres enviar una solicitud para “Mesa auxiliar”?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(requests.calls, 0);
  });

  testWidgets('éxito bloquea doble envío, oculta botón y muestra feedback', (
    tester,
  ) async {
    final pending = Completer<CreatedRequest>();
    final requests = _RequestService(response: (_) => pending.future);
    await tester.pumpWidget(
      _app(
        _DetailService((_) async => _detail(canRequest: true)),
        requestService: requests,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitar donación'), 300);
    await tester.tap(find.text('Solicitar donación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pump();
    expect(find.text('Enviando solicitud…'), findsOneWidget);
    expect(requests.calls, 1);
    pending.complete(_createdRequest());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('requestDonationButton')), findsNothing);
    expect(find.text('Solicitud enviada correctamente.'), findsOneWidget);
    expect(find.text('Ver solicitudes'), findsOneWidget);
  });

  testWidgets('Ver solicitudes navega a enviadas', (tester) async {
    final details = _DetailService((_) async => _detail(canRequest: true));
    final requests = _RequestService();
    final router = GoRouter(
      initialLocation: '/donaciones/4',
      routes: [
        GoRoute(
          path: '/donaciones/:id',
          builder: (_, _) => DonationDetailScreen(
            donationId: 4,
            donationService: details,
            requestService: requests,
          ),
        ),
        GoRoute(
          path: '/solicitudes/enviadas',
          builder: (_, _) => const Scaffold(body: Text('Solicitudes enviadas')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitar donación'), 300);
    await tester.tap(find.text('Solicitar donación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver solicitudes'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitudes enviadas'), findsOneWidget);
  });

  testWidgets('409 muestra mensaje y vuelve a consultar permiso', (tester) async {
    var detailCalls = 0;
    final details = _DetailService((_) async {
      detailCalls++;
      return _detail(canRequest: detailCalls == 1);
    });
    final requests = _RequestService(
      response: (_) async => throw const ApiException(
        ApiErrorType.conflict,
        'Ya existe una solicitud activa para esta donación.',
        statusCode: 409,
      ),
    );
    await tester.pumpWidget(_app(details, requestService: requests));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitar donación'), 300);
    await tester.tap(find.text('Solicitar donación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(detailCalls, 2);
    expect(find.textContaining('Ya existe una solicitud activa'), findsOneWidget);
    expect(find.byKey(const Key('requestDonationButton')), findsNothing);
  });

  testWidgets('404 recarga y muestra no disponible', (tester) async {
    var detailCalls = 0;
    final details = _DetailService((_) async {
      if (detailCalls++ == 0) return _detail(canRequest: true);
      throw const ApiException(
        ApiErrorType.notFound,
        'No encontrada',
        statusCode: 404,
      );
    });
    final requests = _RequestService(
      response: (_) async => throw const ApiException(
        ApiErrorType.notFound,
        'No encontramos la información solicitada.',
        statusCode: 404,
      ),
    );
    await tester.pumpWidget(_app(details, requestService: requests));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitar donación'), 300);
    await tester.tap(find.text('Solicitar donación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('donationDetailNotFound')), findsOneWidget);
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
          _DetailService((_) async => _detail(canRequest: true)),
          mediaQuery: MediaQueryData(
            size: const Size(240, 640),
            textScaler: TextScaler.linear(scale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('En buen estado.'), 250);
      await tester.scrollUntilVisible(find.text('Solicitar donación'), 250);
      if (scale == 2.0) {
        await tester.tap(find.text('Solicitar donación'));
        await tester.pumpAndSettle();
        expect(find.text('Enviar solicitud'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(
  DonationService service, {
  MediaQueryData? mediaQuery,
  RequestService? requestService,
}) {
  final screen = DonationDetailScreen(
    donationId: 4,
    donationService: service,
    requestService: requestService,
  );
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

class _RequestService extends RequestService {
  _RequestService({this.response});
  final Future<CreatedRequest> Function(int id)? response;
  int calls = 0;

  @override
  Future<CreatedRequest> createRequest(int donationId) {
    calls++;
    return response?.call(donationId) ?? Future.value(_createdRequest());
  }
}

CreatedRequest _createdRequest() => CreatedRequest(
  id: 7,
  status: RequestStatus.pendiente,
  donation: const RequestDonationSummary(
    id: 4,
    title: 'Mesa auxiliar',
    status: RequestDonationStatus.publicada,
    mainImage: null,
  ),
);

DonationDetail _detail({
  List<DonationImage> images = const [],
  bool canRequest = false,
}) =>
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
      puedeSolicitar: canRequest,
    );
