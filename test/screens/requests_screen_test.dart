import 'dart:async';

import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/screens/requests_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('muestra loading y luego solicitudes enviadas reales', (
    tester,
  ) async {
    final pending = Completer<RequestPage<SentRequestListItem>>();
    final service = _FakeService(sent: (_, _) => pending.future);
    await tester.pumpWidget(_app(SentRequestsScreen(requestService: service)));
    expect(find.byKey(const Key('requestsLoading')), findsOneWidget);
    pending.complete(_sentPage([_sent()]));
    await tester.pumpAndSettle();
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.text('donante'), findsOneWidget);
    expect(find.byKey(const Key('requestImagePlaceholder')), findsOneWidget);
  });

  testWidgets('muestra vacío', (tester) async {
    final service = _FakeService(sent: (_, _) async => _sentPage([]));
    await tester.pumpWidget(_app(SentRequestsScreen(requestService: service)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('requestsEmpty')), findsOneWidget);
  });

  testWidgets('muestra error y reintenta', (tester) async {
    var calls = 0;
    final service = _FakeService(
      sent: (_, _) async {
        if (calls++ == 0) {
          throw const ApiException(ApiErrorType.network, 'Sin conexión');
        }
        return _sentPage([_sent()]);
      },
    );
    await tester.pumpWidget(_app(SentRequestsScreen(requestService: service)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('requestsError')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('requestCard-7')), findsOneWidget);
  });

  testWidgets('filtro envía el estado real y refresh vuelve a página uno', (
    tester,
  ) async {
    final service = _FakeService(sent: (_, _) async => _sentPage([_sent()]));
    await tester.pumpWidget(_app(SentRequestsScreen(requestService: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('requestStatusFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptadas').last);
    await tester.pumpAndSettle();
    expect(service.statuses.last, RequestStatus.aceptada);
    await tester.drag(
      find.byKey(const Key('requestsList')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(service.pages.last, 1);
  });

  testWidgets('recibidas muestra solicitante y causa real', (tester) async {
    final service = _FakeService(
      received: (_, _) async =>
          _receivedPage([_received(cause: CancellationCause.donacionRetirada)]),
    );
    await tester.pumpWidget(
      _app(ReceivedRequestsScreen(requestService: service)),
    );
    await tester.pumpAndSettle();
    expect(find.text('solicitante'), findsOneWidget);
    expect(find.text('La donación fue retirada'), findsOneWidget);
  });

  testWidgets('tarjeta navega a detalle mediante id', (tester) async {
    final service = _FakeService(sent: (_, _) async => _sentPage([_sent()]));
    final router = GoRouter(
      initialLocation: '/solicitudes/enviadas',
      routes: [
        GoRoute(
          path: '/solicitudes/enviadas',
          builder: (_, _) => SentRequestsScreen(requestService: service),
        ),
        GoRoute(
          path: '/solicitudes/:id',
          builder: (_, state) => Text('Detalle ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('requestsList')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bicicleta'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle 7'), findsOneWidget);
  });

  testWidgets('selector cambia entre Enviadas y Recibidas', (tester) async {
    final service = _FakeService(
      sent: (_, _) async => _sentPage([]),
      received: (_, _) async => _receivedPage([]),
    );
    final router = GoRouter(
      initialLocation: '/solicitudes/enviadas',
      routes: [
        GoRoute(
          path: '/solicitudes/enviadas',
          builder: (_, _) => SentRequestsScreen(requestService: service),
        ),
        GoRoute(
          path: '/solicitudes/recibidas',
          builder: (_, _) => ReceivedRequestsScreen(requestService: service),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recibidas'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/solicitudes/recibidas');
    expect(find.byType(ReceivedRequestsScreen), findsOneWidget);
  });

  testWidgets('error de página siguiente conserva datos previos', (
    tester,
  ) async {
    final service = _FakeService(
      sent: (page, _) async {
        if (page == 2) {
          throw const ApiException(ApiErrorType.network, 'Sin conexión');
        }
        return _sentPage([_sent()], page: 1, totalPages: 2);
      },
    );
    await tester.pumpWidget(_app(SentRequestsScreen(requestService: service)));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('requestsList')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('requestCard-7')), findsOneWidget);
    expect(find.byKey(const Key('requestsPaginationError')), findsOneWidget);
    expect(service.pages, contains(2));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('sin overflow a 240 px con texto ${scale}x', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final service = _FakeService(sent: (_, _) async => _sentPage([_sent()]));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(240, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: _app(SentRequestsScreen(requestService: service)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

class _FakeService extends RequestService {
  _FakeService({this.sent, this.received});
  final Future<RequestPage<SentRequestListItem>> Function(int, RequestStatus?)?
  sent;
  final Future<RequestPage<ReceivedRequestListItem>> Function(
    int,
    RequestStatus?,
  )?
  received;
  final pages = <int>[];
  final statuses = <RequestStatus?>[];
  @override
  Future<RequestPage<SentRequestListItem>> getSentRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) {
    pages.add(page);
    statuses.add(status);
    return sent!(page, status);
  }

  @override
  Future<RequestPage<ReceivedRequestListItem>> getReceivedRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) {
    pages.add(page);
    statuses.add(status);
    return received!(page, status);
  }
}

RequestPage<SentRequestListItem> _sentPage(
  List<SentRequestListItem> items, {
  int page = 1,
  int totalPages = 1,
}) => RequestPage(
  requests: items,
  pagination: RequestPagination(
    page: page,
    limit: 20,
    total: items.length,
    totalPages: items.isEmpty ? 0 : totalPages,
  ),
);
RequestPage<ReceivedRequestListItem> _receivedPage(
  List<ReceivedRequestListItem> items,
) => RequestPage(
  requests: items,
  pagination: RequestPagination(
    page: 1,
    limit: 20,
    total: items.length,
    totalPages: items.isEmpty ? 0 : 1,
  ),
);

SentRequestListItem _sent() => SentRequestListItem(
  id: 7,
  status: RequestStatus.pendiente,
  cancellationCause: null,
  acceptedAt: null,
  rejectedAt: null,
  cancelledAt: null,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
  donation: _donation,
  donor: _user('donante'),
);
ReceivedRequestListItem _received({CancellationCause? cause}) =>
    ReceivedRequestListItem(
      id: 7,
      status: cause == null ? RequestStatus.pendiente : RequestStatus.cancelada,
      cancellationCause: cause,
      acceptedAt: null,
      rejectedAt: null,
      cancelledAt: cause == null ? null : DateTime.utc(2026, 8, 21),
      createdAt: DateTime.utc(2026, 8, 20),
      updatedAt: DateTime.utc(2026, 8, 20),
      donation: _donation,
      applicant: _user('solicitante'),
    );
const _donation = RequestDonationSummary(
  id: 4,
  title: 'Bicicleta',
  status: RequestDonationStatus.publicada,
  mainImage: null,
);
RequestUserSummary _user(String name) => RequestUserSummary(
  id: 2,
  visibleName: name,
  profilePhoto: null,
  city: 'Bogotá',
);
