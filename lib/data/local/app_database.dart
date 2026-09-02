import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/local_cache_dao.dart';
import 'daos/pending_operations_dao.dart';
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
    PendingOperations,
  ],
  daos: [LocalCacheDao, PendingOperationsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({DatabaseKeyStorage? keyStorage})
    : super(_openDatabase(keyStorage ?? DatabaseKeyStorage())) {
    _openInstances.add(this);
  }
  AppDatabase.forTesting(super.executor);

  static final Set<AppDatabase> _openInstances = {};

  static Future<File> databaseFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'donapp.sqlite'));
  }

  static Future<Set<String>> managedLocalImagePaths() async {
    final paths = <String>{};
    for (final database in List<AppDatabase>.of(_openInstances)) {
      final rows = await database.select(database.localDonationImages).get();
      paths.addAll(rows.map((row) => row.managedLocalPath).whereType<String>());
    }
    return paths;
  }

  static Future<void> closeOpenInstances() async {
    for (final database in List<AppDatabase>.of(_openInstances)) {
      await database.close();
    }
  }

  @override
  Future<void> close() {
    _openInstances.remove(this);
    return super.close();
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(localDonations, localDonations.lastAccessedAt);
      }
      if (from < 3) {
        await migrator.createTable(pendingOperations);
        await migrator.createIndex(pendingOperationsProcessableIdx);
        await migrator.createIndex(pendingOperationsEntityIdx);
      }
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

LazyDatabase _openDatabase(DatabaseKeyStorage keyStorage) =>
    LazyDatabase(() async {
      final key = await keyStorage.getOrCreateKey();
      return openEncryptedNativeDatabase(await AppDatabase.databaseFile(), key);
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
