import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = DonationLocalDataSource(db);
  });
  tearDown(() => db.close());
  Future<int> seed({int user = 1, int remote = 731}) async {
    final id = await db
        .into(db.localDonations)
        .insert(
          LocalDonationsCompanion.insert(
            cacheUserId: user,
            clientId: 'client-$user-$remote',
            remoteId: Value(remote),
            expiresAt: DateTime.utc(2026, 10),
            syncState: DonationSyncState.synced,
            title: 'Mesa',
            city: 'Bogotá',
            categoryId: 1,
            categoryName: 'Muebles',
          ),
        );
    await db
        .into(db.localDonationImages)
        .insert(
          LocalDonationImagesCompanion.insert(
            localDonationId: id,
            sortOrder: 1,
            uploadState: ImageUploadState.remote,
            remoteUrl: const Value('/mesa.jpg'),
          ),
        );
    await db
        .into(db.localDonationMemberships)
        .insert(
          LocalDonationMembershipsCompanion.insert(
            cacheUserId: user,
            localDonationId: id,
            collectionType: DonationCollectionType.explore,
            lastSeenAt: DateTime.utc(2026, 9),
            expiresAt: DateTime.utc(2026, 10),
          ),
        );
    return id;
  }

  DonationRepository repository(
    Future<http.Response> Function(http.Request) send,
  ) => DonationRepository(
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
  test('solo tras éxito elimina Drift por remoteId y conserva otras filas/sesiones', () async {
    final id = await seed();
    expect(id, isNot(731));
    await seed(user: 2);
    await seed(remote: 732);
    final before = await db.select(db.localDonations).get();
    final response = Completer<http.Response>();
    final started = Completer<void>();
    var calls = 0;
    final repo = repository((request) {
      calls++;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/donaciones/731');
      started.complete();
      return response.future;
    });
    final deletion = repo.deleteDonation(731, cacheUserId: 1);
    await started.future;
    expect(await db.select(db.localDonations).get(), before);
    response.complete(http.Response('{"success":true,"data":{"id":731}}', 200));
    await deletion;
    expect(calls, 1);
    expect(
      (await db.select(db.localDonations).get()).map((row) => row.localId),
      isNot(contains(id)),
    );
    expect(await db.select(db.localDonations).get(), hasLength(2));
    expect(await db.select(db.localDonationImages).get(), hasLength(2));
    expect(await db.select(db.localDonationMemberships).get(), hasLength(2));
    expect(await db.select(db.pendingOperations).get(), isEmpty);
    expect(repo.wasDeleted(731), isTrue);
    // A second data source receiving an old response shares the deletion guard.
    final otherSource = DonationLocalDataSource(db);
    await otherSource.storeExplorePage(
      cacheUserId: 1,
      categoryId: null,
      page: DonationPage(
        donations: [
          DonationListItem(
            id: 731,
            titulo: 'Mesa',
            ciudad: 'Bogotá',
            estado: DonationStatus.publicada,
            createdAt: DateTime.utc(2026, 9),
            updatedAt: DateTime.utc(2026, 9),
            categoriaId: 1,
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
      ),
      syncedAt: DateTime.utc(2026, 9),
      expiresAt: DateTime.utc(2026, 10),
    );
    expect(
      (await db.select(db.localDonations).get()).where(
        (row) => row.cacheUserId == 1 && row.remoteId == 731,
      ),
      isEmpty,
    );
  });
  for (final failure in ['network', '403', '404', '409', '500', 'invalid']) {
    test(
      '$failure conserva Drift, imágenes, membresías y no crea outbox',
      () async {
        await seed();
        final before = await db.select(db.localDonations).get();
        final images = await db.select(db.localDonationImages).get();
        final memberships = await db.select(db.localDonationMemberships).get();
        var calls = 0;
        final repo = repository((_) async {
          calls++;
          if (failure == 'network') throw http.ClientException('internal');
          if (failure == 'invalid') {
            return http.Response('{"success":true,"data":{"id":1}}', 200);
          }
          final status = int.parse(failure);
          return http.Response(
            jsonEncode({'success': false, 'status': status, 'data': null}),
            status,
          );
        });
        await expectLater(
          repo.deleteDonation(731, cacheUserId: 1),
          throwsA(isA<ApiException>()),
        );
        expect(calls, 1);
        expect(await db.select(db.localDonations).get(), before);
        expect(await db.select(db.localDonationImages).get(), images);
        expect(await db.select(db.localDonationMemberships).get(), memberships);
        expect(await db.select(db.pendingOperations).get(), isEmpty);
        expect(repo.wasDeleted(731), isFalse);
      },
    );
  }
  test('la eliminación física persiste al reabrir Drift', () async {
    final dir = await Directory.systemTemp.createTemp('donapp-delete-test-');
    final file = File('${dir.path}/cache.sqlite');
    final disk = AppDatabase.forTesting(NativeDatabase(file));
    await disk
        .into(disk.localDonations)
        .insert(
          LocalDonationsCompanion.insert(
            cacheUserId: 1,
            clientId: 'stable-uuid',
            remoteId: const Value(731),
            expiresAt: DateTime.utc(2026, 10),
            syncState: DonationSyncState.synced,
            title: 'Mesa',
            city: 'Bogotá',
            categoryId: 1,
            categoryName: 'Muebles',
          ),
        );
    await DonationLocalDataSource(disk)
        .invalidateDeletedDonation(cacheUserId: 1, remoteId: 731);
    await disk.close();
    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    try {
      expect(await reopened.select(reopened.localDonations).get(), isEmpty);
    } finally {
      await reopened.close();
      await file.delete();
      await dir.delete();
    }
  });
}
