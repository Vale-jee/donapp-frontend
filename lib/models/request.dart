import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'request.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RequestStatus { pendiente, aceptada, rechazada, cancelada }

extension RequestStatusJson on RequestStatus {
  static RequestStatus fromJson(Object? value) =>
      apiDecode(() => $enumDecode(_$RequestStatusEnumMap, value));

  String get apiValue => _$RequestStatusEnumMap[this]!;

  String get label => switch (this) {
    RequestStatus.pendiente => 'Pendiente',
    RequestStatus.aceptada => 'Aceptada',
    RequestStatus.rechazada => 'Rechazada',
    RequestStatus.cancelada => 'Cancelada',
  };
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CancellationCause {
  voluntaria,
  otraSolicitudAceptada,
  donacionRetirada,
  usuarioInactivo,
}

extension CancellationCauseJson on CancellationCause {
  static CancellationCause? fromJson(Object? value) =>
      apiDecode(() => $enumDecodeNullable(_$CancellationCauseEnumMap, value));

  String get label => switch (this) {
    CancellationCause.voluntaria => 'Cancelada por el solicitante',
    CancellationCause.otraSolicitudAceptada =>
      'Se aceptó otra solicitud para esta donación',
    CancellationCause.donacionRetirada => 'La donación fue retirada',
    CancellationCause.usuarioInactivo => 'El usuario fue desactivado',
  };
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RequestDonationStatus { publicada, reservada, entregada, retirada }

extension RequestDonationStatusJson on RequestDonationStatus {
  static RequestDonationStatus fromJson(Object? value) =>
      apiDecode(() => $enumDecode(_$RequestDonationStatusEnumMap, value));

  String get label => switch (this) {
    RequestDonationStatus.publicada => 'Publicada',
    RequestDonationStatus.reservada => 'Reservada',
    RequestDonationStatus.entregada => 'Entregada',
    RequestDonationStatus.retirada => 'Retirada',
  };
}

@JsonSerializable(explicitToJson: true)
class RequestDonationSummary {
  const RequestDonationSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.mainImage,
  });
  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(name: 'titulo', fromJson: nonEmptyString)
  final String title;
  @JsonKey(name: 'estado')
  final RequestDonationStatus status;
  @JsonKey(name: 'imagenPrincipal', fromJson: nonEmptyNullableString)
  final String? mainImage;

  factory RequestDonationSummary.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$RequestDonationSummaryFromJson(json));
  Map<String, dynamic> toJson() => _$RequestDonationSummaryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RequestUserSummary {
  const RequestUserSummary({
    required this.id,
    required this.visibleName,
    required this.profilePhoto,
    required this.city,
  });
  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(name: 'nombreVisible', fromJson: nonEmptyString)
  final String visibleName;
  @JsonKey(name: 'fotoPerfil', fromJson: nonEmptyNullableString)
  final String? profilePhoto;
  @JsonKey(name: 'ciudad', fromJson: nonEmptyString)
  final String city;

  factory RequestUserSummary.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$RequestUserSummaryFromJson(json));
  Map<String, dynamic> toJson() => _$RequestUserSummaryToJson(this);
}

abstract class RequestListItem {
  const RequestListItem({
    required this.id,
    required this.status,
    required this.cancellationCause,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.donation,
  });
  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(name: 'estado')
  final RequestStatus status;
  @JsonKey(name: 'causaCancelacion')
  final CancellationCause? cancellationCause;
  @JsonKey(name: 'aceptadaAt')
  final DateTime? acceptedAt;
  @JsonKey(name: 'rechazadaAt')
  final DateTime? rejectedAt;
  @JsonKey(name: 'canceladaAt')
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: 'donacion')
  final RequestDonationSummary donation;
}

@JsonSerializable(explicitToJson: true)
class SentRequestListItem extends RequestListItem {
  const SentRequestListItem({
    required super.id,
    required super.status,
    required super.cancellationCause,
    required super.acceptedAt,
    required super.rejectedAt,
    required super.cancelledAt,
    required super.createdAt,
    required super.updatedAt,
    required super.donation,
    required this.donor,
  });
  @JsonKey(name: 'donante')
  final RequestUserSummary donor;

  factory SentRequestListItem.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$SentRequestListItemFromJson(json));
  Map<String, dynamic> toJson() => _$SentRequestListItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReceivedRequestListItem extends RequestListItem {
  const ReceivedRequestListItem({
    required super.id,
    required super.status,
    required super.cancellationCause,
    required super.acceptedAt,
    required super.rejectedAt,
    required super.cancelledAt,
    required super.createdAt,
    required super.updatedAt,
    required super.donation,
    required this.applicant,
  });
  @JsonKey(name: 'solicitante')
  final RequestUserSummary applicant;

  factory ReceivedRequestListItem.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$ReceivedRequestListItemFromJson(json));
  Map<String, dynamic> toJson() => _$ReceivedRequestListItemToJson(this);
}

enum RequestActor { applicant, owner }

@JsonSerializable(explicitToJson: true)
class CreatedRequest {
  const CreatedRequest({
    required this.id,
    required this.status,
    required this.donation,
  });

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(name: 'estado')
  final RequestStatus status;
  @JsonKey(name: 'donacion')
  final RequestDonationSummary donation;

  factory CreatedRequest.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$CreatedRequestFromJson(json));
  Map<String, dynamic> toJson() => _$CreatedRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, constructor: 'fromWire')
class RequestDetail extends RequestListItem {
  const RequestDetail({
    required super.id,
    required super.status,
    required super.cancellationCause,
    required super.acceptedAt,
    required super.rejectedAt,
    required super.cancelledAt,
    required super.createdAt,
    required super.updatedAt,
    required super.donation,
    required this.actor,
    required this.otherUser,
    RequestUserSummary? donor,
    RequestUserSummary? applicant,
  }) : donor = donor ?? (actor == RequestActor.applicant ? otherUser : null),
       applicant =
           applicant ?? (actor == RequestActor.owner ? otherUser : null);

  RequestDetail.fromWire({
    required int id,
    required RequestStatus status,
    required CancellationCause? cancellationCause,
    required DateTime? acceptedAt,
    required DateTime? rejectedAt,
    required DateTime? cancelledAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required RequestDonationSummary donation,
    RequestUserSummary? donor,
    RequestUserSummary? applicant,
  }) : this(
         id: id,
         status: status,
         cancellationCause: cancellationCause,
         acceptedAt: acceptedAt,
         rejectedAt: rejectedAt,
         cancelledAt: cancelledAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
         donation: donation,
         actor: donor != null ? RequestActor.applicant : RequestActor.owner,
         otherUser:
             donor ??
             applicant ??
             (throw const FormatException('Missing request participant.')),
         donor: donor,
         applicant: applicant,
       );

  @JsonKey(name: 'donante', includeIfNull: false)
  final RequestUserSummary? donor;
  @JsonKey(name: 'solicitante', includeIfNull: false)
  final RequestUserSummary? applicant;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final RequestActor actor;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final RequestUserSummary otherUser;

  bool get canAcceptOrReject =>
      actor == RequestActor.owner &&
      status == RequestStatus.pendiente &&
      donation.status == RequestDonationStatus.publicada;
  bool get canCancel =>
      actor == RequestActor.applicant && status == RequestStatus.pendiente;

  factory RequestDetail.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$RequestDetailFromJson(json));
  Map<String, dynamic> toJson() => _$RequestDetailToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RequestPagination {
  const RequestPagination({
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
  factory RequestPagination.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$RequestPaginationFromJson(json));
  Map<String, dynamic> toJson() => _$RequestPaginationToJson(this);
}

@JsonSerializable(explicitToJson: true, genericArgumentFactories: true)
class RequestPage<T extends RequestListItem> {
  const RequestPage({required this.requests, required this.pagination});
  @JsonKey(name: 'solicitudes')
  final List<T> requests;
  final RequestPagination pagination;

  factory RequestPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => apiDecode(
    () => _$RequestPageFromJson<T>(
      json,
      (value) => parse(value as Map<String, dynamic>),
    ),
  );
  Map<String, dynamic> toJson(Object? Function(T) encode) =>
      _$RequestPageToJson<T>(this, encode);
}
