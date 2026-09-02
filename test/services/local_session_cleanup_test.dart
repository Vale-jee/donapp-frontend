import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/database_key_storage.dart';
import 'package:donapp_mobile/services/local_session_cleanup.dart';

void main() {
  late Directory temporaryDirectory;
  late File databaseFile;
  late Directory managedImagesDirectory;
  late File managedImage;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      DatabaseKeyStorage.storageKey: base64UrlEncode(List<int>.filled(32, 1)),
    });
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'donapp-logout-',
    );
    databaseFile = File('${temporaryDirectory.path}/donapp.sqlite');
    managedImagesDirectory = Directory(
      '${temporaryDirectory.path}/${LocalSessionCleanup.managedImagesDirectoryName}',
    );
    await managedImagesDirectory.create();
    managedImage = File('${managedImagesDirectory.path}/pending.jpg');
    await managedImage.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('elimina base, sidecars, imágenes privadas y clave', () async {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      await File('${databaseFile.path}$suffix').writeAsString('private');
    }
    final events = <String>[];
    final cleanup = LocalSessionCleanup(
      shutdownSync: () async => events.add('sync'),
      managedImagePaths: () async => {managedImage.path},
      closeDatabases: () async => events.add('database'),
      databaseFile: () async => databaseFile,
      managedImagesDirectory: () async => managedImagesDirectory,
    );

    await cleanup.clear();

    expect(events, ['sync', 'database']);
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      expect(await File('${databaseFile.path}$suffix').exists(), isFalse);
    }
    expect(await managedImage.exists(), isFalse);
    expect(await managedImagesDirectory.exists(), isFalse);
    expect(
      await const FlutterSecureStorage().read(
        key: DatabaseKeyStorage.storageKey,
      ),
      isNull,
    );
  });

  test('una apertura posterior crea base vacía y una clave nueva', () async {
    final oldKey = await DatabaseKeyStorage().getOrCreateKey();
    final oldDatabase = AppDatabase.forTesting(NativeDatabase(databaseFile));
    await oldDatabase.localCacheDao.putAuthenticatedUser(
      LocalAuthenticatedUsersCompanion.insert(
        userId: const Value(1),
        nombreVisible: 'Ana',
        city: 'Bogotá',
        lastValidatedAt: DateTime.utc(2026, 9, 2),
        offlineSessionValidUntil: DateTime.utc(2026, 9, 3),
      ),
    );
    await oldDatabase.close();

    await LocalSessionCleanup(
      shutdownSync: () async {},
      managedImagePaths: () async => {},
      closeDatabases: () async {},
      databaseFile: () async => databaseFile,
      managedImagesDirectory: () async => managedImagesDirectory,
    ).clear();

    final newKey = await DatabaseKeyStorage().getOrCreateKey();
    expect(newKey, isNot(orderedEquals(oldKey)));
    final newDatabase = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(newDatabase.close);
    expect(
      await newDatabase.select(newDatabase.localAuthenticatedUsers).get(),
      isEmpty,
    );
    expect(
      await newDatabase.select(newDatabase.pendingOperations).get(),
      isEmpty,
    );
  });
}
