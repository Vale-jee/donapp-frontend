// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => AuthSession(
  accessToken: nonEmptyString(json['accessToken']),
  refreshToken: nonEmptyString(json['refreshToken']),
  accessTokenExpiresIn: strictInt(json['accessTokenExpiresIn']),
  refreshTokenExpiresIn: strictInt(json['refreshTokenExpiresIn']),
  usuario: AuthUser.fromJson(json['usuario'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthSessionToJson(AuthSession instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'accessTokenExpiresIn': instance.accessTokenExpiresIn,
      'refreshTokenExpiresIn': instance.refreshTokenExpiresIn,
      'usuario': instance.usuario.toJson(),
    };

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => AuthUser(
  id: strictInt(json['id']),
  nombreVisible: nonEmptyString(json['nombreVisible']),
  fotoPerfil: json['fotoPerfil'] as String?,
  rol: AuthRole.fromJson(json['rol'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'nombreVisible': instance.nombreVisible,
  'fotoPerfil': instance.fotoPerfil,
  'rol': instance.rol.toJson(),
};

AuthRole _$AuthRoleFromJson(Map<String, dynamic> json) => AuthRole(
  codigo: nonEmptyString(json['codigo']),
  nombre: nonEmptyString(json['nombre']),
);

Map<String, dynamic> _$AuthRoleToJson(AuthRole instance) => <String, dynamic>{
  'codigo': instance.codigo,
  'nombre': instance.nombre,
};
