// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_upload_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CloudinaryUploadAuthorization _$CloudinaryUploadAuthorizationFromJson(
  Map<String, dynamic> json,
) => CloudinaryUploadAuthorization(
  uploadUrl: Uri.parse(json['uploadUrl'] as String),
  apiKey: json['apiKey'] as String,
  timestamp: strictInt(json['timestamp']),
  signature: json['signature'] as String,
  folder: json['folder'] as String,
  allowedFormats: json['allowedFormats'] as String,
);

Map<String, dynamic> _$CloudinaryUploadAuthorizationToJson(
  CloudinaryUploadAuthorization instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl.toString(),
  'apiKey': instance.apiKey,
  'timestamp': instance.timestamp,
  'signature': instance.signature,
  'folder': instance.folder,
  'allowedFormats': instance.allowedFormats,
};
