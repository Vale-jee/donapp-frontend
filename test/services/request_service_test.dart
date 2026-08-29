import 'dart:convert';

import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('crear usa POST, bearer, body exacto y respuesta sin actor', () async {
    late http.Request captured;
    final service = _service((request) async {
      captured = request;
      return http.Response(jsonEncode(_created), 201);
    });
    final created = await service.createRequest(4);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/solicitudes');
    expect(captured.headers['Authorization'], 'Bearer access-real');
    expect(jsonDecode(captured.body), {'donacionId': 4});
    expect(created.id, 7);
    expect(created.status, RequestStatus.pendiente);
  });

  test('crear conserva mensaje seguro de conflicto', () async {
    final service = _service(
      (_) async => http.Response(
        jsonEncode({
          'success': false,
          'status': 409,
          'message': 'Ya existe una solicitud activa para esta donación.',
          'data': null,
        }),
        409,
      ),
    );
    await expectLater(
      service.createRequest(4),
      throwsA(
        isA<ApiException>()
            .having((error) => error.type, 'tipo', ApiErrorType.conflict)
            .having((error) => error.message, 'mensaje', contains('activa')),
      ),
    );
  });

  test('enviadas usa bearer token, query y paginación reales', () async {
    late http.Request captured;
    final service = _service((request) async {
      captured = request;
      return http.Response(jsonEncode(_page('donante')), 200);
    });
    final result = await service.getSentRequests(
      page: 2,
      limit: 10,
      status: RequestStatus.cancelada,
    );
    expect(captured.url.path, '/api/solicitudes/enviadas');
    expect(captured.url.queryParameters, {
      'page': '2',
      'limit': '10',
      'estado': 'CANCELADA',
    });
    expect(captured.headers['Authorization'], 'Bearer access-real');
    expect(result.requests.single.donor.visibleName, 'ana');
  });

  test('recibidas parsea solicitante real', () async {
    final service = _service(
      (_) async => http.Response(jsonEncode(_page('solicitante')), 200),
    );
    final result = await service.getReceivedRequests();
    expect(result.requests.single.applicant.visibleName, 'ana');
  });

  test('detalle consulta por id y valida actor', () async {
    late http.Request captured;
    final service = _service((request) async {
      captured = request;
      return http.Response(jsonEncode(_detail('donante')), 200);
    });
    final detail = await service.getRequestById(7);
    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/solicitudes/7');
    expect(detail.actor, RequestActor.applicant);
  });

  for (final action in ['aceptar', 'rechazar', 'cancelar']) {
    test('$action envía PATCH con body vacío', () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return http.Response(jsonEncode(_detail('solicitante')), 200);
      });
      switch (action) {
        case 'aceptar':
          await service.acceptRequest(7);
        case 'rechazar':
          await service.rejectRequest(7);
        case 'cancelar':
          await service.cancelRequest(7);
      }
      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/api/solicitudes/7/$action');
      expect(jsonDecode(captured.body), <String, dynamic>{});
    });
  }

  for (final code in [404, 409]) {
    test('mapea error HTTP $code', () async {
      final service = _service(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'status': code,
            'message': 'No disponible',
            'data': null,
          }),
          code,
        ),
      );
      await expectLater(
        service.getRequestById(7),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            code,
          ),
        ),
      );
    });
  }

  test('rechaza id inválido sin consultar backend', () async {
    await expectLater(
      RequestService(tokenStorage: _Storage()).getRequestById(0),
      throwsA(isA<ApiException>()),
    );
  });
}

RequestService _service(Future<http.Response> Function(http.Request) handler) =>
    RequestService(
      tokenStorage: _Storage(),
      apiClient: ApiClient(
        endpointBuilder: (path) => Uri.parse('https://api.test$path'),
        client: MockClient(handler),
      ),
    );

class _Storage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'access-real';
}

Map<String, dynamic> _page(String actor) => {
  'success': true,
  'data': {
    'solicitudes': [
      {..._request, actor: _user},
    ],
    'pagination': {'page': 2, 'limit': 10, 'total': 1, 'totalPages': 1},
  },
};

Map<String, dynamic> _detail(String actor) => {
  'success': true,
  'data': {
    'solicitud': {..._request, actor: _user},
  },
};

final Map<String, dynamic> _request = {
  'id': 7,
  'estado': 'PENDIENTE',
  'causaCancelacion': null,
  'aceptadaAt': null,
  'rechazadaAt': null,
  'canceladaAt': null,
  'createdAt': '2026-08-20T12:00:00.000Z',
  'updatedAt': '2026-08-20T12:00:00.000Z',
  'donacion': {
    'id': 4,
    'titulo': 'Bicicleta',
    'estado': 'PUBLICADA',
    'imagenPrincipal': null,
  },
};
const _user = {
  'id': 2,
  'nombreVisible': 'ana',
  'fotoPerfil': null,
  'ciudad': 'Bogotá',
};

final Map<String, dynamic> _created = {
  'success': true,
  'data': {'solicitud': _request},
};
