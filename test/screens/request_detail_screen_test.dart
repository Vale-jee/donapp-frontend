import 'dart:async';

import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/screens/request_detail_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading y 404 controlado', (tester) async {
    final pending = Completer<RequestDetail>();
    await tester.pumpWidget(_app(_DetailService(load: (_) => pending.future)));
    expect(find.byKey(const Key('requestDetailLoading')), findsOneWidget);
    pending.completeError(
      const ApiException(ApiErrorType.notFound, 'No visible', statusCode: 404),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('requestDetailNotFound')), findsOneWidget);
  });

  testWidgets('propietario pendiente ve aceptar y rechazar', (tester) async {
    await tester.pumpWidget(
      _app(_DetailService(load: (_) async => _detail(RequestActor.owner))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('acceptRequestButton')), findsOneWidget);
    expect(find.byKey(const Key('rejectRequestButton')), findsOneWidget);
    expect(find.byKey(const Key('cancelRequestButton')), findsNothing);
    expect(
      find.byKey(const Key('requestDetailImagePlaceholder')),
      findsOneWidget,
    );
  });

  testWidgets('solicitante pendiente ve cancelar', (tester) async {
    await tester.pumpWidget(
      _app(_DetailService(load: (_) async => _detail(RequestActor.applicant))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);
    expect(find.byKey(const Key('acceptRequestButton')), findsNothing);
  });

  testWidgets('aceptar bloquea doble toque, usa respuesta y muestra feedback', (
    tester,
  ) async {
    final pending = Completer<RequestDetail>();
    final service = _DetailService(
      load: (_) async => _detail(RequestActor.owner),
      accept: (_) => pending.future,
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('acceptRequestButton')));
    await tester.tap(find.byKey(const Key('acceptRequestButton')));
    await tester.pump();
    expect(service.acceptCalls, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('acceptRequestButton')))
          .onPressed,
      isNull,
    );
    pending.complete(
      _detail(
        RequestActor.owner,
        status: RequestStatus.aceptada,
        donationStatus: RequestDonationStatus.reservada,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solicitud aceptada.'), findsOneWidget);
    expect(find.byKey(const Key('acceptRequestButton')), findsNothing);
  });

  testWidgets('error de acción conserva datos', (tester) async {
    final service = _DetailService(
      load: (_) async => _detail(RequestActor.applicant),
      cancel: (_) async => throw const ApiException(
        ApiErrorType.conflict,
        'Ya cambió',
        statusCode: 409,
      ),
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('cancelRequestButton')));
    await tester.tap(find.byKey(const Key('cancelRequestButton')));
    await tester.pumpAndSettle();
    expect(find.text('Ya cambió'), findsOneWidget);
    expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);
  });

  testWidgets('estado final no muestra acciones', (tester) async {
    await tester.pumpWidget(
      _app(
        _DetailService(
          load: (_) async =>
              _detail(RequestActor.owner, status: RequestStatus.rechazada),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byKey(const Key('rejectRequestButton')), findsNothing);
  });

  testWidgets('sin overflow a 240 px con texto 2x', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(240, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(240, 800),
          textScaler: TextScaler.linear(2),
        ),
        child: _app(
          _DetailService(load: (_) async => _detail(RequestActor.owner)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _app(RequestService service) => MaterialApp(
  theme: AppTheme.light,
  home: RequestDetailScreen(requestId: 7, requestService: service),
);

class _DetailService extends RequestService {
  _DetailService({required this.load, this.accept, this.cancel});
  final Future<RequestDetail> Function(int) load;
  final Future<RequestDetail> Function(int)? accept;
  final Future<RequestDetail> Function(int)? cancel;
  int acceptCalls = 0;
  @override
  Future<RequestDetail> getRequestById(int id) => load(id);
  @override
  Future<RequestDetail> acceptRequest(int id) {
    acceptCalls++;
    return accept!(id);
  }

  @override
  Future<RequestDetail> cancelRequest(int id) => cancel!(id);
}

RequestDetail _detail(
  RequestActor actor, {
  RequestStatus status = RequestStatus.pendiente,
  RequestDonationStatus donationStatus = RequestDonationStatus.publicada,
}) => RequestDetail(
  id: 7,
  status: status,
  cancellationCause: null,
  acceptedAt: status == RequestStatus.aceptada
      ? DateTime.utc(2026, 8, 21)
      : null,
  rejectedAt: status == RequestStatus.rechazada
      ? DateTime.utc(2026, 8, 21)
      : null,
  cancelledAt: null,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
  donation: RequestDonationSummary(
    id: 4,
    title: 'Bicicleta',
    status: donationStatus,
    mainImage: null,
  ),
  actor: actor,
  otherUser: const RequestUserSummary(
    id: 2,
    visibleName: 'ana',
    profilePhoto: null,
    city: 'Bogotá',
  ),
);
