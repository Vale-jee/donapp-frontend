import 'dart:async';

import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/screens/explore_donations_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:donapp_mobile/widgets/donation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra loading inicial', (tester) async {
    final pending = Completer<DonationPage>();
    await tester.pumpWidget(
      _app(
        donationService: _DonationService((_) => pending.future),
        categoryService: _CategoryService(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('exploreLoading')), findsOneWidget);
    pending.complete(_page());
  });

  testWidgets('muestra estado vacío', (tester) async {
    await tester.pumpWidget(
      _app(
        donationService: _DonationService((_) async => _page(items: const [])),
        categoryService: _CategoryService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exploreEmpty')), findsOneWidget);
  });

  testWidgets('muestra error y permite reintentar', (tester) async {
    var calls = 0;
    final service = _DonationService((_) async {
      calls++;
      if (calls == 1) throw _networkError;
      return _page();
    });
    await tester.pumpWidget(
      _app(donationService: service, categoryService: _CategoryService()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exploreError')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byType(DonationCard), findsOneWidget);
  });

  testWidgets('muestra datos reales y placeholder sin imagen', (tester) async {
    await tester.pumpWidget(
      _app(
        donationService: _DonationService((_) async => _page()),
        categoryService: _CategoryService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mesa auxiliar'), findsOneWidget);
    expect(find.text('Muebles'), findsOneWidget);
    expect(find.text('Bogotá'), findsOneWidget);
    expect(find.text('Publicada'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DonationCard),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('donationImagePlaceholder')), findsOneWidget);
  });

  testWidgets('filtra usando el identificador real de categoría', (
    tester,
  ) async {
    final service = _DonationService((_) async => _page());
    await tester.pumpWidget(
      _app(donationService: service, categoryService: _CategoryService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('categoryFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muebles').last);
    await tester.pumpAndSettle();

    expect(service.calls.last.categoryId, 4);
  });

  testWidgets('refresh reemplaza los datos visibles', (tester) async {
    var calls = 0;
    final service = _DonationService((_) async {
      calls++;
      return _page(
        items: [_donationWith(id: calls, title: 'Donación $calls')],
      );
    });
    await tester.pumpWidget(
      _app(donationService: service, categoryService: _CategoryService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Donación 1'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('exploreList')),
      const Offset(0, 350),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Donación 1'), findsNothing);
    expect(find.text('Donación 2'), findsOneWidget);
  });

  testWidgets('agrega la página siguiente sin reemplazar la primera', (
    tester,
  ) async {
    final service = _DonationService((call) async {
      if (call.page == 1) {
        return _page(
          items: List.generate(
            5,
            (index) => _donationWith(id: index + 1, title: 'Inicial $index'),
          ),
          totalPages: 2,
        );
      }
      return _page(
        items: [_donationWith(id: 20, title: 'Página siguiente')],
        page: 2,
        totalPages: 2,
      );
    });
    await tester.pumpWidget(
      _app(donationService: service, categoryService: _CategoryService()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Inicial 4'), 500);
    await tester.pumpAndSettle();

    expect(find.text('Inicial 0'), findsOneWidget);
    expect(find.text('Página siguiente'), findsOneWidget);
    expect(service.calls.map((call) => call.page), containsAllInOrder([1, 2]));
  });

  testWidgets('error de página siguiente conserva los datos visibles', (
    tester,
  ) async {
    final service = _DonationService((call) async {
      if (call.page == 2) throw _networkError;
      return _page(
        items: List.generate(
          5,
          (index) => _donationWith(id: index + 1, title: 'Visible $index'),
        ),
        totalPages: 2,
      );
    });
    await tester.pumpWidget(
      _app(donationService: service, categoryService: _CategoryService()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Visible 4'), 500);
    await tester.pumpAndSettle();

    expect(find.text('Visible 0'), findsOneWidget);
    expect(find.byKey(const Key('explorePaginationError')), findsOneWidget);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('no desborda a 240 px con texto $textScale×', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(
          donationService: _DonationService((_) async => _page()),
          categoryService: _CategoryService(),
          mediaQuery: MediaQueryData(
            size: const Size(240, 640),
            textScaler: TextScaler.linear(textScale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Publicada'), 250);

      expect(tester.takeException(), isNull);
      expect(find.text('Mesa auxiliar'), findsOneWidget);
    });
  }
}

Widget _app({
  required DonationService donationService,
  required CategoryService categoryService,
  MediaQueryData? mediaQuery,
}) {
  final screen = ExploreDonationsScreen(
    donationService: donationService,
    categoryService: categoryService,
  );
  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null
        ? screen
        : MediaQuery(data: mediaQuery, child: screen),
  );
}

class _DonationCall {
  const _DonationCall(this.page, this.limit, this.categoryId);
  final int page;
  final int limit;
  final int? categoryId;
}

class _DonationService extends DonationService {
  _DonationService(this.response);

  final Future<DonationPage> Function(_DonationCall call) response;
  final List<_DonationCall> calls = [];

  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) {
    final call = _DonationCall(page, limit, categoryId);
    calls.add(call);
    return response(call);
  }
}

class _CategoryService extends CategoryService {
  @override
  Future<List<Category>> getCategories() async => const [
    Category(id: 4, nombre: 'Muebles', descripcion: null),
  ];
}

DonationPage _page({
  List<DonationListItem>? items,
  int page = 1,
  int totalPages = 1,
}) => DonationPage(
  donations: items ?? [_donation],
  pagination: DonationPagination(
    page: page,
    limit: 20,
    total: items?.length ?? 1,
    totalPages: (items?.isEmpty ?? false) ? 0 : totalPages,
  ),
);

DonationListItem _donationWith({required int id, required String title}) =>
    DonationListItem(
      id: id,
      titulo: title,
      ciudad: _donation.ciudad,
      estado: _donation.estado,
      createdAt: _donation.createdAt,
      updatedAt: _donation.updatedAt,
      categoriaId: _donation.categoriaId,
      categoriaNombre: _donation.categoriaNombre,
      imagenPrincipal: null,
      cantidadImagenes: 0,
    );

final _donation = DonationListItem(
  id: 8,
  titulo: 'Mesa auxiliar',
  ciudad: 'Bogotá',
  estado: DonationStatus.publicada,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
  categoriaId: 4,
  categoriaNombre: 'Muebles',
  imagenPrincipal: null,
  cantidadImagenes: 0,
);

const _networkError = ApiException(
  ApiErrorType.network,
  'No pudimos conectarnos.',
);
