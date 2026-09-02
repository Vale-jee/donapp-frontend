import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Set<String>> columns(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test(
    'el perfil local contiene únicamente la identidad offline mínima',
    () async {
      expect(await columns('local_authenticated_users'), {
        'user_id',
        'nombre_visible',
        'city',
        'last_validated_at',
        'offline_session_valid_until',
      });
    },
  );

  test('SQLite excluye datos personales y secretos de autenticación', () async {
    final schema = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' AND sql IS NOT NULL",
        )
        .get();
    final normalized = schema
        .map((row) => row.read<String>('sql').toLowerCase())
        .join('\n');

    for (final forbidden in [
      'email',
      'telefono',
      'password',
      'access_token',
      'refresh_token',
      'database_key',
      'sqlcipher_key',
    ]) {
      expect(normalized, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'pending_operations conserva solo estado operativo sanitizado',
    () async {
      expect(await columns('pending_operations'), {
        'local_id',
        'operation_id',
        'cache_user_id',
        'entity_type',
        'entity_client_id',
        'operation_type',
        'state',
        'attempt_count',
        'created_at',
        'next_attempt_at',
        'last_attempt_at',
        'last_error_code',
      });
    },
  );

  test('las imágenes locales no contienen bytes, base64 ni EXIF', () async {
    final imageColumns = await columns('local_donation_images');

    expect(imageColumns, containsAll({'remote_url', 'managed_local_path'}));
    for (final forbidden in ['bytes', 'base64', 'blob', 'exif']) {
      expect(imageColumns, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
