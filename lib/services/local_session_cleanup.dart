import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/app_database.dart';
import '../data/local/database_key_storage.dart';
import 'remote_image_cache.dart';
import 'sync_coordinator.dart';

class LocalSessionCleanup {
  LocalSessionCleanup({
    DatabaseKeyStorage? keyStorage,
    Future<void> Function()? shutdownSync,
    Future<Set<String>> Function()? managedImagePaths,
    Future<void> Function()? closeDatabases,
    Future<File> Function()? databaseFile,
    Future<Directory> Function()? managedImagesDirectory,
    Future<Directory> Function()? cachedImagesDirectory,
  }) : _keyStorage = keyStorage ?? DatabaseKeyStorage(),
       _shutdownSync = shutdownSync ?? SyncCoordinator.shutdownAll,
       _managedImagePaths =
           managedImagePaths ?? AppDatabase.managedLocalImagePaths,
       _closeDatabases = closeDatabases ?? AppDatabase.closeOpenInstances,
       _databaseFile = databaseFile ?? AppDatabase.databaseFile,
       _managedImagesDirectory =
           managedImagesDirectory ?? _defaultManagedImagesDirectory,
       _cachedImagesDirectory =
           cachedImagesDirectory ?? RemoteImageCache.defaultDirectory;

  static const managedImagesDirectoryName = 'pending_donation_images';
  final DatabaseKeyStorage _keyStorage;
  final Future<void> Function() _shutdownSync;
  final Future<Set<String>> Function() _managedImagePaths;
  final Future<void> Function() _closeDatabases;
  final Future<File> Function() _databaseFile;
  final Future<Directory> Function() _managedImagesDirectory;
  final Future<Directory> Function() _cachedImagesDirectory;

  /// Best-effort cleanup: every stage runs even if an earlier deletion fails.
  Future<void> clear() async {
    await _bestEffort(_shutdownSync);
    var imagePaths = <String>{};
    await _bestEffort(() async {
      imagePaths = await _managedImagePaths();
    });
    await _bestEffort(_closeDatabases);

    File? databaseFile;
    await _bestEffort(() async {
      databaseFile = await _databaseFile();
    });
    if (databaseFile case final file?) {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        await _bestEffort(() => _deleteFile(File('${file.path}$suffix')));
      }
    }

    for (final path in imagePaths) {
      await _bestEffort(() => _deleteFile(File(path)));
    }
    await _bestEffort(() async {
      final directory = await _managedImagesDirectory();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await _bestEffort(() async {
      final directory = await _cachedImagesDirectory();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await _bestEffort(_keyStorage.deleteKey);
  }
}

Future<Directory> _defaultManagedImagesDirectory() async {
  final support = await getApplicationSupportDirectory();
  return Directory(
    p.join(support.path, LocalSessionCleanup.managedImagesDirectoryName),
  );
}

Future<void> _deleteFile(File file) async {
  if (await file.exists()) await file.delete();
}

Future<void> _bestEffort(Future<void> Function() action) async {
  try {
    await action();
  } on Object {
    // Logout must continue to secrets and tokens without exposing local paths.
  }
}
