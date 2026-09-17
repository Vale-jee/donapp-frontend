import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat.dart';
import '../repositories/chat_repository.dart';
import '../services/api_exception.dart';
import '../services/location_share_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.chatId,
    required this.currentUserId,
    required this.chatRepository,
    this.locationShareService,
    super.key,
  });

  final int chatId;
  final int currentUserId;
  final ChatRepository chatRepository;
  final LocationShareService? locationShareService;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final LocationShareService _locationShareService =
      widget.locationShareService ?? GeolocatorLocationShareService();

  Chat? _chat;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  bool _sharingLocation = false;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.chatRepository.getChat(widget.chatId),
        widget.chatRepository.listMessages(widget.chatId),
      ]);
      if (!mounted) return;
      setState(() {
        _chat = results[0] as Chat;
        _messages = (results[1] as ChatPage<ChatMessage>).items.reversed
            .toList(growable: false);
        _loading = false;
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No pudimos cargar el chat.';
        });
      }
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
    if (_sending || _sharingLocation) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.chatRepository.sendMessage(widget.chatId, content);
      _messageController.clear();
      await _refreshMessages();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos enviar el mensaje.')),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    final page = await widget.chatRepository.listMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = page.items.reversed.toList(growable: false);
      _sending = false;
      _sharingLocation = false;
    });
    _scrollToEnd();
  }

  Future<void> _shareLocation() async {
    if (_sending || _sharingLocation) return;

    final continueRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir ubicación'),
        content: const Text(
          'DonnaP usará tu ubicación solo esta vez para compartirla en este chat y facilitar la coordinación de la entrega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('continueShareLocationButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (continueRequest != true || !mounted) return;

    setState(() => _sharingLocation = true);
    final result = await _locationShareService.currentApproximateLocation();
    if (!mounted) return;

    switch (result.status) {
      case LocationShareStatus.granted:
        final latitude = result.latitude;
        final longitude = result.longitude;
        if (latitude == null || longitude == null) {
          _showLocationError('No pudimos obtener tu ubicación.');
          return;
        }
        final confirmed = await _confirmLocation(latitude, longitude);
        if (confirmed != true || !mounted) {
          setState(() => _sharingLocation = false);
          return;
        }
        await _sendLocation(latitude, longitude);
        return;
      case LocationShareStatus.denied:
        setState(() => _sharingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de ubicación denegado. Puedes escribir el punto de encuentro en el chat.',
            ),
          ),
        );
        return;
      case LocationShareStatus.permanentlyDenied:
        setState(() => _sharingLocation = false);
        await _showLocationPermissionBlocked();
        return;
      case LocationShareStatus.serviceDisabled:
        setState(() => _sharingLocation = false);
        await _showLocationServiceDisabled();
        return;
      case LocationShareStatus.unavailable:
        setState(() => _sharingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La ubicación no está disponible en este dispositivo. Puedes escribir el punto de encuentro en el chat.',
            ),
          ),
        );
        return;
      case LocationShareStatus.error:
        _showLocationError(
          result.message ?? 'No pudimos obtener tu ubicación.',
        );
        return;
    }
  }

  Future<bool?> _confirmLocation(double latitude, double longitude) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar ubicación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se compartirá una ubicación, no una dirección escrita.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Latitud: ${latitude.toStringAsFixed(3)}'),
              Text('Longitud: ${longitude.toStringAsFixed(3)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              key: const Key('confirmShareLocationButton'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Compartir'),
            ),
          ],
        ),
      );

  Future<void> _sendLocation(double latitude, double longitude) async {
    try {
      await widget.chatRepository.sendLocation(
        widget.chatId,
        latitude: latitude,
        longitude: longitude,
      );
      await _refreshMessages();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _sharingLocation = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sharingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos compartir la ubicación.')),
        );
      }
    }
  }

  Future<void> _showLocationPermissionBlocked() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de ubicación bloqueado'),
        content: const Text(
          'Activa el permiso de ubicación desde los ajustes del sistema para compartir tu ubicación en el chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            key: const Key('openLocationAppSettingsButton'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _locationShareService.openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationServiceDisabled() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación desactivada'),
        content: const Text(
          'El servicio de ubicación del dispositivo está apagado. Puedes activarlo en los ajustes o escribir el punto de encuentro en el chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            key: const Key('openLocationSettingsButton'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _locationShareService.openLocationSettings();
            },
            child: const Text('Activar ubicación'),
          ),
        ],
      ),
    );
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    setState(() => _sharingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openMap(ChatMessage message) async {
    final latitude = message.latitude;
    final longitude = message.longitude;
    if (latitude == null || longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(
        title: Text(_chat?.otroParticipante.nombreVisible ?? 'Chat'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: AppContentState(
                  type: AppContentStateType.loading,
                  title: 'Cargando chat',
                ),
              )
            : _error != null
            ? Center(
                child: AppContentState(
                  type: AppContentStateType.error,
                  title: 'No pudimos cargar el chat',
                  message: _error,
                  actionText: 'Reintentar',
                  onAction: _load,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(
                            child: AppContentState(
                              type: AppContentStateType.empty,
                              title: 'Aún no hay mensajes',
                              message: 'Envía el primer mensaje.',
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(spacing.large),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final own =
                                  message.remitenteId == widget.currentUserId;
                              return Align(
                                alignment: own
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom: spacing.small,
                                  ),
                                  padding: EdgeInsets.all(spacing.medium),
                                  decoration: BoxDecoration(
                                    color: own
                                        ? Theme.of(context).colorScheme.primary
                                        : colors.background,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: message.isLocation
                                      ? _LocationMessageCard(
                                          message: message,
                                          own: own,
                                          onOpenMap: () => _openMap(message),
                                        )
                                      : Text(
                                          message.contenido,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: own
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                    : null,
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
                      padding: EdgeInsets.fromLTRB(
                        spacing.small,
                        spacing.small,
                        spacing.medium,
                        spacing.medium,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            key: const Key('shareChatLocationButton'),
                            tooltip: 'Compartir ubicación',
                            onPressed: _sending || _sharingLocation
                                ? null
                                : _shareLocation,
                            icon: _sharingLocation
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_location_alt_outlined),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: !_sending && !_sharingLocation,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Escribe un mensaje',
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('sendChatMessageButton'),
                            tooltip: 'Enviar mensaje',
                            onPressed: _sending || _sharingLocation
                                ? null
                                : _send,
                            icon: _sending
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
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

class _LocationMessageCard extends StatelessWidget {
  const _LocationMessageCard({
    required this.message,
    required this.own,
    required this.onOpenMap,
  });

  final ChatMessage message;
  final bool own;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final textColor = own
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      key: Key('chatLocationMessage-${message.id}'),
      onTap: onOpenMap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.latitude!.toStringAsFixed(3)}, ${message.longitude!.toStringAsFixed(3)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toca para abrir en el mapa',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      decoration: TextDecoration.underline,
                      decorationColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
