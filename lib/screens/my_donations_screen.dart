import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/donation.dart';
import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../services/donation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/donation_card.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({this.donationService, super.key});

  final DonationService? donationService;

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  static const _pageLimit = 20;
  late final DonationService _service;
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
    _service = widget.donationService ?? DonationService();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) _loadNextPage();
  }

  Future<void> _loadInitial() async {
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
  }

  Future<void> _refresh() async {
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
  }

  Future<void> _selectStatus(DonationStatus? status) async {
    if (_status == status) return;
    setState(() => _status = status);
    await _loadInitial();
  }

  Future<void> _loadNextPage() async {
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
  }

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
                  child: ListView(
                    key: const Key('myDonationsList'),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(spacing.large),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
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
                              if (_donations.isEmpty)
                                const AppContentState(
                                  key: Key('myDonationsEmpty'),
                                  type: AppContentStateType.empty,
                                  title: 'Aún no tienes donaciones',
                                  message: 'Cuando publiques una donación, aparecerá aquí.',
                                )
                              else
                                ..._donations.map(
                                  (donation) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: spacing.large,
                                    ),
                                    child: DonationCard(
                                      key: ValueKey(
                                        'myDonationCard-${donation.id}',
                                      ),
                                      image: _imageFor(donation),
                                      title: donation.titulo,
                                      category: donation.categoriaNombre,
                                      location: donation.ciudad,
                                      status: donation.estado.label,
                                      subtitle: donation.cantidadImagenes == 1
                                          ? '1 imagen'
                                          : '${donation.cantidadImagenes} imágenes',
                                      onTap: () => context.push(
                                        AppRoutes.donationDetailLocation(
                                          donation.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_loadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      key: Key('myDonationsLoadingMore'),
                                    ),
                                  ),
                                ),
                              if (_pageError case final message?)
                                AppContentState(
                                  key: const Key('myDonationsPaginationError'),
                                  type: AppContentStateType.error,
                                  title: 'No pudimos completar la carga',
                                  message: message,
                                  actionText: 'Reintentar',
                                  onAction: _loadNextPage,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
