import 'dart:async';
import 'dart:convert';

import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/repositories/category_repository.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/screens/edit_donation_screen.dart';
import 'package:donapp_mobile/screens/my_donations_screen.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:donapp_mobile/validation/donation_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('validadores compartidos conservan límites y texto simple', () {
    expect(validateDonationTitle('  Mesa   azul  '), isNull);
    expect(validateDonationTitle('abcd'), isNotNull);
    expect(validateDonationTitle('x' * 101), isNotNull);
    expect(validateDonationTitle('x' * 100), isNull);
    expect(validateDonationDescription('x' * 19), isNotNull);
    expect(validateDonationDescription('x' * 20), isNull);
    expect(validateDonationDescription('x' * 1000), isNull);
    expect(validateDonationDescription('x' * 1001), isNotNull);
    for (final text in [
      '<b>Descripción con etiquetas</b>',
      '```contenido de código```',
      '[Descripción del artículo](https://example.test)',
      '# Encabezado de descripción',
    ]) {
      expect(validateDonationDescription(text), isNotNull);
    }
    expect(validateDonationCategory(null), isNotNull);
  });

  for (final status in DonationStatus.values) {
    testWidgets('detalle propio $status: Editar solo PUBLICADA', (
      tester,
    ) async {
      final harness = _Harness(status: status);
      await tester.pumpWidget(harness.detailApp());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('editDonationButton')),
        status == DonationStatus.publicada ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('ajena sin puedeSolicitar no se confunde con propia', (
    tester,
  ) async {
    final harness = _Harness(owned: false);
    await tester.pumpWidget(harness.detailApp());
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsNothing);
    await tester.pumpWidget(harness.editApp());
    await tester.pumpAndSettle();
    expect(
      find.text('Esta donación no está disponible para editar.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('saveDonationButton')), findsNothing);
    expect(harness.patches, isEmpty);
  });

  testWidgets('verifica propiedad paginada sin usar el permiso de solicitar', (
    tester,
  ) async {
    final harness = _Harness(ownPage: 2);
    await tester.pumpWidget(harness.detailApp());
    await tester.pumpAndSettle();
    expect(harness.ownPages, [1, 2]);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('precarga y sin cambios normalizados no envía PATCH', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.editApp());
    await tester.pumpAndSettle();
    expect(find.text('Mesa auxiliar'), findsOneWidget);
    expect(find.text('Mesa de madera en buen estado.'), findsOneWidget);
    expect(find.text('Muebles'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('editDonationTitle')),
      '  Mesa   auxiliar  ',
    );
    await _save(tester);
    await tester.pumpAndSettle();
    expect(find.text('No hay cambios para guardar.'), findsOneWidget);
    expect(harness.patches, isEmpty);
  });

  testWidgets('validación en formulario evita PATCH inválido', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.editApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editDonationTitle')), 'abc');
    await tester.enterText(
      find.byKey(const Key('editDonationDescription')),
      'corta',
    );
    await _save(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('El título debe tener al menos 5 caracteres.'),
      findsOneWidget,
    );
    expect(
      find.text('La descripción debe tener al menos 20 caracteres.'),
      findsOneWidget,
    );
    expect(harness.patches, isEmpty);
  });

  testWidgets(
    'PATCH único, body correcto, bloqueo y datos nuevos en detalle y lista',
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
      await tester.tap(find.byKey(const ValueKey('myDonationCard-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editDonationTitle')),
        '  Mesa   renovada  ',
      );
      await tester.enterText(
        find.byKey(const Key('editDonationDescription')),
        'Descripción actualizada de la mesa.',
      );
      await tester.tap(find.byKey(const Key('editDonationCategory')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hogar').last);
      await tester.pumpAndSettle();
      await _save(tester);
      await tester.pump();
      await tester.tap(find.byKey(const Key('saveDonationButton')));
      await tester.pump();
      expect(harness.patches, hasLength(1));
      expect(harness.patches.single, {
        'titulo': 'Mesa renovada',
        'descripcion': 'Descripción actualizada de la mesa.',
        'categoriaId': 5,
      });
      expect(harness.authorization, 'Bearer test-access');
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(const Key('saveDonationButton')),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(EditDonationScreen), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(EditDonationScreen), findsNothing);
      expect(find.text('Donación actualizada correctamente.'), findsOneWidget);
      expect(find.text('Mesa renovada'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MyDonationsScreen), findsOneWidget);
      expect(find.text('Mesa renovada'), findsOneWidget);
      expect(harness.patches, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('myDonationCard-4')));
      await tester.pumpAndSettle();
      expect(find.text('Mesa renovada'), findsOneWidget);
    },
  );

  for (final failure in ['network', '400', '403', '404', '409', '500']) {
    testWidgets('error $failure conserva campos y no repite PATCH', (
      tester,
    ) async {
      final harness = _Harness()..failure = failure;
      await tester.pumpWidget(harness.editApp());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editDonationTitle')),
        'Mesa modificada',
      );
      await _save(tester);
      await tester.pumpAndSettle();
      expect(harness.patches, hasLength(1));
      expect(harness.patches.single, {'titulo': 'Mesa modificada'});
      expect(find.text('Mesa modificada'), findsOneWidget);
      expect(find.byKey(const Key('editDonationError')), findsOneWidget);
      expect(find.textContaining('SQL'), findsNothing);
      expect(harness.repository.confirmedUpdate(4), isNull);
    });
  }
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('saveDonationButton')));
  await tester.tap(find.byKey(const Key('saveDonationButton')));
}

class _Categories extends CategoryRepository {
  @override
  Future<List<Category>> getCategories() async => const [
    Category(id: 4, nombre: 'Muebles', descripcion: null),
    Category(id: 5, nombre: 'Hogar', descripcion: null),
  ];
}

class _Tokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'test-access';
}

class _Harness {
  _Harness({
    this.owned = true,
    DonationStatus status = DonationStatus.publicada,
    this.ownPage = 1,
  }) {
    data['estado'] = status.apiValue;
    repository = DonationRepository.fromService(
      DonationService(
        tokenStorage: _Tokens(),
        apiClient: ApiClient(
          endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
          client: MockClient(_request),
          retryDelay: (_) async => fail('No debe reintentar PATCH'),
        ),
      ),
    );
  }
  final bool owned;
  final int ownPage;
  final ownPages = <int>[];
  late final DonationRepository repository;
  final patches = <Map<String, dynamic>>[];
  String? failure;
  String? authorization;
  Future<void>? pending;
  final Map<String, dynamic> data = {
    'id': 4,
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
    if (request.method == 'PATCH') {
      expect(request.url.path, '/api/donaciones/4');
      authorization = request.headers['Authorization'];
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      patches.add(body);
      if (pending != null) await pending;
      if (failure == 'network') {
        throw http.ClientException('internal connection details');
      }
      if (failure != null) {
        return http.Response(
          jsonEncode({
            'success': false,
            'status': int.parse(failure!),
            'message': 'SQL internal failure',
            'data': null,
          }),
          int.parse(failure!),
        );
      }
      data.addAll(body);
      if (body['categoriaId'] != null) {
        data['categoria'] = {'id': 5, 'nombre': 'Hogar'};
      }
      data['updatedAt'] = '2026-09-28T12:00:00Z';
    }
    if (request.url.path.endsWith('/mias')) {
      final page = int.parse(request.url.queryParameters['page']!);
      ownPages.add(page);
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'donaciones': owned && page == ownPage
                ? [
                    {...data, 'imagenPrincipal': null, 'cantidadImagenes': 0},
                  ]
                : [],
            'pagination': {
              'page': page,
              'limit': 100,
              'total': owned ? 1 : 0,
              'totalPages': ownPage,
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
    donationId: 4,
    cacheUserId: 1,
    donationRepository: repository,
    categoryRepository: _Categories(),
  );
  Widget detailApp() => MaterialApp(theme: AppTheme.light, home: detail());
  Widget editApp() => MaterialApp(
    theme: AppTheme.light,
    home: EditDonationScreen(
      donation: DonationDetail.fromJson(data),
      cacheUserId: 1,
      donationRepository: repository,
      categoryRepository: _Categories(),
    ),
  );
}
