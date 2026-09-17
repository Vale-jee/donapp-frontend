class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.nombreVisible,
    required this.fotoPerfil,
    required this.ciudad,
  });

  final int id;
  final String nombreVisible;
  final String? fotoPerfil;
  final String ciudad;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) => ChatParticipant(
    id: json['id'] as int,
    nombreVisible: json['nombreVisible'] as String,
    fotoPerfil: json['fotoPerfil'] as String?,
    ciudad: json['ciudad'] as String,
  );
}

class ChatDonation {
  const ChatDonation({
    required this.id,
    required this.titulo,
    required this.estado,
    required this.imagenPrincipal,
  });

  final int id;
  final String titulo;
  final String estado;
  final String? imagenPrincipal;

  factory ChatDonation.fromJson(Map<String, dynamic> json) => ChatDonation(
    id: json['id'] as int,
    titulo: json['titulo'] as String,
    estado: json['estado'] as String,
    imagenPrincipal: json['imagenPrincipal'] as String?,
  );
}

class Chat {
  const Chat({
    required this.id,
    required this.solicitudId,
    required this.createdAt,
    required this.ultimoMensajeAt,
    required this.donacion,
    required this.otroParticipante,
  });

  final int id;
  final int solicitudId;
  final DateTime createdAt;
  final DateTime? ultimoMensajeAt;
  final ChatDonation donacion;
  final ChatParticipant otroParticipante;

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'] as int,
    solicitudId: json['solicitudId'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    ultimoMensajeAt: (json['ultimoMensajeAt'] as String?) == null
        ? null
        : DateTime.parse(json['ultimoMensajeAt'] as String),
    donacion: ChatDonation.fromJson(json['donacion'] as Map<String, dynamic>),
    otroParticipante: ChatParticipant.fromJson(
      json['otroParticipante'] as Map<String, dynamic>,
    ),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.contenido,
    required this.createdAt,
    required this.remitenteId,
    required this.remitenteNombre,
  });

  final int id;
  final String contenido;
  final DateTime createdAt;
  final int remitenteId;
  final String remitenteNombre;

  bool get isLocation => locationCoordinates != null;

  ({double latitude, double longitude})? get locationCoordinates {
    final match = _locationPattern.firstMatch(contenido);
    if (match == null) return null;
    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return null;
    }
    return (latitude: latitude, longitude: longitude);
  }

  double? get latitude => locationCoordinates?.latitude;
  double? get longitude => locationCoordinates?.longitude;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['remitente'] as Map<String, dynamic>;
    return ChatMessage(
      id: json['id'] as int,
      contenido: json['contenido'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      remitenteId: sender['id'] as int,
      remitenteNombre: sender['nombreVisible'] as String,
    );
  }

  static final RegExp _locationPattern = RegExp(
    r'^Ubicación aproximada: https://www\.google\.com/maps/search/\?api=1&query=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)$',
  );
}

class ChatPage<T> {
  const ChatPage({required this.items, required this.totalPages});
  final List<T> items;
  final int totalPages;
}
