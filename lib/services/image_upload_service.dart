import 'dart:async';
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../models/api_json.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/network_timeouts.dart';

import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

part 'image_upload_service.g.dart';

const maxDonationImages = 5;
const maxDonationImageBytes = 5 * 1024 * 1024;

enum CloudinaryFailure {
  timeout,
  invalidSignature,
  invalidApiKey,
  invalidImage,
  rejected,
  rateLimited,
  unavailable,
}

/// Retains only a safe classification, never the signed request or raw body.
class CloudinaryUploadException extends ApiException {
  const CloudinaryUploadException(
    super.type,
    super.message, {
    required this.failure,
    super.statusCode,
  });

  final CloudinaryFailure failure;
}

const _uploadTimeout = CloudinaryUploadException(
  ApiErrorType.timeout,
  'La subida de la imagen está tardando más de lo esperado. '
  'Verifica tu conexión e intenta nuevamente.',
  failure: CloudinaryFailure.timeout,
);

@JsonSerializable()
class CloudinaryUploadAuthorization {
  const CloudinaryUploadAuthorization({
    required this.uploadUrl,
    required this.apiKey,
    required this.timestamp,
    required this.signature,
    required this.folder,
    required this.allowedFormats,
  });

  final Uri uploadUrl;
  final String apiKey;
  @JsonKey(fromJson: strictInt)
  final int timestamp;
  final String signature;
  final String folder;
  final String allowedFormats;

  factory CloudinaryUploadAuthorization.fromJson(Map<String, dynamic> json) =>
      apiDecode(() {
        final value = _$CloudinaryUploadAuthorizationFromJson(json);
        if (value.uploadUrl.scheme != 'https' ||
            value.uploadUrl.host != 'api.cloudinary.com' ||
            !value.uploadUrl.path.endsWith('/image/upload') ||
            value.apiKey.isEmpty ||
            value.signature.isEmpty ||
            value.folder != 'donapp/donaciones' ||
            value.allowedFormats != 'jpg,jpeg,png,webp') {
          throw const FormatException('Invalid image upload authorization.');
        }
        return value;
      });
  Map<String, dynamic> toJson() => _$CloudinaryUploadAuthorizationToJson(this);
}

class ImageUploadService {
  ImageUploadService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    http.Client? uploadClient,
  }) : _apiClient = tokenStorage != null
           ? (apiClient ?? ApiClient()).withTokenStorage(tokenStorage)
           : apiClient ?? ApiClient(tokenStorage: TokenStorage()),
       _uploadClient = uploadClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _uploadClient;

  Future<CloudinaryUploadAuthorization> requestAuthorization() async {
    try {
      final body = await _apiClient.post(
        '/api/imagenes/firma',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      final data = body['data'];
      if (data is! Map<String, dynamic>) throw const FormatException();
      return CloudinaryUploadAuthorization.fromJson(data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    if (images.isEmpty || images.length > maxDonationImages) {
      throw const ApiException(
        ApiErrorType.validation,
        'Selecciona entre 1 y 5 imágenes.',
      );
    }
    for (final image in images) {
      await validateImage(image);
    }
    final authorization = await requestAuthorization();
    final references = <String>[];
    for (final image in images) {
      references.add(await _uploadImage(image, authorization));
    }
    return List.unmodifiable(references);
  }

  Future<void> validateImage(XFile image) async {
    final extension = _extension(image.name);
    final mimeType = image.mimeType?.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension) &&
        !const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw const ApiException(
        ApiErrorType.validation,
        'Usa imágenes JPG, PNG o WEBP.',
      );
    }
    final length = await image.length();
    if (length <= 0 || length > maxDonationImageBytes) {
      throw const ApiException(
        ApiErrorType.validation,
        'Cada imagen debe pesar como máximo 5 MB.',
      );
    }
  }

  Future<String> _uploadImage(
    XFile image,
    CloudinaryUploadAuthorization authorization,
  ) async {
    final abort = Completer<void>();
    try {
      final bytes = await image.readAsBytes();
      final request =
          http.AbortableMultipartRequest(
              'POST',
              authorization.uploadUrl,
              abortTrigger: abort.future,
            )
            ..fields.addAll({
              'api_key': authorization.apiKey,
              'timestamp': '${authorization.timestamp}',
              'signature': authorization.signature,
              'folder': authorization.folder,
              'allowed_formats': authorization.allowedFormats,
            })
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: image.name.isEmpty
                    ? 'donacion.${_mimeSubtype(image)}'
                    : image.name,
                contentType: http.MediaType('image', _mimeSubtype(image)),
              ),
            );
      // A real mobile upload exceeded 30 seconds. Bound the entire exchange,
      // including the response body, without changing the backend timeouts.
      final response = await _sendUpload(request).timeout(
        NetworkTimeouts.imageUpload,
        onTimeout: () {
          abort.complete();
          throw TimeoutException('Image upload');
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _cloudinaryError(response);
      }
      final decoded = jsonDecode(response.body);
      final secureUrl = decoded is Map<String, dynamic>
          ? decoded['secure_url']
          : null;
      final uri = secureUrl is String ? Uri.tryParse(secureUrl) : null;
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return uri.toString();
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiErrorMapper.network;
    } on TimeoutException {
      throw _uploadTimeout;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<http.Response> _sendUpload(http.BaseRequest request) async {
    final streamed = await _uploadClient.send(request);
    return http.Response.fromStream(streamed);
  }

  CloudinaryUploadException _cloudinaryError(http.Response response) {
    String message = '';
    try {
      final body = jsonDecode(response.body);
      final error = body is Map<String, dynamic> ? body['error'] : null;
      final value = error is Map<String, dynamic> ? error['message'] : null;
      if (value is String) message = value.toLowerCase();
    } on FormatException {
      // HTML/proxy errors must use the same safe status classification.
    }
    final status = response.statusCode;
    final failure = switch (status) {
      408 => CloudinaryFailure.timeout,
      429 => CloudinaryFailure.rateLimited,
      >= 500 => CloudinaryFailure.unavailable,
      _ when message.contains('invalid signature') =>
        CloudinaryFailure.invalidSignature,
      _
          when message.contains('invalid api_key') ||
              message.contains('unknown api_key') =>
        CloudinaryFailure.invalidApiKey,
      _
          when message.contains('invalid image') ||
              message.contains('not allowed') =>
        CloudinaryFailure.invalidImage,
      _ => CloudinaryFailure.rejected,
    };
    final type = switch (failure) {
      CloudinaryFailure.timeout => ApiErrorType.timeout,
      CloudinaryFailure.rateLimited => ApiErrorType.rateLimited,
      CloudinaryFailure.unavailable => ApiErrorType.server,
      CloudinaryFailure.invalidSignature ||
      CloudinaryFailure.invalidApiKey => ApiErrorType.configuration,
      _ when status == 401 || status == 403 || status == 404 =>
        ApiErrorType.configuration,
      _ when status >= 400 && status < 500 => ApiErrorType.validation,
      _ => ApiErrorType.unexpectedResponse,
    };
    return CloudinaryUploadException(
      type,
      failure == CloudinaryFailure.timeout
          ? _uploadTimeout.message
          : 'No pudimos subir una de las imágenes. Intenta nuevamente.',
      failure: failure,
      statusCode: status,
    );
  }

  String _extension(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  String _mimeSubtype(XFile image) {
    final mimeSubtype = image.mimeType?.split('/').last.toLowerCase();
    if (const {'jpeg', 'png', 'webp'}.contains(mimeSubtype)) {
      return mimeSubtype!;
    }
    final extension = _extension(image.name);
    return extension == 'jpg' ? 'jpeg' : extension;
  }
}

abstract interface class DonationGalleryPicker {
  Future<List<XFile>> pickImages();
  Future<List<XFile>> retrieveLostImages();
}

class ImagePickerGallery implements DonationGalleryPicker {
  ImagePickerGallery({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<List<XFile>> pickImages() => _picker.pickMultiImage(imageQuality: 85);

  @override
  Future<List<XFile>> retrieveLostImages() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.exception != null) return const [];
    return response.files ?? const [];
  }
}
