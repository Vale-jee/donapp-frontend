import 'package:donapp_mobile/models/chat.dart';
import 'package:donapp_mobile/repositories/chat_repository.dart';
import 'package:donapp_mobile/screens/chat_detail_screen.dart';
import 'package:donapp_mobile/screens/chats_screen.dart';
import 'package:donapp_mobile/services/chat_service.dart';
import 'package:donapp_mobile/services/location_share_service.dart';
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

  testWidgets('comparte ubicación aproximada y la muestra como mensaje', (tester) async {
    final service = _FakeChatService();
    final location = _FakeLocationShareService(
      const LocationShareResult.granted(latitude: -0.1807, longitude: -78.4678),
    );
    await tester.pumpWidget(_app(ChatDetailScreen(
      chatId: 7,
      currentUserId: 1,
      chatRepository: ChatRepository.fromService(service),
      locationShareService: location,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareChatLocationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Compartir ubicación'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continueShareLocationButton')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Confirmar ubicación'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmShareLocationButton')));
    await tester.pumpAndSettle();

    expect(service.locationSendCount, 1);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('-0.181, -78.468'), findsOneWidget);
  });

  testWidgets('degradación de ubicación denegada mantiene disponible el chat', (tester) async {
    final service = _FakeChatService();
    final location = _FakeLocationShareService(
      const LocationShareResult.denied(),
    );
    await tester.pumpWidget(_app(ChatDetailScreen(
      chatId: 7,
      currentUserId: 1,
      chatRepository: ChatRepository.fromService(service),
      locationShareService: location,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareChatLocationButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueShareLocationButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Permiso de ubicación denegado'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(service.locationSendCount, 0);
  });

  testWidgets('denegación permanente ofrece abrir ajustes', (tester) async {
    final service = _FakeChatService();
    final location = _FakeLocationShareService(
      const LocationShareResult.permanentlyDenied(),
    );
    await tester.pumpWidget(_app(ChatDetailScreen(
      chatId: 7,
      currentUserId: 1,
      chatRepository: ChatRepository.fromService(service),
      locationShareService: location,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareChatLocationButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueShareLocationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Permiso de ubicación bloqueado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openLocationAppSettingsButton')));
    await tester.pumpAndSettle();
    expect(location.appSettingsOpened, isTrue);
  });

  testWidgets('servicio de ubicación apagado ofrece abrir ajustes de ubicación', (tester) async {
    final service = _FakeChatService();
    final location = _FakeLocationShareService(
      const LocationShareResult.serviceDisabled(),
    );
    await tester.pumpWidget(_app(ChatDetailScreen(
      chatId: 7,
      currentUserId: 1,
      chatRepository: ChatRepository.fromService(service),
      locationShareService: location,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareChatLocationButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueShareLocationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación desactivada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openLocationSettingsButton')));
    await tester.pumpAndSettle();
    expect(location.locationSettingsOpened, isTrue);
  });

  testWidgets('ubicación no disponible mantiene usable el chat', (tester) async {
    final service = _FakeChatService();
    final location = _FakeLocationShareService(
      const LocationShareResult.unavailable(),
    );
    await tester.pumpWidget(
      _app(
        ChatDetailScreen(
          chatId: 7,
          currentUserId: 1,
          chatRepository: ChatRepository.fromService(service),
          locationShareService: location,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareChatLocationButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueShareLocationButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ubicación no está disponible'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(service.locationSendCount, 0);
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
  int locationSendCount = 0;
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

  @override
  Future<ChatMessage> sendLocation(
    int chatId, {
    required double latitude,
    required double longitude,
  }) async {
    locationSendCount++;
    final message = ChatMessage(
      id: 100 + locationSendCount,
      contenido:
          'Ubicación aproximada: https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}',
      createdAt: DateTime.utc(2026, 9, 1),
      remitenteId: 1,
      remitenteNombre: 'yo',
    );
    messages.add(message);
    return message;
  }
}

class _FakeLocationShareService implements LocationShareService {
  _FakeLocationShareService(this.result);

  final LocationShareResult result;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;

  @override
  Future<LocationShareResult> currentApproximateLocation() async => result;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}
