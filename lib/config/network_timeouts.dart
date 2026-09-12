/// Total HTTP exchange deadlines, not independent socket/receive timeouts.
/// Each includes connection, request sending, response headers and full body.
abstract final class NetworkTimeouts {
  static const apiResponse = Duration(seconds: 15);
  static const imageUpload = Duration(seconds: 120);
  static const imageDownload = Duration(seconds: 30);
}
