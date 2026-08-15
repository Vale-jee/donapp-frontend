class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
    required this.usuario,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final int refreshTokenExpiresIn;
  final AuthUser usuario;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: _requiredString(json, 'accessToken'),
    refreshToken: _requiredString(json, 'refreshToken'),
    accessTokenExpiresIn: _requiredInt(json, 'accessTokenExpiresIn'),
    refreshTokenExpiresIn: _requiredInt(json, 'refreshTokenExpiresIn'),
    usuario: AuthUser.fromJson(_requiredMap(json, 'usuario')),
  );
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombreVisible,
    required this.fotoPerfil,
    required this.rol,
  });

  final int id;
  final String nombreVisible;
  final String? fotoPerfil;
  final AuthRole rol;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final fotoPerfil = json['fotoPerfil'];
    if (fotoPerfil != null && fotoPerfil is! String) {
      throw const FormatException('fotoPerfil tiene un formato inválido.');
    }
    return AuthUser(
      id: _requiredInt(json, 'id'),
      nombreVisible: _requiredString(json, 'nombreVisible'),
      fotoPerfil: fotoPerfil as String?,
      rol: AuthRole.fromJson(_requiredMap(json, 'rol')),
    );
  }
}

class AuthRole {
  const AuthRole({required this.codigo, required this.nombre});
  final String codigo;
  final String nombre;

  factory AuthRole.fromJson(Map<String, dynamic> json) => AuthRole(
    codigo: _requiredString(json, 'codigo'),
    nombre: _requiredString(json, 'nombre'),
  );
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key tiene un formato inválido.');
  return value;
}
