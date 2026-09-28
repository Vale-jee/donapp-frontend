import '../services/read_cancellation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/donation.dart';
import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../repositories/donation_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/donation_card.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({this.donationRepository, super.key});

  final DonationRepository? donationRepository;

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final _reads = ReadCancellation();
  static const _pageLimit = 20;
  late final DonationRepository _service;
  late final ScrollController _scrollController;
  List<DonationListItem> _donations = const [];
  DonationPagination? _pagination;
  DonationStatus? _status;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _service = widget.donationRepository ?? DonationRepository.remote();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _reads.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openDonation(int id) async {
    await context.push(AppRoutes.donationDetailLocation(id));
    if (!mounted) return;
    setState(() {
      _donations = _donations
          .map((item) {
            final updated = _service.confirmedUpdate(item.id);
            if (updated == null || updated.updatedAt.isBefore(item.updatedAt)) {
              return item;
            }
            return DonationListItem(
              id: updated.id,
              titulo: updated.titulo,
              ciudad: updated.ciudad,
              estado: updated.estado,
              createdAt: updated.createdAt,
              updatedAt: updated.updatedAt,
              categoriaId: updated.categoriaId,
              categoriaNombre: updated.categoriaNombre,
              imagenPrincipal: updated.imagenes.firstOrNull,
              cantidadImagenes: updated.imagenes.length,
            );
          })
          .toList(growable: false);
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) _loadNextPage();
  }

  Future<void> _loadInitial() => _reads.run(() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
    });
    try {
      final page = await _service.getOwnDonations(
        limit: _pageLimit,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _donations = page.donations;
        _pagination = page.pagination;
        _loading = false;
      });
    } on RequestCancelled {
      return;
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
          _error = 'No pudimos cargar tus donaciones. Intenta nuevamente.';
        });
      }
    }
  });

  Future<void> _refresh() => _reads.run(() async {
    if (!mounted) return;
    try {
      final page = await _service.getOwnDonations(
        limit: _pageLimit,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _donations = page.donations;
        _pagination = page.pagination;
        _pageError = null;
      });
    } on RequestCancelled {
      return;
    } on ApiException catch (error) {
      if (mounted) setState(() => _pageError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _pageError =
              'No pudimos actualizar tus donaciones. Intenta nuevamente.',
        );
      }
    }
  });

  Future<void> _selectStatus(DonationStatus? status) async {
    if (_status == status) return;
    setState(() => _status = status);
    await _loadInitial();
  }

  Future<void> _loadNextPage() => _reads.run(() async {
    if (!mounted) return;
    final pagination = _pagination;
    if (_loading ||
        _loadingMore ||
        pagination == null ||
        !pagination.hasNextPage) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    try {
      final page = await _service.getOwnDonations(
        page: pagination.page + 1,
        limit: pagination.limit,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _donations = [..._donations, ...page.donations];
        _pagination = page.pagination;
        _loadingMore = false;
      });
    } on RequestCancelled {
      return;
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
          _pageError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
          _pageError = 'No pudimos cargar más donaciones. Intenta nuevamente.';
        });
      }
    }
  });

  ImageProvider<Object>? _imageFor(DonationListItem donation) {
    final reference = donation.imagenPrincipal?.referencia;
    final uri = reference == null
        ? null
        : ApiConfig.resolveImageReference(reference);
    return uri == null ? null : NetworkImage(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis donaciones')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, colors.background],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: AppContentState(
                    key: Key('myDonationsLoading'),
                    type: AppContentStateType.loading,
                    title: 'Cargando tus donaciones',
                  ),
                )
              : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    child: AppContentState(
                      key: const Key('myDonationsError'),
                      type: AppContentStateType.error,
                      title: 'No pudimos cargar tus donaciones',
                      message: _error,
                      actionText: 'Reintentar',
                      onAction: _loadInitial,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    key: const Key('myDonationsList'),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(spacing.large),
                    itemCount:
                        1 +
                        (_donations.isEmpty ? 1 : _donations.length) +
                        (_loadingMore ? 1 : 0) +
                        (_pageError != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      Widget child;
                      if (index == 0) {
                        child = _KeepAliveHeader(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Revisa las publicaciones que has realizado.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              SizedBox(height: spacing.large),
                              DropdownButtonFormField<DonationStatus?>(
                                key: const Key('statusFilter'),
                                initialValue: _status,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  prefixIcon: Icon(Icons.tune),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Todas'),
                                  ),
                                  ...DonationStatus.values.map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  ),
                                ],
                                onChanged: _selectStatus,
                              ),
                              SizedBox(height: spacing.large),
                            ],
                          ),
                        );
                      } else if (_donations.isEmpty && index == 1) {
                        child = const AppContentState(
                          key: Key('myDonationsEmpty'),
                          type: AppContentStateType.empty,
                          title: 'Aún no tienes donaciones',
                          message:
                              'Cuando publiques una donación, aparecerá aquí.',
                        );
                      } else if (index <= _donations.length) {
                        final donation = _donations[index - 1];
                        child = Padding(
                          padding: EdgeInsets.only(bottom: spacing.large),
                          child: DonationCard(
                            key: ValueKey('myDonationCard-${donation.id}'),
                            image: _imageFor(donation),
                            imageFit: BoxFit.contain,
                            limitContainedImageDecode: true,
                            title: donation.titulo,
                            category: donation.categoriaNombre,
                            location: donation.ciudad,
                            status: donation.estado.label,
                            subtitle: donation.cantidadImagenes == 1
                                ? '1 imagen'
                                : '${donation.cantidadImagenes} imágenes',
                            onTap: () => _openDonation(donation.id),
                          ),
                        );
                      } else if (_loadingMore &&
                          index ==
                              1 +
                                  (_donations.isEmpty
                                      ? 1
                                      : _donations.length)) {
                        child = const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              key: Key('myDonationsLoadingMore'),
                            ),
                          ),
                        );
                      } else {
                        child = AppContentState(
                          key: const Key('myDonationsPaginationError'),
                          type: AppContentStateType.error,
                          title: 'No pudimos completar la carga',
                          message: _pageError!,
                          actionText: 'Reintentar',
                          onAction: _loadNextPage,
                        );
                      }
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SizedBox(width: double.infinity, child: child),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

// Preserve the form field state when the header leaves the lazy viewport.
class _KeepAliveHeader extends StatefulWidget {
  const _KeepAliveHeader({required this.child});
  final Widget child;

  @override
  State<_KeepAliveHeader> createState() => _KeepAliveHeaderState();
}

class _KeepAliveHeaderState extends State<_KeepAliveHeader>
    with AutomaticKeepAliveClientMixin<_KeepAliveHeader> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
