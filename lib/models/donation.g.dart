// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationImage _$DonationImageFromJson(Map<String, dynamic> json) =>
    DonationImage(
      id: strictInt(json['id']),
      referencia: nonEmptyString(json['referencia']),
      orden: strictInt(json['orden']),
    );

Map<String, dynamic> _$DonationImageToJson(DonationImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'referencia': instance.referencia,
      'orden': instance.orden,
    };

DonationDetail _$DonationDetailFromJson(Map<String, dynamic> json) =>
    DonationDetail(
      id: strictInt(json['id']),
      titulo: nonEmptyString(json['titulo']),
      descripcion: nonEmptyString(json['descripcion']),
      ciudad: nonEmptyString(json['ciudad']),
      estado: $enumDecode(_$DonationStatusEnumMap, json['estado']),
      createdAt: serverInstant(json['createdAt']),
      updatedAt: serverInstant(json['updatedAt']),
      categoriaId: strictInt(categoryId(json, 'categoriaId')),
      categoriaNombre: nonEmptyString(categoryName(json, 'categoriaNombre')),
      imagenes: (json['imagenes'] as List<dynamic>)
          .map((e) => DonationImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      puedeSolicitar: json['puedeSolicitar'] as bool? ?? false,
    );

Map<String, dynamic> _$DonationDetailToJson(DonationDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'ciudad': instance.ciudad,
      'estado': _$DonationStatusEnumMap[instance.estado]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imagenes': instance.imagenes.map((e) => e.toJson()).toList(),
      'puedeSolicitar': instance.puedeSolicitar,
      'categoria': instance.categoria,
    };

const _$DonationStatusEnumMap = {
  DonationStatus.publicada: 'PUBLICADA',
  DonationStatus.reservada: 'RESERVADA',
  DonationStatus.entregada: 'ENTREGADA',
  DonationStatus.retirada: 'RETIRADA',
};

DonationListItem _$DonationListItemFromJson(Map<String, dynamic> json) =>
    DonationListItem(
      id: strictInt(json['id']),
      titulo: nonEmptyString(json['titulo']),
      ciudad: nonEmptyString(json['ciudad']),
      estado: $enumDecode(_$DonationStatusEnumMap, json['estado']),
      createdAt: serverInstant(json['createdAt']),
      updatedAt: serverInstant(json['updatedAt']),
      categoriaId: strictInt(categoryId(json, 'categoriaId')),
      categoriaNombre: nonEmptyString(categoryName(json, 'categoriaNombre')),
      imagenPrincipal: json['imagenPrincipal'] == null
          ? null
          : DonationImage.fromJson(
              json['imagenPrincipal'] as Map<String, dynamic>,
            ),
      cantidadImagenes: strictInt(json['cantidadImagenes']),
    );

Map<String, dynamic> _$DonationListItemToJson(DonationListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'ciudad': instance.ciudad,
      'estado': _$DonationStatusEnumMap[instance.estado]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imagenPrincipal': instance.imagenPrincipal?.toJson(),
      'cantidadImagenes': instance.cantidadImagenes,
      'categoria': instance.categoria,
    };

DonationPagination _$DonationPaginationFromJson(Map<String, dynamic> json) =>
    DonationPagination(
      page: strictInt(json['page']),
      limit: strictInt(json['limit']),
      total: strictInt(json['total']),
      totalPages: strictInt(json['totalPages']),
    );

Map<String, dynamic> _$DonationPaginationToJson(DonationPagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
    };

DonationPage _$DonationPageFromJson(Map<String, dynamic> json) => DonationPage(
  donations: (json['donaciones'] as List<dynamic>)
      .map((e) => DonationListItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: DonationPagination.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DonationPageToJson(DonationPage instance) =>
    <String, dynamic>{
      'donaciones': instance.donations.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination.toJson(),
    };
