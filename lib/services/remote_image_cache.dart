import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../config/network_timeouts.dart';
import 'api_exception.dart';

class RemoteImageCache {
  RemoteImageCache({
    http.Client? client,
    this.timeout = NetworkTimeouts.imageDownload,
    Future<Directory> Function()? cacheDirectory,
  }) : _client = client ?? http.Client(),
       _cacheDirectory = cacheDirectory ?? defaultDirectory;

  static const directoryName = 'remote_donation_images';
  final http.Client _client;
  final Duration timeout;
  final Future<Directory> Function() _cacheDirectory;

  static Future<Directory> defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, directoryName));
  }

  Future<String> cache({
    required int cacheUserId,
    required int donationId,
    required int imageId,
    required String reference,
  }) async {
    final uri = ApiConfig.resolveImageReference(reference);
    if (uri == null) {
      throw const FormatException('Referencia de imagen inválida.');
    }

    final directory = await _cacheDirectory();
    await directory.create(recursive: true);
    final target = File(
      p.join(directory.path, 'u${cacheUserId}_d${donationId}_i$imageId.image'),
    );
    if (await target.exists() && await target.length() > 0) return target.path;

    final temporary = File('${target.path}.download');
    try {
      // Client.get completes only after the full body has been collected.
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('No se pudo descargar la imagen.');
      }
      if (response.bodyBytes.isEmpty) {
        throw const FormatException('La imagen descargada está vacía.');
      }
      await temporary.writeAsBytes(response.bodyBytes, flush: true);
      if (await target.exists()) await target.delete();
      return (await temporary.rename(target.path)).path;
    } on Object catch (error) {
      if (await temporary.exists()) await temporary.delete();
      if (error is TimeoutException) {
        throw const ApiException(
          ApiErrorType.timeout,
          'La descarga de la imagen está tardando más de lo esperado. '
          'Verifica tu conexión e intenta nuevamente.',
        );
      }
      rethrow;
    }
  }
}
