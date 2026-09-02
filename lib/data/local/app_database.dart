import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/local_cache_dao.dart';
import 'database_key_storage.dart';
import 'tables/local_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalAuthenticatedUsers,
    LocalCategories,
    LocalDonations,
    LocalDonationMemberships,
    LocalDonationImages,
    LocalRequests,
    LocalCollectionMetadata,
  ],
  daos: [LocalCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({DatabaseKeyStorage? keyStorage})
    : super(_openDatabase(keyStorage ?? DatabaseKeyStorage()));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

LazyDatabase _openDatabase(DatabaseKeyStorage keyStorage) =>
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      final key = await keyStorage.getOrCreateKey();
      return openEncryptedNativeDatabase(
        File(p.join(directory.path, 'donapp.sqlite')),
        key,
      );
    });

NativeDatabase openEncryptedNativeDatabase(File file, Uint8List key) {
  final hexKey = key
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return NativeDatabase(
    file,
    setup: (database) {
      database.execute('PRAGMA key = "x\'$hexKey\'"');
      final cipherVersion = database.select('PRAGMA cipher_version');
      if (cipherVersion.isEmpty ||
          cipherVersion.first.values.first?.toString().trim().isEmpty !=
              false) {
        throw StateError('SQLCipher no está disponible en la conexión local.');
      }
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}
