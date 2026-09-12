import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'user_profile.g.dart';

@JsonSerializable(explicitToJson: true)
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

  @JsonKey(fromJson: strictInt)
  final int id;
  @JsonKey(fromJson: nonEmptyString)
  final String nombreCompleto;
  @JsonKey(fromJson: nonEmptyString)
  final String nombreVisible;
  @JsonKey(fromJson: nonEmptyString)
  final String email;
  @JsonKey(fromJson: nonEmptyString)
  final String ciudad;
  final String? telefono;
  final String? fotoPerfil;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileRole rol;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$UserProfileFromJson(json));
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileRole {
  const ProfileRole({required this.codigo, required this.nombre});
  @JsonKey(fromJson: nonEmptyString)
  final String codigo;
  @JsonKey(fromJson: nonEmptyString)
  final String nombre;

  factory ProfileRole.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$ProfileRoleFromJson(json));
  Map<String, dynamic> toJson() => _$ProfileRoleToJson(this);
}
