import 'package:donapp_mobile/models/donation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

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
