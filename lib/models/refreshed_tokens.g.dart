// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refreshed_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshedTokens _$RefreshedTokensFromJson(Map<String, dynamic> json) =>
    RefreshedTokens(
      accessToken: nonEmptyString(json['accessToken']),
      refreshToken: nonEmptyString(json['refreshToken']),
      accessTokenExpiresIn: strictInt(json['accessTokenExpiresIn']),
      refreshTokenExpiresIn: strictInt(json['refreshTokenExpiresIn']),
    );

Map<String, dynamic> _$RefreshedTokensToJson(RefreshedTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'accessTokenExpiresIn': instance.accessTokenExpiresIn,
      'refreshTokenExpiresIn': instance.refreshTokenExpiresIn,
    };
