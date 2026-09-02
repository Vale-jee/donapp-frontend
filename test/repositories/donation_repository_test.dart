import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';

void main() {
  late AppDatabase db;
  late DonationLocalDataSource local;
  final now = DateTime.utc(2026, 9, 2, 15);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = DonationLocalDataSource(db);
  });
  tearDown(() => db.close());

  DonationRepository repository(
    _DonationService service, {
    CategoryService? categories,
  }) => DonationRepository(
    local,
    DonationRemoteDataSource(service, categories ?? _CategoryService()),
    clock: () => now,
  );

  test(
    'respuesta remota se guarda, actualiza membresía y no duplica',
    () async {
      var title = 'Mesa inicial';
      final repo = repository(
        _DonationService((_) async => _page(title: title)),
      );
      await repo.refreshExplore(cacheUserId: 1);
      title = 'Mesa actualizada';
      await repo.refreshExplore(cacheUserId: 1);

      final cached = await repo.watchExplore(cacheUserId: 1).first;
      expect(cached, hasLength(1));
      expect(cached.single.titulo, 'Mesa actualizada');
      expect(await db.select(db.localDonations).get(), hasLength(1));
      final memberships = await db.select(db.localDonationMemberships).get();
      expect(memberships, hasLength(1));
      expect(memberships.single.collectionType, DonationCollectionType.explore);
      expect(
        (await db.select(db.localDonations).getSingle()).lastSyncedAt?.toUtc(),
        now,
      );
    },
  );

  test('un fallo remoto mantiene datos locales existentes', () async {
    await repository(_DonationService((_) async => _page()))
        .refreshExplore(cacheUserId: 1);
    final failing = repository(
      _DonationService((_) async => throw _networkError),
    );
    await expectLater(
      failing.refreshExplore(cacheUserId: 1),
      throwsA(_networkError),
    );
    expect(await failing.watchExplore(cacheUserId: 1).first, hasLength(1));
  });

  test('local vacío y backend fallido permanece sin contenido', () async {
    final repo = repository(_DonationService((_) async => throw _networkError));
    await expectLater(
      repo.refreshExplore(cacheUserId: 1),
      throwsA(_networkError),
    );
    expect(await repo.watchExplore(cacheUserId: 1).first, isEmpty);
  });

  test('aísla por cacheUserId y filtra por categoría', () async {
    final repo = repository(
      _DonationService((call) async => _page(id: call.userDonationId)),
    );
    await repo.refreshExplore(cacheUserId: 1);
    await repo.refreshExplore(cacheUserId: 2);
    expect((await repo.watchExplore(cacheUserId: 1).first).single.id, 10);
    expect((await repo.watchExplore(cacheUserId: 2).first).single.id, 20);
    expect(
      await repo.watchExplore(cacheUserId: 1, categoryId: 999).first,
      isEmpty,
    );
    expect(
      await repo.watchExplore(cacheUserId: 1, categoryId: 4).first,
      hasLength(1),
    );
  });

  test('datos vencidos siguen legibles y solicitan refresh', () async {
    final repo = repository(_DonationService((_) async => _page()));
    await repo.refreshExplore(cacheUserId: 1);
    await (db.update(
      db.localCollectionMetadata,
    )..where((row) => row.cacheUserId.equals(1))).write(
      LocalCollectionMetadataCompanion(
        expiresAt: Value(now.subtract(const Duration(minutes: 1))),
      ),
    );
    expect(await repo.needsExploreRefresh(1), isTrue);
    expect(await repo.watchExplore(cacheUserId: 1).first, hasLength(1));
  });

  test(
    'categorías se leen local-first y sobreviven a un fallo remoto',
    () async {
      final successful = repository(_DonationService((_) async => _page()));
      await successful.refreshCategories();
      expect(
        (await successful.watchCategories().first).single.nombre,
        'Muebles',
      );

      final failing = repository(
        _DonationService((_) async => _page()),
        categories: _CategoryService(fail: true),
      );
      await expectLater(failing.refreshCategories(), throwsA(_networkError));
      expect(await failing.watchCategories().first, hasLength(1));
    },
  );
}

class _Call {
  const _Call(this.page);
  final int page;
  int get userDonationId => page == 1 ? 10 : 20;
}

class _DonationService extends DonationService {
  _DonationService(this.handler);
  final Future<DonationPage> Function(_Call call) handler;
  int calls = 0;
  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) {
    calls++;
    return handler(_Call(calls));
  }
}

class _CategoryService extends CategoryService {
  _CategoryService({this.fail = false});
  final bool fail;
  @override
  Future<List<Category>> getCategories() async {
    if (fail) throw _networkError;
    return const [Category(id: 4, nombre: 'Muebles', descripcion: null)];
  }
}

DonationPage _page({String title = 'Mesa', int id = 10}) => DonationPage(
  donations: [
    DonationListItem(
      id: id,
      titulo: title,
      ciudad: 'Bogotá',
      estado: DonationStatus.publicada,
      createdAt: DateTime.utc(2026, 8, 20),
      updatedAt: DateTime.utc(2026, 8, 21),
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

const _networkError = ApiException(ApiErrorType.network, 'Sin conexión');
