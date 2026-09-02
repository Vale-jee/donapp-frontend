import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/app_database.dart';

void main() {
  test(
    'SQLCipher abre, persiste y rechaza claves incorrectas o ausentes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'donapp-sqlcipher-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}encrypted.sqlite',
      );
      final key = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 1),
      );
      final wrongKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 2),
      );
      try {
        final first = AppDatabase.forTesting(
          openEncryptedNativeDatabase(file, key),
        );
        await first.customStatement(
          'CREATE TABLE cipher_probe (value TEXT NOT NULL)',
        );
        await first.customStatement(
          "INSERT INTO cipher_probe VALUES ('persisted')",
        );
        final version = await first
            .customSelect('PRAGMA cipher_version')
            .getSingle();
        expect(version.data.values.single.toString(), isNotEmpty);
        await first.close();

        final reopened = AppDatabase.forTesting(
          openEncryptedNativeDatabase(file, key),
        );
        expect(
          (await reopened
                  .customSelect('SELECT value FROM cipher_probe')
                  .getSingle())
              .read<String>('value'),
          'persisted',
        );
        await reopened.close();

        final wrong = AppDatabase.forTesting(
          openEncryptedNativeDatabase(file, wrongKey),
        );
        await expectLater(
          wrong.customSelect('SELECT name FROM sqlite_master').get(),
          throwsA(anything),
        );
        await wrong.close();

        final plain = NativeDatabase(file);
        final plainDb = AppDatabase.forTesting(plain);
        await expectLater(
          plainDb.customSelect('SELECT name FROM sqlite_master').get(),
          throwsA(anything),
        );
        await plainDb.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
