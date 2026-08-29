import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/request.dart';
import '../services/api_exception.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';

enum _RequestAction { accept, reject, cancel }

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    required this.requestId,
    this.requestService,
    super.key,
  });
  final int requestId;
  final RequestService? requestService;
  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late final RequestService _service;
  RequestDetail? _request;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _service = widget.requestService ?? RequestService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final request = await _service.getRequestById(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _notFound = error.type == ApiErrorType.notFound;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No pudimos cargar la solicitud. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _perform(_RequestAction action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final request = switch (action) {
        _RequestAction.accept => _service.acceptRequest(widget.requestId),
        _RequestAction.reject => _service.rejectRequest(widget.requestId),
        _RequestAction.cancel => _service.cancelRequest(widget.requestId),
      };
      final updated = await request;
      if (!mounted) return;
      setState(() {
        _request = updated;
        _acting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (action) {
            _RequestAction.accept => 'Solicitud aceptada.',
            _RequestAction.reject => 'Solicitud rechazada.',
            _RequestAction.cancel => 'Solicitud cancelada.',
          }),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos completar la acción.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de solicitud')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, colors.background],
          ),
        ),
        child: SafeArea(child: _content(context, spacing, colors)),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppSpacing spacing,
    AppColorTokens colors,
  ) {
    if (_loading) {
      return const Center(
        child: AppContentState(
          key: Key('requestDetailLoading'),
          type: AppContentStateType.loading,
          title: 'Cargando solicitud',
        ),
      );
    }
    if (_error case final message?) {
      return Center(
        child: SingleChildScrollView(
          child: AppContentState(
            key: Key(
              _notFound ? 'requestDetailNotFound' : 'requestDetailError',
            ),
            type: AppContentStateType.error,
            title: _notFound
                ? 'Solicitud no disponible'
                : 'No pudimos cargar la solicitud',
            message: message,
            actionText: 'Reintentar',
            onAction: _load,
          ),
        ),
      );
    }
    final request = _request!;
    return SingleChildScrollView(
      key: const Key('requestDetailContent'),
      padding: EdgeInsets.all(spacing.large),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DonationImage(request: request),
              SizedBox(height: spacing.large),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(spacing.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.donation.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: spacing.medium),
                      _DetailRow(
                        label: 'Solicitud',
                        value: request.status.label,
                      ),
                      _DetailRow(
                        label: 'Donación',
                        value: request.donation.status.label,
                      ),
                      _DetailRow(
                        label: request.actor == RequestActor.owner
                            ? 'Solicitante'
                            : 'Donante',
                        value: request.otherUser.visibleName,
                      ),
                      _DetailRow(
                        label: 'Ciudad',
                        value: request.otherUser.city,
                      ),
                      _DetailRow(
                        label: 'Creada',
                        value: _formatDateTime(request.createdAt),
                      ),
                      if (request.cancellationCause case final cause?)
                        _DetailRow(label: 'Motivo', value: cause.label),
                      if (request.acceptedAt case final date?)
                        _DetailRow(
                          label: 'Aceptada',
                          value: _formatDateTime(date),
                        ),
                      if (request.rejectedAt case final date?)
                        _DetailRow(
                          label: 'Rechazada',
                          value: _formatDateTime(date),
                        ),
                      if (request.cancelledAt case final date?)
                        _DetailRow(
                          label: 'Cancelada',
                          value: _formatDateTime(date),
                        ),
                    ],
                  ),
                ),
              ),
              if (request.canAcceptOrReject) ...[
                SizedBox(height: spacing.large),
                FilledButton.icon(
                  key: const Key('acceptRequestButton'),
                  onPressed: _acting
                      ? null
                      : () => _perform(_RequestAction.accept),
                  icon: _acting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Aceptar'),
                ),
                SizedBox(height: spacing.small),
                OutlinedButton.icon(
                  key: const Key('rejectRequestButton'),
                  onPressed: _acting
                      ? null
                      : () => _perform(_RequestAction.reject),
                  icon: const Icon(Icons.close),
                  label: const Text('Rechazar'),
                ),
              ],
              if (request.canCancel) ...[
                SizedBox(height: spacing.large),
                OutlinedButton.icon(
                  key: const Key('cancelRequestButton'),
                  onPressed: _acting
                      ? null
                      : () => _perform(_RequestAction.cancel),
                  icon: _acting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar solicitud'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationImage extends StatelessWidget {
  const _DonationImage({required this.request});
  final RequestDetail request;
  @override
  Widget build(BuildContext context) {
    final reference = request.donation.mainImage;
    final uri = reference == null
        ? null
        : ApiConfig.resolveImageReference(reference);
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: colors.background,
          child: uri == null
              ? const _DetailPlaceholder()
              : Image.network(
                  uri.toString(),
                  key: const Key('requestDetailImage'),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const _DetailPlaceholder(),
                ),
        ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    key: Key('requestDetailImagePlaceholder'),
    child: Icon(Icons.image_not_supported_outlined),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
