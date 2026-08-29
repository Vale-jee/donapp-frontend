import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/donation.dart';
import '../services/api_exception.dart';
import '../services/donation_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';

class DonationDetailScreen extends StatefulWidget {
  const DonationDetailScreen({
    required this.donationId,
    this.donationService,
    this.requestService,
    super.key,
  });

  final int donationId;
  final DonationService? donationService;
  final RequestService? requestService;

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  late final DonationService _service;
  late final RequestService _requestService;
  DonationDetail? _donation;
  ApiException? _error;
  bool _isSubmitting = false;
  bool _requestCreated = false;

  @override
  void initState() {
    super.initState();
    _service = widget.donationService ?? DonationService();
    _requestService = widget.requestService ?? RequestService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _donation = null;
      _error = null;
    });
    try {
      final donation = await _service.getDonationById(widget.donationId);
      if (mounted) setState(() => _donation = donation);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const ApiException(
            ApiErrorType.unexpectedResponse,
            'No pudimos cargar la donación. Intenta nuevamente.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de donación')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, colors.background],
          ),
        ),
        child: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    final error = _error;
    if (error != null) {
      final notFound = error.type == ApiErrorType.notFound;
      return Center(
        child: SingleChildScrollView(
          child: AppContentState(
            key: Key(
              notFound ? 'donationDetailNotFound' : 'donationDetailError',
            ),
            type: notFound
                ? AppContentStateType.empty
                : AppContentStateType.error,
            title: notFound
                ? 'Donación no disponible'
                : 'No pudimos cargar la donación',
            message: notFound
                ? 'Puede que ya no exista o no esté visible para ti.'
                : error.message,
            actionText: 'Reintentar',
            onAction: _load,
          ),
        ),
      );
    }
    final donation = _donation;
    if (donation == null) {
      return const Center(
        child: AppContentState(
          key: Key('donationDetailLoading'),
          type: AppContentStateType.loading,
          title: 'Cargando donación',
        ),
      );
    }
    return _DonationDetailContent(
      donation: donation,
      isSubmitting: _isSubmitting,
      showRequestAction: donation.puedeSolicitar && !_requestCreated,
      onRequest: _confirmRequest,
    );
  }

  Future<void> _confirmRequest() async {
    final donation = _donation;
    if (donation == null || _isSubmitting || _requestCreated) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Solicitar donación'),
        content: Text(
          '¿Quieres enviar una solicitud para “${donation.titulo}”?',
        ),
        actionsOverflowAlignment: OverflowBarAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submitRequest();
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting || _requestCreated) return;
    setState(() => _isSubmitting = true);
    try {
      await _requestService.createRequest(widget.donationId);
      if (!mounted) return;
      setState(() {
        _requestCreated = true;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Solicitud enviada correctamente.'),
          action: SnackBarAction(
            label: 'Ver solicitudes',
            onPressed: () => context.push('/solicitudes/enviadas'),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      if (error.type == ApiErrorType.conflict ||
          error.type == ApiErrorType.notFound) {
        await _load();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos enviar la solicitud. Intenta nuevamente.'),
        ),
      );
    }
  }
}

class _DonationDetailContent extends StatelessWidget {
  const _DonationDetailContent({
    required this.donation,
    required this.isSubmitting,
    required this.showRequestAction,
    required this.onRequest,
  });
  final DonationDetail donation;
  final bool isSubmitting;
  final bool showRequestAction;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return SingleChildScrollView(
      key: const Key('donationDetailScroll'),
      padding: EdgeInsets.all(spacing.large),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImageGallery(images: donation.imagenes, title: donation.titulo),
              SizedBox(height: spacing.large),
              _DetailCard(donation: donation),
              if (showRequestAction) ...[
                SizedBox(height: spacing.large),
                Semantics(
                  button: true,
                  label: isSubmitting
                      ? 'Enviando solicitud'
                      : 'Solicitar donación',
                  child: FilledButton.icon(
                    key: const Key('requestDonationButton'),
                    onPressed: isSubmitting ? null : onRequest,
                    icon: isSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.volunteer_activism_outlined),
                    label: Text(
                      isSubmitting ? 'Enviando solicitud…' : 'Solicitar donación',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.images, required this.title});
  final List<DonationImage> images;
  final String title;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    final galleryHeight = (MediaQuery.sizeOf(context).height * 0.55).clamp(
      280.0,
      560.0,
    );
    return Semantics(
      container: true,
      label: widget.images.isEmpty
          ? 'La donación ${widget.title} no tiene imágenes'
          : 'Imágenes de ${widget.title}. Imagen ${_index + 1} de ${widget.images.length}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius.featuredCard),
        child: ColoredBox(
          key: const Key('donationImageViewport'),
          color: colors.background,
          child: SizedBox(
            height: galleryHeight,
            width: double.infinity,
            child: widget.images.isEmpty
                ? const _DetailImagePlaceholder()
                : PageView.builder(
                    key: const Key('donationImageGallery'),
                    itemCount: widget.images.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) {
                      final uri = ApiConfig.resolveImageReference(
                        widget.images[index].referencia,
                      );
                      if (uri == null) return const _DetailImagePlaceholder();
                      return Image.network(
                        uri.toString(),
                        key: ValueKey('donationDetailImage-$index'),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            const _DetailImagePlaceholder(),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return ColoredBox(
      key: const Key('donationDetailImagePlaceholder'),
      color: colors.background,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.donation});
  final DonationDetail donation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(donation.titulo, style: theme.textTheme.headlineSmall),
            SizedBox(height: spacing.medium),
            _Metadata(
              icon: Icons.category_outlined,
              label: 'Categoría',
              value: donation.categoriaNombre,
            ),
            SizedBox(height: spacing.small),
            _Metadata(
              icon: Icons.location_on_outlined,
              label: 'Ciudad',
              value: donation.ciudad,
            ),
            SizedBox(height: spacing.small),
            _Metadata(
              icon: Icons.info_outline,
              label: 'Estado',
              value: donation.estado.label,
            ),
            SizedBox(height: spacing.small),
            _Metadata(
              icon: Icons.calendar_today_outlined,
              label: 'Publicada',
              value: _date(donation.createdAt),
            ),
            SizedBox(height: spacing.large),
            Text('Descripción', style: theme.textTheme.titleLarge),
            SizedBox(height: spacing.small),
            Text(donation.descripcion, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, semanticLabel: label),
        SizedBox(width: spacing.small),
        Expanded(child: Text('$label: $value')),
      ],
    );
  }
}
