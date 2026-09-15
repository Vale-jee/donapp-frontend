import 'dart:async';
import 'dart:io';

import 'package:donapp_mobile/services/read_cancellation.dart';

import 'package:donapp_mobile/services/api_exception.dart';

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

  test(
    'descarga aborta transporte y limpia temporal al cancelar propietario',
    () async {
      final transport = _AbortCacheClient();
      final cache = RemoteImageCache(
        client: transport,
        cacheDirectory: () async => directory,
      );
      final temporary = File(p.join(directory.path, 'u1_d2_i3.image.download'));
      await temporary.writeAsBytes([9]);
      final cancellation = ReadCancellation();
      final expectation = expectLater(
        cancellation.run(
          () => cache.cache(
            cacheUserId: 1,
            donationId: 2,
            imageId: 3,
            reference: 'https://images.test/a.jpg',
          ),
        ),
        throwsA(isA<RequestCancelled>()),
      );
      await transport.started.future;
      cancellation.cancel();
      await expectation;
      expect(transport.aborted, isTrue);
      expect(await directory.list().toList(), isEmpty);
    },
  );

  for (final scenario in [
    (400, ApiErrorType.validation),
    (401, ApiErrorType.authentication),
    (403, ApiErrorType.forbidden),
    (404, ApiErrorType.notFound),
    (409, ApiErrorType.conflict),
    (422, ApiErrorType.validation),
    (429, ApiErrorType.rateLimited),
    (500, ApiErrorType.server),
    (502, ApiErrorType.server),
    (503, ApiErrorType.server),
    (504, ApiErrorType.server),
    (200, ApiErrorType.unexpectedResponse),
  ]) {
    test(
      'descarga ${scenario.$1} conserva status y tipo sin body JSON',
      () async {
        final cache = RemoteImageCache(
          client: MockClient((_) async => http.Response('', scenario.$1)),
          cacheDirectory: () async => directory,
        );
        await expectLater(
          cache.cache(
            cacheUserId: 1,
            donationId: 2,
            imageId: 3,
            reference: 'https://images.test/photo.jpg',
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', scenario.$2)
                .having((e) => e.statusCode, 'status', scenario.$1),
          ),
        );
        expect(await directory.list().toList(), isEmpty);
      },
    );
  }

  for (final error in [
    const SocketException('private host'),
    http.ClientException('private host'),
  ]) {
    test('descarga clasifica ${error.runtimeType} como red', () async {
      final cache = RemoteImageCache(
        client: MockClient((_) async => throw error),
        cacheDirectory: () async => directory,
      );
      await expectLater(
        cache.cache(
          cacheUserId: 1,
          donationId: 2,
          imageId: 3,
          reference: 'https://images.test/photo.jpg',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.network)
              .having((e) => e.message, 'message', isNot(contains('private'))),
        ),
      );
    });
  }

  test('referencia invalida se clasifica antes de descargar', () async {
    final cache = RemoteImageCache(
      client: MockClient((_) async {
        fail('No debe descargar una referencia invalida');
      }),
      cacheDirectory: () async => directory,
    );
    await expectLater(
      cache.cache(cacheUserId: 1, donationId: 2, imageId: 3, reference: ''),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          ApiErrorType.validation,
        ),
      ),
    );
  });

  for (final headersReceived in [false, true]) {
    test(
      'timeout de descarga limpia temporal (cabeceras=$headersReceived)',
      () async {
        final body = StreamController<List<int>>();
        final headers = Completer<http.StreamedResponse>();
        final temporary = File(
          p.join(directory.path, 'u1_d2_i3.image.download'),
        );
        await temporary.writeAsBytes([9]);
        final cache = RemoteImageCache(
          client: _StreamingClient(
            () => headersReceived
                ? Future.value(http.StreamedResponse(body.stream, 200))
                : headers.future,
          ),
          timeout: const Duration(milliseconds: 10),
          cacheDirectory: () async => directory,
        );
        await expectLater(
          cache.cache(
            cacheUserId: 1,
            donationId: 2,
            imageId: 3,
            reference: 'https://images.test/photo.jpg',
          ),
          throwsA(
            isA<ApiException>()
                .having((error) => error.type, 'type', ApiErrorType.timeout)
                .having(
                  (error) => error.message,
                  'message',
                  contains('descarga de la imagen'),
                ),
          ),
        );
        expect(await temporary.exists(), isFalse);
        expect(
          await File(p.join(directory.path, 'u1_d2_i3.image')).exists(),
          isFalse,
        );
        if (!headersReceived) {
          headers.complete(http.StreamedResponse(body.stream, 200));
        }
        await body.close();
        // A late transport completion must not publish an expired download.
        expect(await directory.list().toList(), isEmpty);
      },
    );
  }

  test('propaga timeout del transporte como error comprensible', () async {
    final cache = RemoteImageCache(
      client: MockClient((_) async => throw TimeoutException('internal')),
      cacheDirectory: () async => directory,
    );
    await expectLater(
      cache.cache(
        cacheUserId: 1,
        donationId: 2,
        imageId: 3,
        reference: 'https://images.test/photo.jpg',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.timeout,
        ),
      ),
    );
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

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.response);
  final Future<http.StreamedResponse> Function() response;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => response();
}

class _AbortCacheClient extends http.BaseClient {
  final started = Completer<void>();
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    started.complete();
    return (request as http.Abortable).abortTrigger!.then((_) {
      aborted = true;
      throw http.RequestAbortedException(request.url);
    });
  }
}
