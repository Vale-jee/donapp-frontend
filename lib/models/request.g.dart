// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestDonationSummary _$RequestDonationSummaryFromJson(
  Map<String, dynamic> json,
) => RequestDonationSummary(
  id: strictInt(json['id']),
  title: nonEmptyString(json['titulo']),
  status: $enumDecode(_$RequestDonationStatusEnumMap, json['estado']),
  mainImage: nonEmptyNullableString(json['imagenPrincipal']),
);

Map<String, dynamic> _$RequestDonationSummaryToJson(
  RequestDonationSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'titulo': instance.title,
  'estado': _$RequestDonationStatusEnumMap[instance.status]!,
  'imagenPrincipal': instance.mainImage,
};

const _$RequestDonationStatusEnumMap = {
  RequestDonationStatus.publicada: 'PUBLICADA',
  RequestDonationStatus.reservada: 'RESERVADA',
  RequestDonationStatus.entregada: 'ENTREGADA',
  RequestDonationStatus.retirada: 'RETIRADA',
};

RequestUserSummary _$RequestUserSummaryFromJson(Map<String, dynamic> json) =>
    RequestUserSummary(
      id: strictInt(json['id']),
      visibleName: nonEmptyString(json['nombreVisible']),
      profilePhoto: nonEmptyNullableString(json['fotoPerfil']),
      city: nonEmptyString(json['ciudad']),
    );

Map<String, dynamic> _$RequestUserSummaryToJson(RequestUserSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombreVisible': instance.visibleName,
      'fotoPerfil': instance.profilePhoto,
      'ciudad': instance.city,
    };

SentRequestListItem _$SentRequestListItemFromJson(Map<String, dynamic> json) =>
    SentRequestListItem(
      id: strictInt(json['id']),
      status: $enumDecode(_$RequestStatusEnumMap, json['estado']),
      cancellationCause: $enumDecodeNullable(
        _$CancellationCauseEnumMap,
        json['causaCancelacion'],
      ),
      acceptedAt: json['aceptadaAt'] == null
          ? null
          : DateTime.parse(json['aceptadaAt'] as String),
      rejectedAt: json['rechazadaAt'] == null
          ? null
          : DateTime.parse(json['rechazadaAt'] as String),
      cancelledAt: json['canceladaAt'] == null
          ? null
          : DateTime.parse(json['canceladaAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      donation: RequestDonationSummary.fromJson(
        json['donacion'] as Map<String, dynamic>,
      ),
      donor: RequestUserSummary.fromJson(
        json['donante'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SentRequestListItemToJson(
  SentRequestListItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'estado': _$RequestStatusEnumMap[instance.status]!,
  'causaCancelacion': _$CancellationCauseEnumMap[instance.cancellationCause],
  'aceptadaAt': instance.acceptedAt?.toIso8601String(),
  'rechazadaAt': instance.rejectedAt?.toIso8601String(),
  'canceladaAt': instance.cancelledAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'donacion': instance.donation.toJson(),
  'donante': instance.donor.toJson(),
};

const _$RequestStatusEnumMap = {
  RequestStatus.pendiente: 'PENDIENTE',
  RequestStatus.aceptada: 'ACEPTADA',
  RequestStatus.rechazada: 'RECHAZADA',
  RequestStatus.cancelada: 'CANCELADA',
};

const _$CancellationCauseEnumMap = {
  CancellationCause.voluntaria: 'VOLUNTARIA',
  CancellationCause.otraSolicitudAceptada: 'OTRA_SOLICITUD_ACEPTADA',
  CancellationCause.donacionRetirada: 'DONACION_RETIRADA',
  CancellationCause.usuarioInactivo: 'USUARIO_INACTIVO',
};

ReceivedRequestListItem _$ReceivedRequestListItemFromJson(
  Map<String, dynamic> json,
) => ReceivedRequestListItem(
  id: strictInt(json['id']),
  status: $enumDecode(_$RequestStatusEnumMap, json['estado']),
  cancellationCause: $enumDecodeNullable(
    _$CancellationCauseEnumMap,
    json['causaCancelacion'],
  ),
  acceptedAt: json['aceptadaAt'] == null
      ? null
      : DateTime.parse(json['aceptadaAt'] as String),
  rejectedAt: json['rechazadaAt'] == null
      ? null
      : DateTime.parse(json['rechazadaAt'] as String),
  cancelledAt: json['canceladaAt'] == null
      ? null
      : DateTime.parse(json['canceladaAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  donation: RequestDonationSummary.fromJson(
    json['donacion'] as Map<String, dynamic>,
  ),
  applicant: RequestUserSummary.fromJson(
    json['solicitante'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ReceivedRequestListItemToJson(
  ReceivedRequestListItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'estado': _$RequestStatusEnumMap[instance.status]!,
  'causaCancelacion': _$CancellationCauseEnumMap[instance.cancellationCause],
  'aceptadaAt': instance.acceptedAt?.toIso8601String(),
  'rechazadaAt': instance.rejectedAt?.toIso8601String(),
  'canceladaAt': instance.cancelledAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'donacion': instance.donation.toJson(),
  'solicitante': instance.applicant.toJson(),
};

CreatedRequest _$CreatedRequestFromJson(Map<String, dynamic> json) =>
    CreatedRequest(
      id: strictInt(json['id']),
      status: $enumDecode(_$RequestStatusEnumMap, json['estado']),
      donation: RequestDonationSummary.fromJson(
        json['donacion'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$CreatedRequestToJson(CreatedRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'estado': _$RequestStatusEnumMap[instance.status]!,
      'donacion': instance.donation.toJson(),
    };

RequestDetail _$RequestDetailFromJson(Map<String, dynamic> json) =>
    RequestDetail.fromWire(
      id: strictInt(json['id']),
      status: $enumDecode(_$RequestStatusEnumMap, json['estado']),
      cancellationCause: $enumDecodeNullable(
        _$CancellationCauseEnumMap,
        json['causaCancelacion'],
      ),
      acceptedAt: json['aceptadaAt'] == null
          ? null
          : DateTime.parse(json['aceptadaAt'] as String),
      rejectedAt: json['rechazadaAt'] == null
          ? null
          : DateTime.parse(json['rechazadaAt'] as String),
      cancelledAt: json['canceladaAt'] == null
          ? null
          : DateTime.parse(json['canceladaAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      donation: RequestDonationSummary.fromJson(
        json['donacion'] as Map<String, dynamic>,
      ),
      donor: json['donante'] == null
          ? null
          : RequestUserSummary.fromJson(
              json['donante'] as Map<String, dynamic>,
            ),
      applicant: json['solicitante'] == null
          ? null
          : RequestUserSummary.fromJson(
              json['solicitante'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$RequestDetailToJson(
  RequestDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'estado': _$RequestStatusEnumMap[instance.status]!,
  'causaCancelacion': _$CancellationCauseEnumMap[instance.cancellationCause],
  'aceptadaAt': instance.acceptedAt?.toIso8601String(),
  'rechazadaAt': instance.rejectedAt?.toIso8601String(),
  'canceladaAt': instance.cancelledAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'donacion': instance.donation.toJson(),
  'donante': ?instance.donor?.toJson(),
  'solicitante': ?instance.applicant?.toJson(),
};

RequestPagination _$RequestPaginationFromJson(Map<String, dynamic> json) =>
    RequestPagination(
      page: strictInt(json['page']),
      limit: strictInt(json['limit']),
      total: strictInt(json['total']),
      totalPages: strictInt(json['totalPages']),
    );

Map<String, dynamic> _$RequestPaginationToJson(RequestPagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
    };

RequestPage<T> _$RequestPageFromJson<T extends RequestListItem>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => RequestPage<T>(
  requests: (json['solicitudes'] as List<dynamic>).map(fromJsonT).toList(),
  pagination: RequestPagination.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$RequestPageToJson<T extends RequestListItem>(
  RequestPage<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'solicitudes': instance.requests.map(toJsonT).toList(),
  'pagination': instance.pagination.toJson(),
};
