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
    expect(upload.headers['content-type'], startsWith('multipart/form-data;'));
    expect(upload.body, contains('public-key'));
    expect(upload.body, contains('donapp/donaciones'));
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
}) => ImageUploadService(
  tokenStorage: _TokenStorage(),
  apiClient: ApiClient(
    endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
    client: MockClient(
      apiHandler ??
          (_) async => http.Response(jsonEncode(_authorizationBody), 200),
    ),
  ),
  uploadClient: MockClient(
    uploadHandler ??
        (_) async => http.Response(
          jsonEncode({'secure_url': 'https://images.test/a.jpg'}),
          200,
        ),
  ),
);

XFile _image(String name, {int bytes = 10, String mimeType = 'image/jpeg'}) =>
    XFile.fromData(Uint8List(bytes), name: name, mimeType: mimeType);

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
