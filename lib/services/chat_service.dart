import '../models/chat.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class ChatService {
  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;
  static const _headers = {'Accept': 'application/json'};

  Future<ChatPage<Chat>> listChats({int page = 1, int limit = 20}) async {
    final body = await _get('/api/chats', page: page, limit: limit);
    final data = _data(body);
    return ChatPage(
      items: _list(data, 'chats').map(Chat.fromJson).toList(growable: false),
      totalPages: _pagination(data),
    );
  }

  Future<Chat> createForRequest(int requestId) async {
    if (requestId <= 0) throw _invalidId;
    try {
      final body = await _apiClient.post(
        '/api/solicitudes/$requestId/chat',
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: const {},
        successStatusCodes: const {200, 201},
        context: ApiRequestContext.protectedSession,
        allowSafeBackendMessage: true,
      );
      return Chat.fromJson(_data(body)['chat'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<Chat> getChat(int chatId) async {
    final body = await _apiClient.get(
      '/api/chats/$chatId',
      headers: _headers,
      successStatusCodes: const {200},
      context: ApiRequestContext.protectedSession,
    );
    return Chat.fromJson(_data(body)['chat'] as Map<String, dynamic>);
  }

  Future<ChatPage<ChatMessage>> listMessages(
    int chatId, {
    int page = 1,
    int limit = 100,
  }) async {
    final body = await _get('/api/chats/$chatId/mensajes', page: page, limit: limit);
    final data = _data(body);
    return ChatPage(
      items: _list(data, 'mensajes').map(ChatMessage.fromJson).toList(growable: false),
      totalPages: _pagination(data),
    );
  }

  Future<ChatMessage> sendMessage(int chatId, String content) async {
    try {
      final body = await _apiClient.post(
        '/api/chats/$chatId/mensajes',
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: {'contenido': content},
        successStatusCodes: const {201},
        context: ApiRequestContext.protectedSession,
        allowSafeBackendMessage: true,
      );
      return ChatMessage.fromJson(_data(body)['mensaje'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required int page,
    required int limit,
  }) async {
    try {
      return await _apiClient.get(
        path,
        headers: _headers,
        queryParameters: {'page': '$page', 'limit': '$limit'},
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) throw ApiErrorMapper.unexpectedResponse;
    return data;
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! List) throw ApiErrorMapper.unexpectedResponse;
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  int _pagination(Map<String, dynamic> data) {
    final pagination = data['pagination'];
    if (pagination is! Map<String, dynamic> || pagination['totalPages'] is! int) {
      throw ApiErrorMapper.unexpectedResponse;
    }
    return pagination['totalPages'] as int;
  }

  static const _invalidId = ApiException(
    ApiErrorType.validation,
    'El chat no es válido.',
  );
}
