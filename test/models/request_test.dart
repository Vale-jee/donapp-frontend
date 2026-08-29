import 'package:donapp_mobile/models/request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea los cuatro estados y sus etiquetas', () {
    expect(
      [
        'PENDIENTE',
        'ACEPTADA',
        'RECHAZADA',
        'CANCELADA',
      ].map(RequestStatusJson.fromJson),
      RequestStatus.values,
    );
    expect(RequestStatus.values.map((value) => value.apiValue), [
      'PENDIENTE',
      'ACEPTADA',
      'RECHAZADA',
      'CANCELADA',
    ]);
  });

  test('mapea las cuatro causas reales', () {
    expect(
      [
        'VOLUNTARIA',
        'OTRA_SOLICITUD_ACEPTADA',
        'DONACION_RETIRADA',
        'USUARIO_INACTIVO',
      ].map(CancellationCauseJson.fromJson),
      CancellationCause.values,
    );
  });

  test('parsea solicitudes enviadas y recibidas paginadas', () {
    final sent = RequestPage<SentRequestListItem>.fromJson(
      _page({..._request, 'donante': _user}),
      SentRequestListItem.fromJson,
    );
    final received = RequestPage<ReceivedRequestListItem>.fromJson(
      _page({..._request, 'solicitante': _user}),
      ReceivedRequestListItem.fromJson,
    );
    expect(sent.requests.single.donor.visibleName, 'ana');
    expect(received.requests.single.applicant.city, 'Bogotá');
    expect(sent.pagination.hasNextPage, isFalse);
  });

  test('detalle infiere solicitante por donante', () {
    final detail = RequestDetail.fromJson({..._request, 'donante': _user});
    expect(detail.actor, RequestActor.applicant);
    expect(detail.canCancel, isTrue);
    expect(detail.canAcceptOrReject, isFalse);
  });

  test('detalle infiere propietario por solicitante', () {
    final detail = RequestDetail.fromJson({..._request, 'solicitante': _user});
    expect(detail.actor, RequestActor.owner);
    expect(detail.canAcceptOrReject, isTrue);
  });

  test('rechaza detalle con ambos actores o sin actor', () {
    expect(
      () => RequestDetail.fromJson(_request),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RequestDetail.fromJson({
        ..._request,
        'donante': _user,
        'solicitante': _user,
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, dynamic> _page(Map<String, dynamic> request) => {
  'solicitudes': [request],
  'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
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
    'titulo': 'Bicicleta infantil',
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
