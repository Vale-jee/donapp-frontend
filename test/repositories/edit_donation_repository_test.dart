import 'dart:convert';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  late DonationLocalDataSource local;
  final updated = DonationDetail.fromMutationJson(_body);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = DonationLocalDataSource(db);
  });
  tearDown(() => db.close());

  Future<int> seed({
    int userId = 1,
    DonationSyncState state = DonationSyncState.synced,
    DateTime? serverTime,
  }) async {
    final id = await db
        .into(db.localDonations)
        .insert(
          LocalDonationsCompanion.insert(
            cacheUserId: userId,
            clientId: 'client-$userId',
            remoteId: const Value(4),
            expiresAt: DateTime.utc(2026, 10),
            syncState: state,
            title: 'Mesa anterior',
            description: const Value('Descripción anterior de la mesa.'),
            city: 'Bogotá',
            categoryId: 4,
            categoryName: 'Muebles',
            status: const Value('PUBLICADA'),
            mainImageUrl: const Value('/image.jpg'),
            imageCount: const Value(1),
            serverUpdatedAt: Value(serverTime ?? DateTime.utc(2026, 9, 1)),
          ),
        );
    await db
        .into(db.localDonationImages)
        .insert(
          LocalDonationImagesCompanion.insert(
            localDonationId: id,
            remoteImageId: const Value(9),
            remoteUrl: const Value('/image.jpg'),
            cachedLocalPath: const Value('/cache/image.jpg'),
            sortOrder: 1,
            uploadState: ImageUploadState.remote,
          ),
        );
    await db
        .into(db.localDonationMemberships)
        .insert(
          LocalDonationMembershipsCompanion.insert(
            cacheUserId: userId,
            localDonationId: id,
            collectionType: DonationCollectionType.explore,
            lastSeenAt: DateTime.utc(2026, 9),
            expiresAt: DateTime.utc(2026, 10),
          ),
        );
    return id;
  }

  DonationRepository repo(Future<http.Response> Function(http.Request) send) =>
      DonationRepository(
        local,
        DonationRemoteDataSource(
          DonationService(
            apiClient: ApiClient(
              endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
              client: MockClient(send),
            ),
          ),
          const CategoryService(),
        ),
      );

  test('PATCH confirmado actualiza Drift y stream conservando identidad, imágenes y otras sesiones', () async {
    final id = await seed();
    await seed(userId: 2);
    final imagesBefore = await db.select(db.localDonationImages).get();
    final membershipsBefore = await db
        .select(db.localDonationMemberships)
        .get();
    var calls = 0;
    final repository = repo((request) async {
      calls++;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/donaciones/4');
      expect(jsonDecode(request.body), {
        'titulo': 'Mesa actualizada',
        'categoriaId': 5,
      });
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'donacion': _body},
        }),
        200,
      );
    });
    final change = repository
        .watchExplore(cacheUserId: 1)
        .firstWhere((items) => items.single.titulo == 'Mesa actualizada');
    final result = await repository.updateDonation(
      4,
      cacheUserId: 1,
      title: 'Mesa actualizada',
      categoryId: 5,
    );
    expect(result.id, 4);
    expect(calls, 1);
    expect((await change).single.categoriaId, 5);
    final row = await (db.select(
      db.localDonations,
    )..where((row) => row.localId.equals(id))).getSingle();
    expect(row.clientId, 'client-1');
    expect(row.description, updated.descripcion);
    expect(row.syncState, DonationSyncState.synced);
    expect(await db.select(db.localDonationImages).get(), imagesBefore);
    expect(
      await db.select(db.localDonationMemberships).get(),
      membershipsBefore,
    );
    expect(
      (await repository.watchExplore(cacheUserId: 2).first).single.titulo,
      'Mesa anterior',
    );
    expect(await db.select(db.pendingOperations).get(), isEmpty);
  });

  for (final status in [400, 401, 403, 404, 409, 500]) {
    test('PATCH $status no modifica caché ni crea outbox', () async {
      await seed();
      final before = await db.select(db.localDonations).get();
      var calls = 0;
      final repository = repo((_) async {
        calls++;
        return http.Response(
          jsonEncode({'success': false, 'status': status, 'data': null}),
          status,
        );
      });
      await expectLater(
        repository.updateDonation(4, cacheUserId: 1, title: 'Mesa actualizada'),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
      expect(await db.select(db.localDonations).get(), before);
      expect(await db.select(db.pendingOperations).get(), isEmpty);
    });
  }

  for (final state in DonationSyncState.values.where(
    (state) => state != DonationSyncState.synced,
  )) {
    test('confirmación no sobrescribe registro $state', () async {
      await seed(state: state);
      final before = await db.select(db.localDonations).get();
      await local.storeConfirmedUpdate(cacheUserId: 1, donation: updated);
      expect(await db.select(db.localDonations).get(), before);
    });
  }

  test(
    'confirmación antigua no sobrescribe una versión más reciente',
    () async {
      await seed(serverTime: DateTime.utc(2026, 10));
      final before = await db.select(db.localDonations).get();
      await local.storeConfirmedUpdate(cacheUserId: 1, donation: updated);
      expect(await db.select(db.localDonations).get(), before);
    },
  );

  test(
    'respuesta inválida no toca caché y body vacío no envía PATCH',
    () async {
      await seed();
      final before = await db.select(db.localDonations).get();
      var calls = 0;
      final repository = repo((_) async {
        calls++;
        return http.Response('{"success":true,"data":{}}', 200);
      });
      await expectLater(
        repository.updateDonation(4, cacheUserId: 1),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 0);
      await expectLater(
        repository.updateDonation(4, cacheUserId: 1, title: 'Mesa actualizada'),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
      expect(await db.select(db.localDonations).get(), before);
    },
  );
}

const _body = {
  'id': 4,
  'titulo': 'Mesa actualizada',
  'descripcion': 'Descripción actualizada de la mesa.',
  'ciudad': 'Bogotá',
  'estado': 'PUBLICADA',
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-09-28T12:00:00Z',
  'categoria': {'id': 5, 'nombre': 'Hogar'},
  'imagenes': [
    {'id': 9, 'referencia': '/image.jpg', 'orden': 1},
  ],
};
