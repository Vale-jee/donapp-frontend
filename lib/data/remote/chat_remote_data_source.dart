import '../../models/chat.dart';
import '../../services/chat_service.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource([ChatService? service])
    : _service = service ?? ChatService();
  final ChatService _service;

  Future<ChatPage<Chat>> listChats() => _service.listChats();
  Future<Chat> createForRequest(int requestId) =>
      _service.createForRequest(requestId);
  Future<Chat> getChat(int chatId) => _service.getChat(chatId);
  Future<ChatPage<ChatMessage>> listMessages(int chatId) =>
      _service.listMessages(chatId);
  Future<ChatMessage> sendMessage(int chatId, String content) =>
      _service.sendMessage(chatId, content);
}
