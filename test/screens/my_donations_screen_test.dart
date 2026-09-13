import 'package:donapp_mobile/repositories/donation_repository.dart';

import 'dart:async';

import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/screens/my_donations_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('UI usa el repository inyectado y presenta su error', (
    tester,
  ) async {
    final repository = _RepositorySpy();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MyDonationsScreen(donationRepository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('Error del repository'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.byKey(const Key('myDonationsEmpty')), findsOneWidget);
    expect(find.text('Error del repository'), findsNothing);
  });
  testWidgets('muestra carga inicial y luego datos con estados reales', (
    tester,
  ) async {
    final pending = Completer<DonationPage>();
    await tester.pumpWidget(_app(_FakeService((_, _, _) => pending.future)));
    expect(find.byKey(const Key('myDonationsLoading')), findsOneWidget);
    pending.complete(_page([_item()]));
    await tester.pumpAndSettle();
    expect(
      find.text('Revisa las publicaciones que has realizado.'),
      findsOneWidget,
    );
    expect(find.text('Publicada'), findsWidgets);
    expect(find.byKey(const Key('donationImagePlaceholder')), findsOneWidget);
  });

  testWidgets('muestra vacío', (tester) async {
    await tester.pumpWidget(_app(_FakeService((_, _, _) async => _page([]))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('myDonationsEmpty')), findsOneWidget);
  });

  testWidgets('configura la imagen completa sin deformarla', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService(
          (_, _, _) async => _page([
            _item(
              image: const DonationImage(
                id: 1,
                referencia: 'https://images.test/vertical.jpg',
                orden: 1,
              ),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<Image>(find.byKey(const Key('donationCardImage'))).fit,
      BoxFit.contain,
    );
    expect(find.byKey(const Key('donationCardImageViewport')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra error y permite reintentar', (tester) async {
    var calls = 0;
    final service = _FakeService((_, _, _) async {
      if (calls++ == 0) {
        throw const ApiException(ApiErrorType.network, 'Sin conexión.');
      }
      return _page([_item()]);
    });
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('myDonationsError')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('myDonationCard-7')), findsOneWidget);
  });

  testWidgets('filtra por los cuatro estados del contrato', (tester) async {
    final service = _FakeService((_, _, _) async => _page([]));
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statusFilter')));
    await tester.pumpAndSettle();
    for (final label in [
      'Todas',
      'Publicada',
      'Reservada',
      'Entregada',
      'Retirada',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Reservada').last);
    await tester.pumpAndSettle();
    expect(service.statuses.last, DonationStatus.reservada);
  });

  testWidgets('pull-to-refresh vuelve a pedir la primera página', (
    tester,
  ) async {
    final service = _FakeService((_, _, _) async => _page([_item()]));
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('myDonationsList')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(service.pages, [1, 1]);
  });

  testWidgets('abre el detalle por URI sin transportar objetos', (
    tester,
  ) async {
    final service = _FakeService((_, _, _) async => _page([_item()]));
    final router = GoRouter(
      initialLocation: '/donaciones/mias',
      routes: [
        GoRoute(
          path: '/donaciones/mias',
          builder: (_, _) => MyDonationsScreen(
            donationRepository: DonationRepository.fromService(service),
          ),
        ),
        GoRoute(
          path: '/donaciones/:id',
          builder: (_, state) => Text('Detalle ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('myDonationCard-7')));
    await tester.pumpAndSettle();
    expect(find.text('Detalle 7'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('sin overflow a 240 px y texto ${scale}x', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(240, 640),
            textScaler: TextScaler.linear(scale),
          ),
          child: _app(_FakeService((_, _, _) async => _page([_item()]))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('myDonationCard-7')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _RepositorySpy implements DonationRepository {
  int calls = 0;
  @override
  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) async {
    expect(page, 1);
    expect(limit, 20);
    expect(status, isNull);
    if (++calls == 1) {
      throw const ApiException(ApiErrorType.network, 'Error del repository');
    }
    return _page([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected repository call: ${invocation.memberName}');
}

Widget _app(DonationService service) => MaterialApp(
  theme: AppTheme.light,
  home: MyDonationsScreen(
    donationRepository: DonationRepository.fromService(service),
  ),
);

class _FakeService extends DonationService {
  _FakeService(this.handler);
  final Future<DonationPage> Function(int, int, DonationStatus?) handler;
  final pages = <int>[];
  final statuses = <DonationStatus?>[];
  @override
  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) {
    pages.add(page);
    statuses.add(status);
    return handler(page, limit, status);
  }
}

DonationPage _page(List<DonationListItem> items) => DonationPage(
  donations: items,
  pagination: const DonationPagination(
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  ),
);
DonationListItem _item({DonationImage? image}) => DonationListItem(
  id: 7,
  titulo: 'Mesa auxiliar',
  ciudad: 'Bogotá',
  estado: DonationStatus.publicada,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
  categoriaId: 4,
  categoriaNombre: 'Muebles',
  imagenPrincipal: image,
  cantidadImagenes: image == null ? 0 : 1,
);
