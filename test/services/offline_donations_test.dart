import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/main.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/auth_state_controller.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/services/offline_donations.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/sync_coordinator.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

import 'sync_coordinator_test.dart' show remoteDonation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final failure in ['network', 'timeout', '503', '409']) {
    test('repository persiste antes de HTTP; $failure conserva IDs y outbox', () async {
      final root = await Directory.systemTemp.createTemp('donapp-outbox-');
      final file = File('${root.path}/outbox.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var now = DateTime.utc(2026, 9, 15);
      var recovered = false;
      final bodies = <String>[];
      final images = _Images();
      final api = ApiClient(
        tokenStorage: _Tokens(),
        endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
        retryDelay: (_) => throw StateError('No GET retry for POST'),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(await db.select(db.pendingOperations).get(), hasLength(1));
          bodies.add(request.body);
          if (!recovered) {
            switch (failure) {
              case 'network':
                throw const SocketException('offline');
              case 'timeout':
                throw TimeoutException('offline');
              default:
                return http.Response('{}', int.parse(failure));
            }
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'donacion': remoteDonation().toJson()},
            }),
            201,
          );
        }),
      );
      final service = DonationService(apiClient: api);
      final local = DonationLocalDataSource(db, imagesDirectory: root);
      final repository = DonationRepository(
        local,
        DonationRemoteDataSource(service, const CategoryService()),
      );
      final operation = await repository.enqueueCreation(
        cacheUserId: 1,
        city: 'Bogotá',
        title: 'Mesa para donar',
        description: 'Mesa de madera en buen estado para donar.',
        category: const Category(id: 4, nombre: 'Muebles', descripcion: null),
        images: [
          XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'one.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
      );
      expect(bodies, isEmpty);
      expect(operation.state, PendingOperationState.pending);
      final donation = await db.select(db.localDonations).getSingle();
      final image = await db.select(db.localDonationImages).getSingle();
      expect(donation.clientId, operation.entityClientId);
      expect(await File(image.managedLocalPath!).readAsBytes(), [1, 2, 3]);
      var sync = SyncCoordinator(
        database: db,
        donationService: service,
        imageUploadService: images,
        clock: () => now,
      );
      await sync.processPending(1);
      expect(
        bodies,
        hasLength(1),
        reason: 'ApiClient must not retry the write',
      );
      final failed = (await db.pendingOperationsDao.findByOperationId(
        operation.operationId,
      ))!;
      expect(
        failed.state,
        failure == '409'
            ? PendingOperationState.failedPermanent
            : PendingOperationState.retryWait,
      );
      expect(failed.operationId, operation.operationId);
      expect(failed.entityClientId, operation.entityClientId);
      expect(await File(image.managedLocalPath!).exists(), isTrue);
      await sync.processPending(1);
      expect(bodies, hasLength(1), reason: 'backoff or permanent conflict');
      await sync.shutdown();
      await db.close();

      // A new connection and coordinator continue from the same disk database.
      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(
        (await db.select(db.localDonations).getSingle()).clientId,
        donation.clientId,
      );
      expect(
        (await db.select(db.pendingOperations).getSingle()).operationId,
        operation.operationId,
      );
      recovered = true;
      now = now.add(const Duration(seconds: 5));
      sync = SyncCoordinator(
        database: db,
        donationService: service,
        imageUploadService: images,
        clock: () => now,
      );
      await sync.processPending(1);
      final result = await db.select(db.pendingOperations).getSingle();
      if (failure == '409') {
        expect(result.state, PendingOperationState.failedPermanent);
        expect(result.lastErrorCode, 'CONFLICT');
        expect(bodies, hasLength(1));
      } else {
        expect(result.state, PendingOperationState.completed);
        expect(bodies, hasLength(2));
        expect(bodies[1], bodies[0]);
        expect(jsonDecode(bodies.last)['clientId'], donation.clientId);
        expect((await db.select(db.localDonations).getSingle()).remoteId, 42);
        expect(await File(image.managedLocalPath!).exists(), isFalse);
        expect(
          images.calls,
          1,
          reason: 'persisted image URL is reused after restart',
        );
      }
      await sync.shutdown();
      await db.close();
      await root.delete(recursive: true);
    });
  }

  for (final trigger in ['foreground', 'timer']) {
    test(
      'autenticación y $trigger usan un solo coordinador sin duplicar envío',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final root = await Directory.systemTemp.createTemp('donapp-runtime-');
        final local = DonationLocalDataSource(db, imagesDirectory: root);
        await local.enqueueCreation(
          cacheUserId: 1,
          city: 'Bogotá',
          title: 'Mesa para donar',
          description: 'Mesa de madera en buen estado para donar.',
          category: const Category(id: 4, nombre: 'Muebles', descripcion: null),
          images: [XFile.fromData(Uint8List(3), name: 'one.jpg')],
        );
        var now = DateTime.utc(2026, 9, 15);
        var calls = 0;
        var opens = 0;
        final started = Completer<void>();
        final response = Completer<http.Response>();
        final service = DonationService(
          apiClient: ApiClient(
            tokenStorage: _Tokens(),
            endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
            client: MockClient((_) async {
              calls++;
              if (calls == 1) {
                started.complete();
                return response.future;
              }
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {'donacion': remoteDonation().toJson()},
                }),
                201,
              );
            }),
          ),
        );
        final auth = AuthStateController();
        final offline = OfflineDonations(
          authState: auth,
          databaseFactory: () {
            opens++;
            return db;
          },
          donationService: service,
          imageUploadService: _Images(),
          clock: () => now,
        );
        expect(opens, 0);
        auth.authenticated(_profile);
        await started.future;
        auth.authenticated(_profile);
        offline.didChangeAppLifecycleState(AppLifecycleState.resumed);
        final running = offline.syncNow();
        response.complete(http.Response('{}', 503));
        await running;
        expect(calls, 1);
        expect(opens, 1);
        if (trigger == 'foreground') {
          offline.didChangeAppLifecycleState(AppLifecycleState.paused);
          now = now.add(const Duration(seconds: 5));
          offline.didChangeAppLifecycleState(AppLifecycleState.resumed);
        } else {
          now = now.add(const Duration(seconds: 5));
          // Real timer, only once at the persisted deadline; no polling.
          await Future<void>.delayed(const Duration(milliseconds: 5200));
          expect(
            calls,
            2,
            reason: 'the timer must trigger without manual sync',
          );
        }
        await offline.syncNow();
        expect(calls, 2);
        expect(
          (await db.select(db.pendingOperations).getSingle()).state,
          PendingOperationState.completed,
        );
        await offline.syncNow();
        expect(calls, 2);
        await offline.dispose();
        auth.dispose();
        await root.delete(recursive: true);
      },
    );
  }

  testWidgets('DonApp compone el runtime y lo activa al restaurar sesión', (
    tester,
  ) async {
    var opens = 0;
    late OfflineDonations offline;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      DonApp(
        sessionCoordinator: _Session(),
        offlineFactory: (auth) {
          return offline = OfflineDonations(
            authState: auth,
            databaseFactory: () {
              opens++;
              return db;
            },
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(opens, 1);
    expect(offline.repository, isNotNull);
    await tester.runAsync(offline.syncNow);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(offline.dispose);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}

class _Tokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token';
}

class _Images extends ImageUploadService {
  int calls = 0;
  @override
  Future<List<String>> uploadImages(List<XFile> images) async {
    calls++;
    expect(await File(images.single.path).exists(), isTrue);
    return ['https://images.test/remote.jpg'];
  }
}

class _Session extends SessionCoordinator {
  @override
  Future<SessionRestoreResult> restoreSession() async =>
      SessionRestoreResult.valid(_profile);
}

final _profile = UserProfile(
  id: 1,
  nombreCompleto: 'Ana Uno',
  nombreVisible: 'Ana',
  email: 'ana@test.com',
  ciudad: 'Bogotá',
  telefono: null,
  fotoPerfil: null,
  activo: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  rol: const ProfileRole(codigo: 'USUARIO', nombre: 'Usuario'),
);
