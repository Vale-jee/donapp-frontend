import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/chat.dart';
import '../navigation/app_router.dart';
import '../repositories/chat_repository.dart';
import '../services/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({required this.chatRepository, super.key});
  final ChatRepository chatRepository;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _loading = true;
  String? _error;
  List<Chat> _chats = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final page = await widget.chatRepository.listChats();
      if (!mounted) return;
      setState(() { _chats = page.items; _loading = false; });
    } on ApiException catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No pudimos cargar tus conversaciones.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors = Theme.of(context).extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: SafeArea(
        child: _loading
            ? const Center(child: AppContentState(type: AppContentStateType.loading, title: 'Cargando conversaciones'))
            : _error != null
            ? Center(child: AppContentState(type: AppContentStateType.error, title: 'No pudimos cargar tus conversaciones', message: _error, actionText: 'Reintentar', onAction: _load))
            : _chats.isEmpty
            ? const Center(child: AppContentState(type: AppContentStateType.empty, title: 'No tienes conversaciones', message: 'Los chats aparecen después de aceptar una solicitud.'))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: EdgeInsets.all(spacing.large),
                  itemCount: _chats.length,
                  separatorBuilder: (_, _) => SizedBox(height: spacing.small),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return Card(
                      child: ListTile(
                        contentPadding: EdgeInsets.all(spacing.medium),
                        leading: CircleAvatar(
                          backgroundColor: colors.background,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(chat.otroParticipante.nombreVisible.characters.first.toUpperCase()),
                        ),
                        title: Text(chat.otroParticipante.nombreVisible),
                        subtitle: Text(chat.donacion.titulo),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.chatLocation(chat.id)),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
