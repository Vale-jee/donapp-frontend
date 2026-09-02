import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:donapp_mobile/data/local/app_database.dart';

void main() {
  final key = Uint8List.fromList(List<int>.generate(32, (index) => index + 31));

  test('migra acumulativamente un archivo SQLCipher v1 a v3', () async {
    final directory = await Directory.systemTemp.createTemp(
      'donapp-migration-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}migration.sqlite',
    );
    try {
      _createEncryptedV1(file, key);

      final db = AppDatabase.forTesting(openEncryptedNativeDatabase(file, key));
      expect(db.schemaVersion, 3);
      expect(await db.select(db.localAuthenticatedUsers).get(), hasLength(1));
      expect(await db.select(db.localCategories).get(), hasLength(1));
      final donations = await db.select(db.localDonations).get();
      expect(donations, hasLength(1));
      expect(donations.single.title, 'Mesa de comedor');
      expect(donations.single.lastAccessedAt, isNull);
      expect(await db.select(db.localDonationImages).get(), hasLength(1));
      expect(await db.select(db.localDonationMemberships).get(), hasLength(1));
      expect(await db.select(db.localRequests).get(), hasLength(1));
      expect(await db.select(db.localCollectionMetadata).get(), hasLength(1));
      expect(await db.select(db.pendingOperations).get(), isEmpty);

      final columns = await db
          .customSelect('PRAGMA table_info(local_donations)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        contains('last_accessed_at'),
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      final indexes = await db
          .customSelect('PRAGMA index_list(local_donations)')
          .get();
      expect(
        indexes.where((row) => row.read<int>('unique') == 1),
        hasLength(2),
      );
      final version = await db
          .customSelect('PRAGMA cipher_version')
          .getSingle();
      expect(version.data.values.single.toString(), isNotEmpty);
      await db.close();

      final reopened = AppDatabase.forTesting(
        openEncryptedNativeDatabase(file, key),
      );
      expect(
        await reopened.select(reopened.localDonations).get(),
        hasLength(1),
      );
      await reopened.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('migra SQLCipher v2 a v3 y preserva todos los datos', () async {
    final directory = await Directory.systemTemp.createTemp(
      'donapp-migration-v2-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}migration.sqlite',
    );
    try {
      _createEncryptedV2(file, key);

      final db = AppDatabase.forTesting(openEncryptedNativeDatabase(file, key));
      try {
        expect(db.schemaVersion, 3);
        expect(await db.select(db.localAuthenticatedUsers).get(), hasLength(1));
        expect(await db.select(db.localCategories).get(), hasLength(1));
        expect(await db.select(db.localDonations).get(), hasLength(1));
        expect(await db.select(db.localDonationImages).get(), hasLength(1));
        expect(
          await db.select(db.localDonationMemberships).get(),
          hasLength(1),
        );
        expect(await db.select(db.localRequests).get(), hasLength(1));
        expect(await db.select(db.localCollectionMetadata).get(), hasLength(1));
        expect(await db.select(db.pendingOperations).get(), isEmpty);

        final indexes = await db
            .customSelect('PRAGMA index_list(pending_operations)')
            .get();
        expect(
          indexes.map((row) => row.read<String>('name')),
          containsAll(<String>[
            'pending_operations_processable_idx',
            'pending_operations_entity_idx',
          ]),
        );
        expect(
          indexes.where((row) => row.read<int>('unique') == 1),
          hasLength(1),
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        final cipherVersion = await db
            .customSelect('PRAGMA cipher_version')
            .getSingle();
        expect(cipherVersion.data.values.single.toString(), isNotEmpty);
      } finally {
        await db.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'una instalación nueva v3 crea directamente el esquema completo',
    () async {
      final directory = await Directory.systemTemp.createTemp('donapp-v3-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}fresh.sqlite',
      );
      try {
        final db = AppDatabase.forTesting(
          openEncryptedNativeDatabase(file, key),
        );
        final tables = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((row) => row.read<String>('name')),
          containsAll(<String>[
            'local_authenticated_users',
            'local_categories',
            'local_donations',
            'local_donation_memberships',
            'local_donation_images',
            'local_requests',
            'local_collection_metadata',
            'pending_operations',
          ]),
        );
        final columns = await db
            .customSelect('PRAGMA table_info(local_donations)')
            .get();
        expect(
          columns.map((row) => row.read<String>('name')),
          contains('last_accessed_at'),
        );
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          3,
        );
        await db.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

void _createEncryptedV1(File file, Uint8List key) {
  final database = sqlite.sqlite3.open(file.path);
  final hexKey = key
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  database.execute('PRAGMA key = "x\'$hexKey\'"');
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('''
    CREATE TABLE local_authenticated_users (user_id INTEGER NOT NULL PRIMARY KEY, nombre_visible TEXT NOT NULL, city TEXT NOT NULL, last_validated_at INTEGER NOT NULL, offline_session_valid_until INTEGER NOT NULL);
    CREATE TABLE local_categories (remote_id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL, description TEXT NULL, last_synced_at INTEGER NOT NULL, expires_at INTEGER NOT NULL);
    CREATE TABLE local_donations (local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, cache_user_id INTEGER NOT NULL, client_id TEXT NOT NULL, remote_id INTEGER NULL, last_synced_at INTEGER NULL, expires_at INTEGER NOT NULL, detail_expires_at INTEGER NULL, sync_state TEXT NOT NULL, locally_deleted INTEGER NOT NULL DEFAULT 0 CHECK (locally_deleted IN (0, 1)), title TEXT NOT NULL, description TEXT NULL, city TEXT NOT NULL, status TEXT NULL, category_id INTEGER NOT NULL, category_name TEXT NOT NULL, main_image_url TEXT NULL, image_count INTEGER NOT NULL DEFAULT 0, created_at INTEGER NULL, server_updated_at INTEGER NULL, UNIQUE (cache_user_id, client_id), UNIQUE (cache_user_id, remote_id));
    CREATE TABLE local_donation_memberships (cache_user_id INTEGER NOT NULL, local_donation_id INTEGER NOT NULL REFERENCES local_donations (local_id) ON DELETE CASCADE, collection_type TEXT NOT NULL, last_seen_at INTEGER NOT NULL, expires_at INTEGER NOT NULL, PRIMARY KEY (cache_user_id, local_donation_id, collection_type));
    CREATE TABLE local_donation_images (local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, local_donation_id INTEGER NOT NULL REFERENCES local_donations (local_id) ON DELETE CASCADE, remote_image_id INTEGER NULL, remote_url TEXT NULL, managed_local_path TEXT NULL, sort_order INTEGER NOT NULL, mime_type TEXT NULL, size_bytes INTEGER NULL, upload_state TEXT NOT NULL);
    CREATE TABLE local_requests (cache_user_id INTEGER NOT NULL, remote_id INTEGER NOT NULL, collection_type TEXT NOT NULL, detail_cached INTEGER NOT NULL DEFAULT 0 CHECK (detail_cached IN (0, 1)), status TEXT NOT NULL, cancellation_cause TEXT NULL, accepted_at INTEGER NULL, rejected_at INTEGER NULL, cancelled_at INTEGER NULL, created_at INTEGER NOT NULL, server_updated_at INTEGER NOT NULL, donation_remote_id INTEGER NOT NULL, donation_title TEXT NOT NULL, donation_status TEXT NOT NULL, donation_main_image_url TEXT NULL, participant_remote_id INTEGER NOT NULL, participant_visible_name TEXT NOT NULL, participant_city TEXT NOT NULL, participant_profile_photo_url TEXT NULL, last_synced_at INTEGER NOT NULL, expires_at INTEGER NOT NULL, PRIMARY KEY (cache_user_id, remote_id, collection_type));
    CREATE TABLE local_collection_metadata (cache_user_id INTEGER NOT NULL, collection_key TEXT NOT NULL, last_synced_at INTEGER NOT NULL, expires_at INTEGER NOT NULL, PRIMARY KEY (cache_user_id, collection_key));
  ''');
  const timestamp = 1788350400;
  database.execute(
    "INSERT INTO local_authenticated_users VALUES (1, 'Ana', 'Bogotá', $timestamp, $timestamp + 86400)",
  );
  database.execute(
    "INSERT INTO local_categories VALUES (7, 'Hogar', NULL, $timestamp, $timestamp + 3600)",
  );
  database.execute(
    "INSERT INTO local_donations (cache_user_id, client_id, remote_id, last_synced_at, expires_at, sync_state, title, city, status, category_id, category_name, image_count) VALUES (1, 'client-v1', 10, $timestamp, $timestamp + 3600, 'synced', 'Mesa de comedor', 'Bogotá', 'PUBLICADA', 7, 'Hogar', 1)",
  );
  database.execute(
    "INSERT INTO local_donation_images (local_donation_id, remote_image_id, remote_url, sort_order, upload_state) VALUES (1, 20, 'https://example.test/mesa.jpg', 1, 'remote')",
  );
  database.execute(
    "INSERT INTO local_donation_memberships VALUES (1, 1, 'explore', $timestamp, $timestamp + 3600)",
  );
  database.execute(
    "INSERT INTO local_requests (cache_user_id, remote_id, collection_type, status, created_at, server_updated_at, donation_remote_id, donation_title, donation_status, participant_remote_id, participant_visible_name, participant_city, last_synced_at, expires_at) VALUES (1, 50, 'sent', 'PENDIENTE', $timestamp, $timestamp, 10, 'Mesa de comedor', 'PUBLICADA', 2, 'Luis', 'Cali', $timestamp, $timestamp + 3600)",
  );
  database.execute(
    "INSERT INTO local_collection_metadata VALUES (1, 'explore', $timestamp, $timestamp + 3600)",
  );
  database.execute('PRAGMA user_version = 1');
  database.close();
}

void _createEncryptedV2(File file, Uint8List key) {
  _createEncryptedV1(file, key);
  final database = sqlite.sqlite3.open(file.path);
  final hexKey = key
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  database.execute('PRAGMA key = "x\'$hexKey\'"');
  database.execute(
    'ALTER TABLE local_donations ADD COLUMN last_accessed_at INTEGER NULL',
  );
  database.execute('PRAGMA user_version = 2');
  database.close();
}
