import '../data/remote/chat_remote_data_source.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatRepository {
  ChatRepository({ChatRemoteDataSource? remote})
    : _remote = remote ?? ChatRemoteDataSource();
  final ChatRemoteDataSource _remote;

  factory ChatRepository.fromService(ChatService service) =>
      ChatRepository(remote: ChatRemoteDataSource(service));

  Future<ChatPage<Chat>> listChats() => _remote.listChats();
  Future<Chat> createForRequest(int requestId) =>
      _remote.createForRequest(requestId);
  Future<Chat> getChat(int chatId) => _remote.getChat(chatId);
  Future<ChatPage<ChatMessage>> listMessages(int chatId) =>
      _remote.listMessages(chatId);
  Future<ChatMessage> sendMessage(int chatId, String content) =>
      _remote.sendMessage(chatId, content);
}
