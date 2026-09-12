import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'auth_session.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
    required this.usuario,
  });

  @JsonKey(fromJson: nonEmptyString)
  final String accessToken;
  @JsonKey(fromJson: nonEmptyString)
  final String refreshToken;
  @JsonKey(fromJson: strictInt)
  final int accessTokenExpiresIn;
  @JsonKey(fromJson: strictInt)
  final int refreshTokenExpiresIn;
  final AuthUser usuario;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$AuthSessionFromJson(json));
  Map<String, dynamic> toJson() => _$AuthSessionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombreVisible,
    required this.fotoPerfil,
    required this.rol,
  });

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(fromJson: nonEmptyString)
  final String nombreVisible;
  final String? fotoPerfil;
  final AuthRole rol;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$AuthUserFromJson(json));
  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AuthRole {
  const AuthRole({required this.codigo, required this.nombre});
  @JsonKey(fromJson: nonEmptyString)
  final String codigo;
  @JsonKey(fromJson: nonEmptyString)
  final String nombre;

  factory AuthRole.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$AuthRoleFromJson(json));
  Map<String, dynamic> toJson() => _$AuthRoleToJson(this);
}
