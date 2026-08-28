import 'dart:convert';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía token y query params correctos y parsea la lista', () async {
    late http.Request captured;
    final service = DonationService(
      tokenStorage: _TokenStorage('access-real'),
      apiClient: ApiClient(
        endpointBuilder: (path) => Uri.parse('https://api.donapp.test$path'),
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(_successBody), 200);
        }),
      ),
    );

    final page = await service.getAvailableDonations(
      page: 2,
      limit: 10,
      categoryId: 4,
    );

    expect(captured.url.path, '/api/donaciones');
    expect(captured.url.queryParameters, {
      'page': '2',
      'limit': '10',
      'categoriaId': '4',
    });
    expect(captured.headers['Authorization'], 'Bearer access-real');
    expect(page.donations.single.titulo, 'Silla de madera');
  });

  test('mapea un error HTTP mediante ApiException', () async {
    final service = DonationService(
      tokenStorage: _TokenStorage('access-real'),
      apiClient: ApiClient(
        endpointBuilder: (path) => Uri.parse('https://api.donapp.test$path'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'status': 500,
              'message': 'Error interno del servidor',
              'data': null,
            }),
            500,
          ),
        ),
      ),
    );

    await expectLater(
      service.getAvailableDonations(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.server,
        ),
      ),
    );
  });

  test(
    'consulta detalle por id con bearer token y parsea la respuesta',
    () async {
      late http.Request captured;
      final service = DonationService(
        tokenStorage: _TokenStorage('access-real'),
        apiClient: ApiClient(
          endpointBuilder: (path) => Uri.parse('https://api.donapp.test$path'),
          client: MockClient((request) async {
            captured = request;
            return http.Response(jsonEncode(_detailBody), 200);
          }),
        ),
      );

      final detail = await service.getDonationById(4);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/donaciones/4');
      expect(captured.headers['Authorization'], 'Bearer access-real');
      expect(detail.id, 4);
    },
  );

  test('rechaza id no positivo sin consultar la API', () async {
    final service = DonationService(tokenStorage: _TokenStorage('access-real'));
    await expectLater(
      service.getDonationById(0),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.validation,
        ),
      ),
    );
  });

  test('mapea 404 del detalle', () async {
    final service = DonationService(
      tokenStorage: _TokenStorage('access-real'),
      apiClient: ApiClient(
        endpointBuilder: (path) => Uri.parse('https://api.donapp.test$path'),
        client: MockClient(
          (_) async => http.Response(jsonEncode({'success': false}), 404),
        ),
      ),
    );
    await expectLater(
      service.getDonationById(4),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.notFound,
        ),
      ),
    );
  });
}

class _TokenStorage extends TokenStorage {
  _TokenStorage(this.token);
  final String? token;

  @override
  Future<String?> readAccessToken() async => token;
}

const _successBody = {
  'success': true,
  'message': 'Donaciones disponibles consultadas correctamente.',
  'data': {
    'donaciones': [
      {
        'id': 2,
        'titulo': 'Silla de madera',
        'ciudad': 'Bogotá',
        'estado': 'PUBLICADA',
        'createdAt': '2026-08-20T12:00:00.000Z',
        'updatedAt': '2026-08-20T12:00:00.000Z',
        'categoria': {'id': 4, 'nombre': 'Muebles'},
        'imagenPrincipal': null,
        'cantidadImagenes': 0,
      },
    ],
    'pagination': {'page': 2, 'limit': 10, 'total': 11, 'totalPages': 2},
  },
};

const _detailBody = {
  'success': true,
  'data': {
    'donacion': {
      'id': 4,
      'titulo': 'Mesa auxiliar',
      'descripcion': 'En buen estado.',
      'ciudad': 'Bogotá',
      'estado': 'PUBLICADA',
      'createdAt': '2026-08-20T12:00:00.000Z',
      'updatedAt': '2026-08-21T12:00:00.000Z',
      'categoria': {'id': 4, 'nombre': 'Muebles'},
      'imagenes': <Map<String, Object>>[],
    },
  },
};
