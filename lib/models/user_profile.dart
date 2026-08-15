class UserProfile {
  const UserProfile({
    required this.id,
    required this.nombreCompleto,
    required this.nombreVisible,
    required this.email,
    required this.ciudad,
    required this.telefono,
    required this.fotoPerfil,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    required this.rol,
  });

  final int id;
  final String nombreCompleto;
  final String nombreVisible;
  final String email;
  final String ciudad;
  final String? telefono;
  final String? fotoPerfil;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileRole rol;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final telefono = json['telefono'];
    final fotoPerfil = json['fotoPerfil'];
    if (telefono != null && telefono is! String) {
      throw const FormatException('telefono tiene un formato inválido.');
    }
    if (fotoPerfil != null && fotoPerfil is! String) {
      throw const FormatException('fotoPerfil tiene un formato inválido.');
    }
    return UserProfile(
      id: _int(json, 'id'),
      nombreCompleto: _string(json, 'nombreCompleto'),
      nombreVisible: _string(json, 'nombreVisible'),
      email: _string(json, 'email'),
      ciudad: _string(json, 'ciudad'),
      telefono: telefono as String?,
      fotoPerfil: fotoPerfil as String?,
      activo: _bool(json, 'activo'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      rol: ProfileRole.fromJson(_map(json, 'rol')),
    );
  }
}

class ProfileRole {
  const ProfileRole({required this.codigo, required this.nombre});
  final String codigo;
  final String nombre;

  factory ProfileRole.fromJson(Map<String, dynamic> json) => ProfileRole(
    codigo: _string(json, 'codigo'),
    nombre: _string(json, 'nombre'),
  );
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key tiene un formato inválido.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return parsed;
}
