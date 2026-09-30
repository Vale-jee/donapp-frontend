import 'dart:async';
import 'dart:convert';

import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/screens/my_donations_screen.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final status in DonationStatus.values) {
    testWidgets('Eliminar solo en propia PUBLICADA: $status', (tester) async {
      final harness = _Harness(status: status);
      await tester.pumpWidget(harness.detailApp());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deleteDonationButton')),
        status == DonationStatus.publicada ? findsOneWidget : findsNothing,
      );
    });
  }
  testWidgets('ajena sin permiso de solicitar no muestra Eliminar', (
    tester,
  ) async {
    final harness = _Harness(owned: false);
    await tester.pumpWidget(harness.detailApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteDonationButton')), findsNothing);
  });
  testWidgets('Cancelar no envía DELETE', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.detailApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteDonationButton')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '¿Seguro que deseas eliminar esta donación? Esta acción no se puede deshacer.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(harness.deletes, 0);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(DonationDetailScreen), findsOneWidget);
  });
  testWidgets(
    'doble toque: un DELETE, vuelve a Mis donaciones y retira la tarjeta',
    (tester) async {
      final harness = _Harness();
      final pending = Completer<void>();
      harness.pending = pending.future;
      final router = GoRouter(
        initialLocation: '/donaciones/mias',
        routes: [
          GoRoute(
            path: '/donaciones/mias',
            builder: (_, _) =>
                MyDonationsScreen(donationRepository: harness.repository),
          ),
          GoRoute(path: '/donaciones/:id', builder: (_, _) => harness.detail()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('myDonationCard-731')));
      await tester.pumpAndSettle();
      final delete = find.byKey(const Key('deleteDonationButton'));
      final openDialog = tester.widget<TextButton>(delete).onPressed!;
      await tester.tap(delete);
      openDialog();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final confirm = find.byKey(const Key('confirmDeleteDonationButton'));
      final confirmDeletion = tester.widget<FilledButton>(confirm).onPressed!;
      await tester.tap(confirm);
      confirmDeletion();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(harness.deletes, 1);
      expect(tester.widget<TextButton>(delete).onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DonationDetailScreen), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(MyDonationsScreen), findsOneWidget);
      expect(find.byType(DonationDetailScreen), findsNothing);
      expect(find.byKey(const ValueKey('myDonationCard-731')), findsNothing);
      expect(find.text('Donación eliminada correctamente.'), findsOneWidget);
      expect(harness.deletes, 1);
      // Even a stale own-list response cannot revive a confirmed deletion.
      expect((await harness.repository.getOwnDonations()).donations, isEmpty);
    },
  );
  for (final failure in [
    'requests',
    'history',
    'network',
    '403',
    '404',
    '500',
  ]) {
    testWidgets(
      '$failure conserva detalle y permite reintento sin texto técnico',
      (tester) async {
        final harness = _Harness()..failure = failure;
        await tester.pumpWidget(harness.detailApp());
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('deleteDonationButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmDeleteDonationButton')));
        await tester.pumpAndSettle();
        expect(harness.deletes, 1);
        expect(find.byType(DonationDetailScreen), findsOneWidget);
        expect(harness.repository.wasDeleted(731), isFalse);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('deleteDonationButton')))
              .onPressed,
          isNotNull,
        );
        expect(find.textContaining('SQL'), findsNothing);
        if (failure == 'requests') {
          expect(find.text(_requestsMessage), findsOneWidget);
        }
        if (failure == 'history') {
          expect(find.text(_historyMessage), findsOneWidget);
        }
        if (failure == 'network') {
          expect(find.textContaining('Verifica tu conexión'), findsOneWidget);
        }
      },
    );
  }
}

const _requestsMessage =
    'Esta donación no se puede eliminar porque ya tiene solicitudes asociadas.';
const _historyMessage =
    'Esta donación no se puede eliminar porque tiene historial asociado que debe conservarse.';

class _Harness {
  _Harness({
    this.owned = true,
    DonationStatus status = DonationStatus.publicada,
  }) {
    data['estado'] = status.apiValue;
    repository = DonationRepository.fromService(
      DonationService(
        apiClient: ApiClient(
          endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
          client: MockClient(_request),
        ),
      ),
    );
  }
  final bool owned;
  late final DonationRepository repository;
  int deletes = 0;
  String? failure;
  Future<void>? pending;
  final Map<String, dynamic> data = {
    'id': 731,
    'titulo': 'Mesa auxiliar',
    'descripcion': 'Mesa de madera en buen estado.',
    'ciudad': 'Bogotá',
    'estado': 'PUBLICADA',
    'createdAt': '2026-09-01T12:00:00Z',
    'updatedAt': '2026-09-01T12:00:00Z',
    'categoria': {'id': 4, 'nombre': 'Muebles'},
    'imagenes': <Map<String, dynamic>>[],
    'puedeSolicitar': false,
  };
  Future<http.Response> _request(http.Request request) async {
    if (request.method == 'DELETE') {
      deletes++;
      expect(request.url.path, '/api/donaciones/731');
      expect(request.body, isEmpty);
      if (pending != null) await pending;
      if (failure == 'network') {
        throw http.ClientException('SQL internal connection');
      }
      if (failure != null) {
        final status = int.tryParse(failure!) ?? 409;
        return http.Response(
          jsonEncode({
            'success': false,
            'status': status,
            'data': null,
            'message': failure == 'requests'
                ? _requestsMessage
                : failure == 'history'
                ? _historyMessage
                : 'SQL internal failure',
          }),
          status,
        );
      }
      return http.Response('{"success":true,"data":{"id":731}}', 200);
    }
    if (request.url.path.endsWith('/mias')) {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'donaciones': owned
                ? [
                    {...data, 'imagenPrincipal': null, 'cantidadImagenes': 0},
                  ]
                : [],
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': owned ? 1 : 0,
              'totalPages': 1,
            },
          },
        }),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {'donacion': data},
      }),
      200,
    );
  }

  Widget detail() => DonationDetailScreen(
    donationId: 731,
    cacheUserId: 1,
    donationRepository: repository,
  );
  Widget detailApp() => MaterialApp(theme: AppTheme.light, home: detail());
}
