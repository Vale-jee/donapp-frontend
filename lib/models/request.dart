enum RequestStatus { pendiente, aceptada, rechazada, cancelada }

extension RequestStatusJson on RequestStatus {
  static RequestStatus fromJson(Object? value) => switch (value) {
    'PENDIENTE' => RequestStatus.pendiente,
    'ACEPTADA' => RequestStatus.aceptada,
    'RECHAZADA' => RequestStatus.rechazada,
    'CANCELADA' => RequestStatus.cancelada,
    _ => throw const FormatException('Estado de solicitud inválido.'),
  };

  String get apiValue => switch (this) {
    RequestStatus.pendiente => 'PENDIENTE',
    RequestStatus.aceptada => 'ACEPTADA',
    RequestStatus.rechazada => 'RECHAZADA',
    RequestStatus.cancelada => 'CANCELADA',
  };

  String get label => switch (this) {
    RequestStatus.pendiente => 'Pendiente',
    RequestStatus.aceptada => 'Aceptada',
    RequestStatus.rechazada => 'Rechazada',
    RequestStatus.cancelada => 'Cancelada',
  };
}

enum CancellationCause {
  voluntaria,
  otraSolicitudAceptada,
  donacionRetirada,
  usuarioInactivo,
}

extension CancellationCauseJson on CancellationCause {
  static CancellationCause? fromJson(Object? value) => switch (value) {
    null => null,
    'VOLUNTARIA' => CancellationCause.voluntaria,
    'OTRA_SOLICITUD_ACEPTADA' => CancellationCause.otraSolicitudAceptada,
    'DONACION_RETIRADA' => CancellationCause.donacionRetirada,
    'USUARIO_INACTIVO' => CancellationCause.usuarioInactivo,
    _ => throw const FormatException('Causa de cancelación inválida.'),
  };

  String get label => switch (this) {
    CancellationCause.voluntaria => 'Cancelada por el solicitante',
    CancellationCause.otraSolicitudAceptada =>
      'Se aceptó otra solicitud para esta donación',
    CancellationCause.donacionRetirada => 'La donación fue retirada',
    CancellationCause.usuarioInactivo => 'El usuario fue desactivado',
  };
}

enum RequestDonationStatus { publicada, reservada, entregada, retirada }

extension RequestDonationStatusJson on RequestDonationStatus {
  static RequestDonationStatus fromJson(Object? value) => switch (value) {
    'PUBLICADA' => RequestDonationStatus.publicada,
    'RESERVADA' => RequestDonationStatus.reservada,
    'ENTREGADA' => RequestDonationStatus.entregada,
    'RETIRADA' => RequestDonationStatus.retirada,
    _ => throw const FormatException('Estado de donación inválido.'),
  };

  String get label => switch (this) {
    RequestDonationStatus.publicada => 'Publicada',
    RequestDonationStatus.reservada => 'Reservada',
    RequestDonationStatus.entregada => 'Entregada',
    RequestDonationStatus.retirada => 'Retirada',
  };
}

class RequestDonationSummary {
  const RequestDonationSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.mainImage,
  });
  final int id;
  final String title;
  final RequestDonationStatus status;
  final String? mainImage;

  factory RequestDonationSummary.fromJson(Map<String, dynamic> json) =>
      RequestDonationSummary(
        id: _int(json, 'id'),
        title: _string(json, 'titulo'),
        status: RequestDonationStatusJson.fromJson(json['estado']),
        mainImage: _nullableString(json, 'imagenPrincipal'),
      );
}

class RequestUserSummary {
  const RequestUserSummary({
    required this.id,
    required this.visibleName,
    required this.profilePhoto,
    required this.city,
  });
  final int id;
  final String visibleName;
  final String? profilePhoto;
  final String city;

  factory RequestUserSummary.fromJson(Map<String, dynamic> json) =>
      RequestUserSummary(
        id: _int(json, 'id'),
        visibleName: _string(json, 'nombreVisible'),
        profilePhoto: _nullableString(json, 'fotoPerfil'),
        city: _string(json, 'ciudad'),
      );
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
  final int id;
  final RequestStatus status;
  final CancellationCause? cancellationCause;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RequestDonationSummary donation;
}

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
  final RequestUserSummary donor;

  factory SentRequestListItem.fromJson(Map<String, dynamic> json) {
    final common = _RequestFields.fromJson(json);
    return SentRequestListItem(
      id: common.id,
      status: common.status,
      cancellationCause: common.cancellationCause,
      acceptedAt: common.acceptedAt,
      rejectedAt: common.rejectedAt,
      cancelledAt: common.cancelledAt,
      createdAt: common.createdAt,
      updatedAt: common.updatedAt,
      donation: common.donation,
      donor: RequestUserSummary.fromJson(_map(json, 'donante')),
    );
  }
}

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
  final RequestUserSummary applicant;

  factory ReceivedRequestListItem.fromJson(Map<String, dynamic> json) {
    final common = _RequestFields.fromJson(json);
    return ReceivedRequestListItem(
      id: common.id,
      status: common.status,
      cancellationCause: common.cancellationCause,
      acceptedAt: common.acceptedAt,
      rejectedAt: common.rejectedAt,
      cancelledAt: common.cancelledAt,
      createdAt: common.createdAt,
      updatedAt: common.updatedAt,
      donation: common.donation,
      applicant: RequestUserSummary.fromJson(_map(json, 'solicitante')),
    );
  }
}

enum RequestActor { applicant, owner }

class CreatedRequest {
  const CreatedRequest({
    required this.id,
    required this.status,
    required this.donation,
  });

  final int id;
  final RequestStatus status;
  final RequestDonationSummary donation;

  factory CreatedRequest.fromJson(Map<String, dynamic> json) => CreatedRequest(
    id: _int(json, 'id'),
    status: RequestStatusJson.fromJson(json['estado']),
    donation: RequestDonationSummary.fromJson(_map(json, 'donacion')),
  );
}

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
  });
  final RequestActor actor;
  final RequestUserSummary otherUser;

  bool get canAcceptOrReject =>
      actor == RequestActor.owner &&
      status == RequestStatus.pendiente &&
      donation.status == RequestDonationStatus.publicada;
  bool get canCancel =>
      actor == RequestActor.applicant && status == RequestStatus.pendiente;

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    final donor = json['donante'];
    final applicant = json['solicitante'];
    final hasDonor = donor is Map<String, dynamic>;
    final hasApplicant = applicant is Map<String, dynamic>;
    if (hasDonor == hasApplicant) {
      throw const FormatException('Actor de solicitud inconsistente.');
    }
    final common = _RequestFields.fromJson(json);
    return RequestDetail(
      id: common.id,
      status: common.status,
      cancellationCause: common.cancellationCause,
      acceptedAt: common.acceptedAt,
      rejectedAt: common.rejectedAt,
      cancelledAt: common.cancelledAt,
      createdAt: common.createdAt,
      updatedAt: common.updatedAt,
      donation: common.donation,
      actor: hasDonor ? RequestActor.applicant : RequestActor.owner,
      otherUser: RequestUserSummary.fromJson(
        (hasDonor ? donor : applicant) as Map<String, dynamic>,
      ),
    );
  }
}

class RequestPagination {
  const RequestPagination({
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
  factory RequestPagination.fromJson(Map<String, dynamic> json) =>
      RequestPagination(
        page: _int(json, 'page'),
        limit: _int(json, 'limit'),
        total: _int(json, 'total'),
        totalPages: _int(json, 'totalPages'),
      );
}

class RequestPage<T extends RequestListItem> {
  const RequestPage({required this.requests, required this.pagination});
  final List<T> requests;
  final RequestPagination pagination;

  factory RequestPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final requests = json['solicitudes'];
    final pagination = json['pagination'];
    if (requests is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Listado de solicitudes inválido.');
    }
    return RequestPage(
      requests: requests
          .map((value) {
            if (value is! Map<String, dynamic>) {
              throw const FormatException('Solicitud inválida.');
            }
            return parse(value);
          })
          .toList(growable: false),
      pagination: RequestPagination.fromJson(pagination),
    );
  }
}

class _RequestFields {
  const _RequestFields({
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
  final int id;
  final RequestStatus status;
  final CancellationCause? cancellationCause;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RequestDonationSummary donation;

  factory _RequestFields.fromJson(Map<String, dynamic> json) => _RequestFields(
    id: _int(json, 'id'),
    status: RequestStatusJson.fromJson(json['estado']),
    cancellationCause: CancellationCauseJson.fromJson(json['causaCancelacion']),
    acceptedAt: _nullableDate(json, 'aceptadaAt'),
    rejectedAt: _nullableDate(json, 'rechazadaAt'),
    cancelledAt: _nullableDate(json, 'canceladaAt'),
    createdAt: _date(json, 'createdAt'),
    updatedAt: _date(json, 'updatedAt'),
    donation: RequestDonationSummary.fromJson(_map(json, 'donacion')),
  );
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
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

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
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

DateTime? _nullableDate(Map<String, dynamic> json, String key) {
  if (json[key] == null) return null;
  return _date(json, key);
}
