import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('una subida móvil de 60 segundos termina correctamente', (
    tester,
  ) async {
    var completed = false;
    final response = Completer<http.Response>();
    final service = _service(uploadHandler: (_) => response.future);
    final upload = service.uploadImages([_image('a.jpg')]).then((value) {
      completed = true;
      return value;
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));
    expect(completed, isFalse);
    response.complete(
      http.Response(
        jsonEncode({'secure_url': 'https://images.test/a.jpg'}),
        200,
      ),
    );
    await tester.pump();
    expect(await upload, ['https://images.test/a.jpg']);
    expect(completed, isTrue);
  });

  for (final scenario in [
    (
      400,
      'Invalid image file',
      ApiErrorType.validation,
      CloudinaryFailure.invalidImage,
    ),
    (
      401,
      'Invalid Signature',
      ApiErrorType.configuration,
      CloudinaryFailure.invalidSignature,
    ),
    (
      401,
      'Unknown API_key',
      ApiErrorType.configuration,
      CloudinaryFailure.invalidApiKey,
    ),
    (403, 'Forbidden', ApiErrorType.configuration, CloudinaryFailure.rejected),
    (408, '', ApiErrorType.timeout, CloudinaryFailure.timeout),
    (429, '', ApiErrorType.rateLimited, CloudinaryFailure.rateLimited),
    (500, '', ApiErrorType.server, CloudinaryFailure.unavailable),
    (503, '', ApiErrorType.server, CloudinaryFailure.unavailable),
  ]) {
    test(
      'clasifica Cloudinary ${scenario.$1} ${scenario.$2} sin secretos',
      () async {
        final service = _service(
          uploadHandler: (_) async => http.Response(
            jsonEncode({
              'error': {
                'message': '${scenario.$2} signed-value public-key access-real',
              },
            }),
            scenario.$1,
          ),
        );
        await expectLater(
          service.uploadImages([_image('a.jpg')]),
          throwsA(
            isA<CloudinaryUploadException>()
                .having((e) => e.statusCode, 'status', scenario.$1)
                .having((e) => e.type, 'type', scenario.$3)
                .having((e) => e.failure, 'failure', scenario.$4)
                .having(
                  (e) => e.toString(),
                  'safe message',
                  allOf(
                    isNot(contains('signed-value')),
                    isNot(contains('public-key')),
                    isNot(contains('access-real')),
                  ),
                ),
          ),
        );
      },
    );
  }

  test('clasifica respuesta HTML de proxy sin mostrar su cuerpo', () async {
    final service = _service(
      uploadHandler: (_) async => http.Response('<html>secret</html>', 502),
    );
    await expectLater(
      service.uploadImages([_image('a.jpg')]),
      throwsA(
        isA<CloudinaryUploadException>()
            .having((e) => e.type, 'type', ApiErrorType.server)
            .having((e) => e.statusCode, 'status', 502)
            .having((e) => e.message, 'message', isNot(contains('secret'))),
      ),
    );
  });

  testWidgets(
    'el timeout real del upload se identifica sin exponer la petición',
    (tester) async {
      final pending = Completer<http.Response>();
      final service = _service(uploadHandler: (_) => pending.future);
      final expectation = expectLater(
        service.uploadImages([_image('a.jpg')]),
        throwsA(
          isA<CloudinaryUploadException>()
              .having((e) => e.type, 'type', ApiErrorType.timeout)
              .having((e) => e.failure, 'failure', CloudinaryFailure.timeout)
              .having(
                (e) => e.message,
                'message',
                contains('subida de la imagen'),
              ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 121));
      await expectation;
      pending.complete(http.Response('{}', 200));
      await tester.pump();
    },
  );

  testWidgets(
    'limita también el cuerpo de respuesta y cancela la petición expirada',
    (tester) async {
      final body = StreamController<List<int>>();
      var aborted = false;
      final service = _service(
        uploadClient: _StreamingUploadClient((request) async {
          unawaited(
            (request as http.Abortable).abortTrigger!.then((_) {
              aborted = true;
            }),
          );
          return http.StreamedResponse(body.stream, 200);
        }),
      );
      final expectation = expectLater(
        service.uploadImages([_image('a.jpg')]),
        throwsA(
          isA<CloudinaryUploadException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.timeout,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 121));
      await expectation;
      expect(aborted, isTrue);
      await body.close();
      await tester.pump();
    },
  );

  test('archivo ilegible no solicita firma ni intenta upload', () async {
    var requests = 0;
    final service = _service(
      apiHandler: (_) async {
        requests++;
        return http.Response('{}', 500);
      },
      uploadHandler: (_) async {
        requests++;
        return http.Response('{}', 500);
      },
    );
    await expectLater(
      service.uploadImages([XFile('missing-upload-test-image.jpg')]),
      throwsA(isA<Exception>()),
    );
    expect(requests, 0);
  });

  test('pide firma con bearer token y valida sus campos', () async {
    late http.Request captured;
    final service = _service(
      apiHandler: (request) async {
        captured = request;
        return http.Response(jsonEncode(_authorizationBody), 200);
      },
    );
    final result = await service.requestAuthorization();
    expect(captured.url.path, '/api/imagenes/firma');
    expect(captured.headers['Authorization'], 'Bearer access-real');
    expect(result.folder, 'donapp/donaciones');
  });

  test('sube una imagen firmada y extrae secure_url HTTPS', () async {
    late http.Request upload;
    final service = _service(
      uploadHandler: (request) async {
        upload = request;
        return http.Response(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/demo/image/upload/a.jpg',
          }),
          200,
        );
      },
    );
    final references = await service.uploadImages([_image('photo.jpg')]);
    expect(references, ['https://res.cloudinary.com/demo/image/upload/a.jpg']);
    expect(upload.url.host, 'api.cloudinary.com');
    expect(upload.url.path, '/v1_1/demo/image/upload');
    expect(upload.method, 'POST');
    expect(upload.headers.containsKey('Authorization'), isFalse);
    expect(upload.headers['content-type'], startsWith('multipart/form-data;'));
    expect(upload.body, contains('public-key'));
    expect(upload.body, contains('donapp/donaciones'));
    for (final entry in {
      'api_key': 'public-key',
      'timestamp': '1787900000',
      'signature': 'signed-value',
      'folder': 'donapp/donaciones',
      'allowed_formats': 'jpg,jpeg,png,webp',
    }.entries) {
      expect(
        upload.body,
        contains('name="${entry.key}"\r\n\r\n${entry.value}\r\n'),
      );
    }
    expect(upload.body, contains('content-type: image/jpeg'));
    expect(upload.body, contains('name="file"; filename="photo.jpg"'));
  });

  test('preserva el orden de varias imágenes', () async {
    var call = 0;
    final service = _service(
      uploadHandler: (_) async {
        call++;
        return http.Response(
          jsonEncode({'secure_url': 'https://images.test/$call.jpg'}),
          200,
        );
      },
    );
    final result = await service.uploadImages([
      _image('one.jpg'),
      _image('two.png'),
    ]);
    expect(result, ['https://images.test/1.jpg', 'https://images.test/2.jpg']);
  });

  test('rechaza más de cinco imágenes', () async {
    final service = _service();
    await expectLater(
      service.uploadImages(List.generate(6, (index) => _image('$index.jpg'))),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.validation,
        ),
      ),
    );
  });

  test('rechaza formato no permitido y archivo demasiado grande', () async {
    final service = _service();
    await expectLater(
      service.validateImage(_image('file.gif', mimeType: 'image/gif')),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      service.validateImage(
        _image('large.jpg', bytes: maxDonationImageBytes + 1),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('rechaza secure_url que no sea HTTPS', () async {
    final service = _service(
      uploadHandler: (_) async => http.Response(
        jsonEncode({'secure_url': 'http://images.test/a.jpg'}),
        200,
      ),
    );
    await expectLater(
      service.uploadImages([_image('a.jpg')]),
      throwsA(isA<ApiException>()),
    );
  });

  test('fallo parcial no devuelve referencias y permite reintentar', () async {
    var uploadCalls = 0;
    final service = _service(
      uploadHandler: (_) async {
        uploadCalls++;
        if (uploadCalls == 2) return http.Response('{}', 503);
        return http.Response(
          jsonEncode({'secure_url': 'https://images.test/$uploadCalls.jpg'}),
          200,
        );
      },
    );
    final images = [_image('one.jpg'), _image('two.jpg')];
    await expectLater(
      service.uploadImages(images),
      throwsA(isA<ApiException>()),
    );
    final retried = await service.uploadImages(images);
    expect(retried, ['https://images.test/3.jpg', 'https://images.test/4.jpg']);
  });

  test('mapea fallo de red de Cloudinary', () async {
    final service = _service(
      uploadHandler: (_) => throw http.ClientException('offline'),
    );
    await expectLater(
      service.uploadImages([_image('a.jpg')]),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.network,
        ),
      ),
    );
  });
}

ImageUploadService _service({
  Future<http.Response> Function(http.Request)? apiHandler,
  Future<http.Response> Function(http.Request)? uploadHandler,
  http.Client? uploadClient,
}) => ImageUploadService(
  tokenStorage: _TokenStorage(),
  apiClient: ApiClient(
    endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
    client: MockClient(
      apiHandler ??
          (_) async => http.Response(jsonEncode(_authorizationBody), 200),
    ),
  ),
  uploadClient:
      uploadClient ??
      MockClient(
        uploadHandler ??
            (_) async => http.Response(
              jsonEncode({'secure_url': 'https://images.test/a.jpg'}),
              200,
            ),
      ),
);

XFile _image(String name, {int bytes = 10, String mimeType = 'image/jpeg'}) =>
    XFile.fromData(
      Uint8List(bytes),
      name: name,
      path: name,
      mimeType: mimeType,
    );

class _TokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'access-real';
}

const _authorizationBody = {
  'success': true,
  'message': 'Carga de imagen autorizada.',
  'data': {
    'uploadUrl': 'https://api.cloudinary.com/v1_1/demo/image/upload',
    'apiKey': 'public-key',
    'timestamp': 1787900000,
    'signature': 'signed-value',
    'folder': 'donapp/donaciones',
    'allowedFormats': 'jpg,jpeg,png,webp',
  },
};

class _StreamingUploadClient extends http.BaseClient {
  _StreamingUploadClient(this.handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
