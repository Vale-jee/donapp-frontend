import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyStorage {
  DatabaseKeyStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'donapp_local_database_key_v1';
  final FlutterSecureStorage _storage;

  Future<Uint8List> getOrCreateKey() async {
    final existing = await _storage.read(key: storageKey);
    if (existing != null) {
      final decoded = base64Url.decode(existing);
      if (decoded.length != 32) {
        throw StateError('La clave local almacenada no tiene 32 bytes.');
      }
      return Uint8List.fromList(decoded);
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256), growable: false),
    );
    await _storage.write(key: storageKey, value: base64UrlEncode(key));
    return key;
  }

  Future<void> deleteKey() => _storage.delete(key: storageKey);
}
