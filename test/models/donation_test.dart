import 'package:donapp_mobile/models/donation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea el detalle, estado, fechas e imágenes ordenadas', () {
    final detail = DonationDetail.fromJson(_detailJson);

    expect(detail.id, 4);
    expect(detail.descripcion, 'En buen estado.');
    expect(detail.puedeSolicitar, isTrue);
    expect(detail.estado, DonationStatus.publicada);
    expect(detail.createdAt, DateTime.parse('2026-08-20T12:00:00.000Z'));
    expect(detail.updatedAt, DateTime.parse('2026-08-21T12:00:00.000Z'));
    expect(detail.imagenes.map((image) => image.orden), [1, 2]);
  });
  test('exige puedeSolicitar booleano en el detalle GET', () {
    final invalid = Map<String, dynamic>.from(_detailJson)
      ..remove('puedeSolicitar');
    expect(() => DonationDetail.fromJson(invalid), throwsFormatException);
  });
  test('parsea un listado real con paginación', () {
    final page = DonationPage.fromJson(_pageJson(image: _imageJson));

    expect(page.donations, hasLength(1));
    final donation = page.donations.single;
    expect(donation.id, 7);
    expect(donation.titulo, 'Mesa auxiliar');
    expect(donation.estado, DonationStatus.publicada);
    expect(donation.categoriaId, 3);
    expect(donation.categoriaNombre, 'Muebles');
    expect(donation.imagenPrincipal?.referencia, '/imagenes/mesa.jpg');
    expect(page.pagination.page, 1);
    expect(page.pagination.limit, 20);
    expect(page.pagination.total, 21);
    expect(page.pagination.totalPages, 2);
    expect(page.pagination.hasNextPage, isTrue);
  });

  test('acepta imagenPrincipal null', () {
    final page = DonationPage.fromJson(_pageJson(image: null));

    expect(page.donations.single.imagenPrincipal, isNull);
  });

  test('normaliza al mismo instante UTC sin truncar precisión', () {
    final json = Map<String, dynamic>.from(_detailJson)
      ..['createdAt'] = '2026-08-20T07:00:00.123456-05:00'
      ..['updatedAt'] = '2026-08-21T14:30:00.654321+02:30';

    final detail = DonationDetail.fromJson(json);

    expect(detail.createdAt, DateTime.utc(2026, 8, 20, 12, 0, 0, 123, 456));
    expect(detail.updatedAt, DateTime.utc(2026, 8, 21, 12, 0, 0, 654, 321));
    expect(detail.createdAt.isUtc, isTrue);
    expect(detail.updatedAt.isUtc, isTrue);
  });

  test('rechaza timestamps ausentes, inválidos o sin zona explícita', () {
    for (final value in <Object?>[
      null,
      'fecha-inválida',
      '2026-08-20T12:00:00',
    ]) {
      final json = Map<String, dynamic>.from(_detailJson)
        ..['updatedAt'] = value;
      expect(() => DonationDetail.fromJson(json), throwsFormatException);
    }
  });
}

const _detailJson = {
  'id': 4,
  'titulo': 'Mesa auxiliar',
  'descripcion': 'En buen estado.',
  'puedeSolicitar': true,
  'ciudad': 'Bogotá',
  'estado': 'PUBLICADA',
  'createdAt': '2026-08-20T12:00:00.000Z',
  'updatedAt': '2026-08-21T12:00:00.000Z',
  'categoria': {'id': 4, 'nombre': 'Muebles'},
  'imagenes': [
    {'id': 2, 'referencia': '/segunda.jpg', 'orden': 2},
    {'id': 1, 'referencia': '/primera.jpg', 'orden': 1},
  ],
};

Map<String, dynamic> _pageJson({required Object? image}) => {
  'donaciones': [
    {
      'id': 7,
      'titulo': 'Mesa auxiliar',
      'ciudad': 'Bogotá',
      'estado': 'PUBLICADA',
      'createdAt': '2026-08-20T12:00:00.000Z',
      'updatedAt': '2026-08-21T12:00:00.000Z',
      'categoria': {'id': 3, 'nombre': 'Muebles'},
      'imagenPrincipal': image,
      'cantidadImagenes': image == null ? 0 : 1,
    },
  ],
  'pagination': {'page': 1, 'limit': 20, 'total': 21, 'totalPages': 2},
};

const _imageJson = {'id': 9, 'referencia': '/imagenes/mesa.jpg', 'orden': 1};
