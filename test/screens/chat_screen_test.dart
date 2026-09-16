import 'package:donapp_mobile/models/chat.dart';
import 'package:donapp_mobile/repositories/chat_repository.dart';
import 'package:donapp_mobile/screens/chat_detail_screen.dart';
import 'package:donapp_mobile/screens/chats_screen.dart';
import 'package:donapp_mobile/services/chat_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra conversaciones y abre el detalle', (tester) async {
    final service = _FakeChatService();
    await tester.pumpWidget(_app(ChatsScreen(
      chatRepository: ChatRepository.fromService(service),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Vale'), findsOneWidget);
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('muestra estado vacío sin conversaciones', (tester) async {
    final service = _FakeChatService(empty: true);
    await tester.pumpWidget(_app(ChatsScreen(
      chatRepository: ChatRepository.fromService(service),
    )));
    await tester.pumpAndSettle();

    expect(find.text('No tienes conversaciones'), findsOneWidget);
  });

  testWidgets('envía un mensaje y evita doble envío', (tester) async {
    final service = _FakeChatService();
    await tester.pumpWidget(_app(ChatDetailScreen(
      chatId: 7,
      currentUserId: 1,
      chatRepository: ChatRepository.fromService(service),
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.pumpAndSettle();

    expect(service.sendCount, 1);
    expect(find.text('Hola'), findsOneWidget);
  });
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

final _chat = Chat(
  id: 7,
  solicitudId: 3,
  createdAt: DateTime.utc(2026, 9, 1),
  ultimoMensajeAt: null,
  donacion: const ChatDonation(
    id: 8,
    titulo: 'Bicicleta',
    estado: 'RESERVADA',
    imagenPrincipal: null,
  ),
  otroParticipante: const ChatParticipant(
    id: 2,
    nombreVisible: 'Vale',
    fotoPerfil: null,
    ciudad: 'Quito',
  ),
);

class _FakeChatService extends ChatService {
  _FakeChatService({this.empty = false});

  final bool empty;
  int sendCount = 0;
  final List<ChatMessage> messages = [];

  @override
  Future<ChatPage<Chat>> listChats({int page = 1, int limit = 20}) async =>
      ChatPage(items: empty ? const [] : [_chat], totalPages: 1);

  @override
  Future<Chat> getChat(int chatId) async => _chat;

  @override
  Future<ChatPage<ChatMessage>> listMessages(
    int chatId, {
    int page = 1,
    int limit = 100,
  }) async => ChatPage(items: List.of(messages), totalPages: 1);

  @override
  Future<ChatMessage> sendMessage(int chatId, String content) async {
    sendCount++;
    final message = ChatMessage(
      id: sendCount,
      contenido: content,
      createdAt: DateTime.utc(2026, 9, 1),
      remitenteId: 1,
      remitenteNombre: 'yo',
    );
    messages.add(message);
    return message;
  }
}
