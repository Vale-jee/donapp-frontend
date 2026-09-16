import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../repositories/chat_repository.dart';
import '../services/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.chatId,
    required this.currentUserId,
    required this.chatRepository,
    super.key,
  });

  final int chatId;
  final int currentUserId;
  final ChatRepository chatRepository;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Chat? _chat;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.chatRepository.getChat(widget.chatId),
        widget.chatRepository.listMessages(widget.chatId),
      ]);
      if (!mounted) return;
      setState(() {
        _chat = results[0] as Chat;
        _messages = (results[1] as ChatPage<ChatMessage>).items.reversed.toList(growable: false);
        _loading = false;
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No pudimos cargar el chat.'; });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.chatRepository.sendMessage(widget.chatId, content);
      _messageController.clear();
      final page = await widget.chatRepository.listMessages(widget.chatId);
      if (!mounted) return;
      setState(() {
        _messages = page.items.reversed.toList(growable: false);
        _sending = false;
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos enviar el mensaje.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors = Theme.of(context).extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(title: Text(_chat?.otroParticipante.nombreVisible ?? 'Chat')),
      body: SafeArea(
        child: _loading
            ? const Center(child: AppContentState(type: AppContentStateType.loading, title: 'Cargando chat'))
            : _error != null
            ? Center(child: AppContentState(type: AppContentStateType.error, title: 'No pudimos cargar el chat', message: _error, actionText: 'Reintentar', onAction: _load))
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(child: AppContentState(type: AppContentStateType.empty, title: 'Aún no hay mensajes', message: 'Envía el primer mensaje.'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(spacing.large),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final own = message.remitenteId == widget.currentUserId;
                              return Align(
                                alignment: own ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  margin: EdgeInsets.only(bottom: spacing.small),
                                  padding: EdgeInsets.all(spacing.medium),
                                  decoration: BoxDecoration(
                                    color: own ? Theme.of(context).colorScheme.primary : colors.background,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    message.contenido,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: own ? Theme.of(context).colorScheme.onPrimary : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Material(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(spacing.medium, spacing.small, spacing.medium, spacing.medium),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: !_sending,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(hintText: 'Escribe un mensaje'),
                            ),
                          ),
                          IconButton(
                            key: const Key('sendChatMessageButton'),
                            tooltip: 'Enviar mensaje',
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
