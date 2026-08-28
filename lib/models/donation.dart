enum DonationStatus { publicada, reservada, entregada, retirada }

extension DonationStatusJson on DonationStatus {
  static DonationStatus fromJson(Object? value) {
    return switch (value) {
      'PUBLICADA' => DonationStatus.publicada,
      'RESERVADA' => DonationStatus.reservada,
      'ENTREGADA' => DonationStatus.entregada,
      'RETIRADA' => DonationStatus.retirada,
      _ => throw const FormatException('Estado de donación inválido.'),
    };
  }

  String get label => switch (this) {
    DonationStatus.publicada => 'Publicada',
    DonationStatus.reservada => 'Reservada',
    DonationStatus.entregada => 'Entregada',
    DonationStatus.retirada => 'Retirada',
  };
}

class DonationImage {
  const DonationImage({
    required this.id,
    required this.referencia,
    required this.orden,
  });

  final int id;
  final String referencia;
  final int orden;

  factory DonationImage.fromJson(Map<String, dynamic> json) => DonationImage(
    id: _int(json, 'id'),
    referencia: _string(json, 'referencia'),
    orden: _int(json, 'orden'),
  );
}

class DonationListItem {
  const DonationListItem({
    required this.id,
    required this.titulo,
    required this.ciudad,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.imagenPrincipal,
    required this.cantidadImagenes,
  });

  final int id;
  final String titulo;
  final String ciudad;
  final DonationStatus estado;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int categoriaId;
  final String categoriaNombre;
  final DonationImage? imagenPrincipal;
  final int cantidadImagenes;

  factory DonationListItem.fromJson(Map<String, dynamic> json) {
    final category = json['categoria'];
    final image = json['imagenPrincipal'];
    if (category is! Map<String, dynamic> ||
        (image != null && image is! Map<String, dynamic>)) {
      throw const FormatException('Donación con formato inválido.');
    }
    return DonationListItem(
      id: _int(json, 'id'),
      titulo: _string(json, 'titulo'),
      ciudad: _string(json, 'ciudad'),
      estado: DonationStatusJson.fromJson(json['estado']),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      categoriaId: _int(category, 'id'),
      categoriaNombre: _string(category, 'nombre'),
      imagenPrincipal: image == null
          ? null
          : DonationImage.fromJson(image as Map<String, dynamic>),
      cantidadImagenes: _int(json, 'cantidadImagenes'),
    );
  }
}

class DonationPagination {
  const DonationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  factory DonationPagination.fromJson(Map<String, dynamic> json) =>
      DonationPagination(
        page: _int(json, 'page'),
        limit: _int(json, 'limit'),
        total: _int(json, 'total'),
        totalPages: _int(json, 'totalPages'),
      );
}

class DonationPage {
  const DonationPage({required this.donations, required this.pagination});

  final List<DonationListItem> donations;
  final DonationPagination pagination;

  factory DonationPage.fromJson(Map<String, dynamic> json) {
    final donations = json['donaciones'];
    final pagination = json['pagination'];
    if (donations is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Listado de donaciones inválido.');
    }
    return DonationPage(
      donations: donations
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Donación con formato inválido.');
            }
            return DonationListItem.fromJson(item);
          })
          .toList(growable: false),
      pagination: DonationPagination.fromJson(pagination),
    );
  }
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key tiene un formato inválido.');
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('$key tiene un formato inválido.');
  return parsed;
}
