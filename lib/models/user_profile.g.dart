// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: strictInt(json['id']),
  nombreCompleto: nonEmptyString(json['nombreCompleto']),
  nombreVisible: nonEmptyString(json['nombreVisible']),
  email: nonEmptyString(json['email']),
  ciudad: nonEmptyString(json['ciudad']),
  telefono: json['telefono'] as String?,
  fotoPerfil: json['fotoPerfil'] as String?,
  activo: json['activo'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  rol: ProfileRole.fromJson(json['rol'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombreCompleto': instance.nombreCompleto,
      'nombreVisible': instance.nombreVisible,
      'email': instance.email,
      'ciudad': instance.ciudad,
      'telefono': instance.telefono,
      'fotoPerfil': instance.fotoPerfil,
      'activo': instance.activo,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'rol': instance.rol.toJson(),
    };

ProfileRole _$ProfileRoleFromJson(Map<String, dynamic> json) => ProfileRole(
  codigo: nonEmptyString(json['codigo']),
  nombre: nonEmptyString(json['nombre']),
);

Map<String, dynamic> _$ProfileRoleToJson(ProfileRole instance) =>
    <String, dynamic>{'codigo': instance.codigo, 'nombre': instance.nombre};
