import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

const maxDonationImages = 5;
const maxDonationImageBytes = 5 * 1024 * 1024;

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
  final int timestamp;
  final String signature;
  final String folder;
  final String allowedFormats;

  factory CloudinaryUploadAuthorization.fromJson(Map<String, dynamic> json) {
    final uploadUrl = Uri.tryParse(json['uploadUrl'] as String? ?? '');
    final apiKey = json['apiKey'];
    final timestamp = json['timestamp'];
    final signature = json['signature'];
    final folder = json['folder'];
    final allowedFormats = json['allowedFormats'];
    if (uploadUrl == null ||
        uploadUrl.scheme != 'https' ||
        uploadUrl.host != 'api.cloudinary.com' ||
        !uploadUrl.path.endsWith('/image/upload') ||
        apiKey is! String ||
        apiKey.isEmpty ||
        timestamp is! int ||
        signature is! String ||
        signature.isEmpty ||
        folder != 'donapp/donaciones' ||
        allowedFormats != 'jpg,jpeg,png,webp') {
      throw const FormatException();
    }
    return CloudinaryUploadAuthorization(
      uploadUrl: uploadUrl,
      apiKey: apiKey,
      timestamp: timestamp,
      signature: signature,
      folder: folder as String,
      allowedFormats: allowedFormats as String,
    );
  }
}

class ImageUploadService {
  ImageUploadService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    http.Client? uploadClient,
  }) : _apiClient = apiClient ?? ApiClient(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _uploadClient = uploadClient ?? http.Client();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final http.Client _uploadClient;

  Future<CloudinaryUploadAuthorization> requestAuthorization() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        ApiErrorType.authentication,
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    try {
      final body = await _apiClient.post(
        '/api/imagenes/firma',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
    try {
      final request = http.MultipartRequest('POST', authorization.uploadUrl)
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
            await image.readAsBytes(),
            filename: image.name.isEmpty
                ? 'donacion.${_mimeSubtype(image)}'
                : image.name,
            contentType: http.MediaType('image', _mimeSubtype(image)),
          ),
        );
      final streamed = await _uploadClient
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException(
          ApiErrorType.server,
          'No pudimos subir una de las imágenes. Intenta nuevamente.',
        );
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
      throw ApiErrorMapper.timeout;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
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
