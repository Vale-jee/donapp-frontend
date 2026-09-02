import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import 'package:donapp_mobile/services/remote_image_cache.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('donapp-image-cache-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('descarga en almacenamiento privado con nombre controlado', () async {
    final cache = RemoteImageCache(
      client: MockClient((_) async => http.Response.bytes([1, 2, 3], 200)),
      cacheDirectory: () async => directory,
    );

    final path = await cache.cache(
      cacheUserId: 7,
      donationId: 11,
      imageId: 13,
      reference: 'https://images.test/photo.jpg?temporary=token',
    );

    expect(File(path).parent.path, directory.path);
    expect(File(path).uri.pathSegments.last, 'u7_d11_i13.image');
    expect(await File(path).readAsBytes(), [1, 2, 3]);
    expect(path, isNot(contains('temporary')));
  });

  test('reutiliza la copia aunque cambie la URL temporal', () async {
    var requests = 0;
    final cache = RemoteImageCache(
      client: MockClient((_) async {
        requests++;
        return http.Response.bytes([4, 5, 6], 200);
      }),
      cacheDirectory: () async => directory,
    );
    final first = await cache.cache(
      cacheUserId: 1,
      donationId: 2,
      imageId: 3,
      reference: 'https://images.test/photo.jpg?token=one',
    );
    final second = await cache.cache(
      cacheUserId: 1,
      donationId: 2,
      imageId: 3,
      reference: 'https://images.test/photo.jpg?token=two',
    );

    expect(second, first);
    expect(requests, 1);
  });

  test('un fallo no elimina una copia existente', () async {
    final existing = File(p.join(directory.path, 'u1_d2_i3.image'));
    await existing.writeAsBytes([9]);
    final cache = RemoteImageCache(
      client: MockClient((_) async => throw const SocketException('offline')),
      cacheDirectory: () async => directory,
    );

    final path = await cache.cache(
      cacheUserId: 1,
      donationId: 2,
      imageId: 3,
      reference: 'https://images.test/photo.jpg',
    );

    expect(path, existing.path);
    expect(await existing.readAsBytes(), [9]);
  });
}
