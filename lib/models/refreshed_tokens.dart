import 'package:json_annotation/json_annotation.dart';

import 'api_json.dart';

part 'refreshed_tokens.g.dart';

@JsonSerializable(explicitToJson: true)
class RefreshedTokens {
  const RefreshedTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
  });

  @JsonKey(fromJson: nonEmptyString)
  final String accessToken;
  @JsonKey(fromJson: nonEmptyString)
  final String refreshToken;
  @JsonKey(fromJson: strictInt)
  final int accessTokenExpiresIn;
  @JsonKey(fromJson: strictInt)
  final int refreshTokenExpiresIn;

  factory RefreshedTokens.fromJson(Map<String, dynamic> json) =>
      apiDecode(() => _$RefreshedTokensFromJson(json));
  Map<String, dynamic> toJson() => _$RefreshedTokensToJson(this);
}
