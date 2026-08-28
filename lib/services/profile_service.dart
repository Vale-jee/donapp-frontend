import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class ProfileService {
  ProfileService({http.Client? client, ApiClient? apiClient})
    : assert(client == null || apiClient == null),
      _apiClient = apiClient ?? ApiClient(client: client);

  final ApiClient _apiClient;

  Future<UserProfile> getProfile(String accessToken) async {
    try {
      final body = await _apiClient.get(
        '/api/usuarios/perfil',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      final data = body['data'];
      if (data is! Map<String, dynamic> ||
          data['usuario'] is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return UserProfile.fromJson(data['usuario'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }
}
