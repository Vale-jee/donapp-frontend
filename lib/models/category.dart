import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'category.g.dart';

@JsonSerializable(explicitToJson: true)
class Category {
  const Category({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });
  @JsonKey(fromJson: strictInt)
  final int id;
  final String nombre;
  final String? descripcion;

  factory Category.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$CategoryFromJson(json));
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
