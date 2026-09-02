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
  testWidgets('no queda vacía si existe caché y falla el backend', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final local = DonationLocalDataSource(db);
    final seed = DonationRepository(
      local,
      DonationRemoteDataSource(
        _DonationService(success: true),
        _CategoryService(),
      ),
    );
    await seed.refreshCategories();
    await seed.refreshExplore(cacheUserId: 77);

    final repository = DonationRepository(
      local,
      DonationRemoteDataSource(
        _DonationService(success: false),
        _CategoryService(fail: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ExploreDonationsScreen(
          cacheUserId: 77,
          repository: repository,
          donationService: _DonationService(success: false),
          categoryService: _CategoryService(fail: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Donación guardada'), findsOneWidget);
    expect(find.byKey(const Key('exploreError')), findsNothing);
    expect(find.byKey(const Key('exploreEmpty')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
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
    return DonationPage(
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
  }
}

class _CategoryService extends CategoryService {
  _CategoryService({this.fail = false});
  final bool fail;
  @override
  Future<List<Category>> getCategories() async {
    if (fail) throw const ApiException(ApiErrorType.network, 'Sin conexión');
    return const [Category(id: 4, nombre: 'Muebles', descripcion: null)];
  }
}
