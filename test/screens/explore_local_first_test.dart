import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/screens/explore_donations_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';

void main() {
  testWidgets('caché y fallo remoto conservan tarjetas y muestran aviso', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final local = DonationLocalDataSource(db);
    await _repository(local, success: true).refreshCategories();
    await _repository(local, success: true).refreshExplore(cacheUserId: 77);
    await tester.pumpWidget(_app(_repository(local, success: false)));
    await tester.pumpAndSettle();
    expect(find.text('Donación guardada'), findsOneWidget);
    expect(find.byKey(const Key('exploreError')), findsNothing);
    expect(find.byKey(const Key('exploreFreshnessIndicator')), findsOneWidget);
    expect(find.textContaining('mostrando datos guardados'), findsOneWidget);
    expect(find.textContaining('Última sincronización:'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('caché fresca y backend correcto no muestran advertencia', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _repository(DonationLocalDataSource(db), success: true);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Donación guardada'), findsOneWidget);
    expect(find.byKey(const Key('exploreFreshnessIndicator')), findsNothing);
    await _dispose(tester);
  });

  testWidgets('caché vencida sigue visible con fecha y semántica', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final local = DonationLocalDataSource(db);
    final oldSync = DateTime.now().subtract(const Duration(days: 2));
    await _repository(
      local,
      success: true,
      clock: () => oldSync,
    ).refreshCategories();
    await _repository(
      local,
      success: true,
      clock: () => oldSync,
    ).refreshExplore(cacheUserId: 77);
    final pending = Completer<DonationPage>();
    final repository = DonationRepository(
      local,
      DonationRemoteDataSource(
        _PendingDonationService(pending),
        _CategoryService(),
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Donación guardada'), findsOneWidget);
    expect(find.text('Los datos pueden estar desactualizados'), findsOneWidget);
    expect(find.textContaining('Última sincronización:'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const Key('exploreFreshnessIndicator')),
    );
    expect(semantics.label, contains('Los datos pueden estar desactualizados'));
    expect(semantics.label, contains('Última sincronización'));
    pending.complete(_page());
    await tester.pumpAndSettle();
    await _dispose(tester);
  });

  testWidgets('sin caché y fallo remoto conserva estado sin contenido', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      _app(_repository(DonationLocalDataSource(db), success: false)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exploreError')), findsOneWidget);
    expect(find.byKey(const Key('exploreFreshnessIndicator')), findsNothing);
    await _dispose(tester);
  });
}

DonationRepository _repository(
  DonationLocalDataSource local, {
  required bool success,
  DateTime Function()? clock,
}) => DonationRepository(
  local,
  DonationRemoteDataSource(
    _DonationService(success: success),
    _CategoryService(fail: !success),
  ),
  clock: clock,
);

Widget _app(DonationRepository repository) => MaterialApp(
  theme: AppTheme.light,
  home: ExploreDonationsScreen(
    cacheUserId: 77,
    repository: repository,
    donationService: _DonationService(success: true),
    categoryService: _CategoryService(),
  ),
);

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

class _PendingDonationService extends DonationService {
  _PendingDonationService(this.pending);
  final Completer<DonationPage> pending;
  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) => pending.future;
}

class _DonationService extends DonationService {
  _DonationService({required this.success});
  final bool success;
  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    if (!success) {
      throw const ApiException(ApiErrorType.network, 'Sin conexión');
    }
    return _page();
  }
}

class _CategoryService extends CategoryService {
  _CategoryService({this.fail = false});
  final bool fail;
  @override
  Future<List<Category>> getCategories() async {
    if (fail) {
      throw const ApiException(ApiErrorType.network, 'Sin conexión');
    }
    return const [Category(id: 4, nombre: 'Muebles', descripcion: null)];
  }
}

DonationPage _page() => DonationPage(
  donations: [
    DonationListItem(
      id: 10,
      titulo: 'Donación guardada',
      ciudad: 'Bogotá',
      estado: DonationStatus.publicada,
      createdAt: DateTime.utc(2026, 8, 20),
      updatedAt: DateTime.utc(2026, 8, 20),
      categoriaId: 4,
      categoriaNombre: 'Muebles',
      imagenPrincipal: null,
      cantidadImagenes: 0,
    ),
  ],
  pagination: const DonationPagination(
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  ),
);
