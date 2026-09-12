import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'donation.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DonationStatus { publicada, reservada, entregada, retirada }

extension DonationStatusJson on DonationStatus {
  static DonationStatus fromJson(Object? value) =>
      apiDecode(() => $enumDecode(_$DonationStatusEnumMap, value));

  String get label => switch (this) {
    DonationStatus.publicada => 'Publicada',
    DonationStatus.reservada => 'Reservada',
    DonationStatus.entregada => 'Entregada',
    DonationStatus.retirada => 'Retirada',
  };

  String get apiValue => _$DonationStatusEnumMap[this]!;
}

@JsonSerializable(explicitToJson: true)
class DonationImage {
  const DonationImage({
    required this.id,
    required this.referencia,
    required this.orden,
    this.cachedLocalPath,
  });

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(fromJson: nonEmptyString)
  final String referencia;
  @JsonKey(fromJson: strictInt)
  final int orden;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? cachedLocalPath;

  factory DonationImage.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$DonationImageFromJson(json));
  Map<String, dynamic> toJson() => _$DonationImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DonationDetail {
  DonationDetail({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.ciudad,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    required this.categoriaId,
    required this.categoriaNombre,
    required List<DonationImage> imagenes,
    this.puedeSolicitar = false,
  }) : imagenes = List.unmodifiable(
         [...imagenes]
           ..sort((first, second) => first.orden.compareTo(second.orden)),
       );

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(fromJson: nonEmptyString)
  final String titulo;
  @JsonKey(fromJson: nonEmptyString)
  final String descripcion;
  @JsonKey(fromJson: nonEmptyString)
  final String ciudad;
  final DonationStatus estado;
  @JsonKey(fromJson: serverInstant)
  final DateTime createdAt;
  @JsonKey(fromJson: serverInstant)
  final DateTime updatedAt;
  @JsonKey(fromJson: strictInt, readValue: categoryId, includeToJson: false)
  final int categoriaId;
  @JsonKey(
    fromJson: nonEmptyString,
    readValue: categoryName,
    includeToJson: false,
  )
  final String categoriaNombre;
  final List<DonationImage> imagenes;
  final bool puedeSolicitar;

  factory DonationDetail.fromJson(Map<String, dynamic> json) => apiDecode(() {
    if (json['puedeSolicitar'] is! bool) {
      throw const FormatException('Expected puedeSolicitar.');
    }
    return _$DonationDetailFromJson(json);
  });
  factory DonationDetail.fromMutationJson(Map<String, dynamic> json) =>
      apiDecode(
        () => _$DonationDetailFromJson({...json, 'puedeSolicitar': false}),
      );
  Map<String, dynamic> toJson() => _$DonationDetailToJson(this);
  @JsonKey(includeFromJson: false, includeToJson: true)
  Map<String, dynamic> get categoria => {
    'id': categoriaId,
    'nombre': categoriaNombre,
  };
}

@JsonSerializable(explicitToJson: true)
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

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(fromJson: nonEmptyString)
  final String titulo;
  @JsonKey(fromJson: nonEmptyString)
  final String ciudad;
  final DonationStatus estado;
  @JsonKey(fromJson: serverInstant)
  final DateTime createdAt;
  @JsonKey(fromJson: serverInstant)
  final DateTime updatedAt;
  @JsonKey(fromJson: strictInt, readValue: categoryId, includeToJson: false)
  final int categoriaId;
  @JsonKey(
    fromJson: nonEmptyString,
    readValue: categoryName,
    includeToJson: false,
  )
  final String categoriaNombre;
  final DonationImage? imagenPrincipal;
  @JsonKey(fromJson: strictInt)
  final int cantidadImagenes;

  factory DonationListItem.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$DonationListItemFromJson(json));
  Map<String, dynamic> toJson() => _$DonationListItemToJson(this);
  @JsonKey(includeFromJson: false, includeToJson: true)
  Map<String, dynamic> get categoria => {
    'id': categoriaId,
    'nombre': categoriaNombre,
  };
}

@JsonSerializable(explicitToJson: true)
class DonationPagination {
  const DonationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  @JsonKey(fromJson: strictInt)
  final int page;
  @JsonKey(fromJson: strictInt)
  final int limit;
  @JsonKey(fromJson: strictInt)
  final int total;
  @JsonKey(fromJson: strictInt)
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  factory DonationPagination.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$DonationPaginationFromJson(json));
  Map<String, dynamic> toJson() => _$DonationPaginationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DonationPage {
  const DonationPage({required this.donations, required this.pagination});

  @JsonKey(name: 'donaciones')
  final List<DonationListItem> donations;
  final DonationPagination pagination;

  factory DonationPage.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$DonationPageFromJson(json));
  Map<String, dynamic> toJson() => _$DonationPageToJson(this);
}
