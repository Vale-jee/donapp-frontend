import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/request.dart';
import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/request_card.dart';

enum RequestsListMode { sent, received }

class SentRequestsScreen extends StatelessWidget {
  const SentRequestsScreen({this.requestService, super.key});
  final RequestService? requestService;
  @override
  Widget build(BuildContext context) => RequestsScreen(
    mode: RequestsListMode.sent,
    requestService: requestService,
  );
}

class ReceivedRequestsScreen extends StatelessWidget {
  const ReceivedRequestsScreen({this.requestService, super.key});
  final RequestService? requestService;
  @override
  Widget build(BuildContext context) => RequestsScreen(
    mode: RequestsListMode.received,
    requestService: requestService,
  );
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({required this.mode, this.requestService, super.key});
  final RequestsListMode mode;
  final RequestService? requestService;
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  static const _limit = 20;
  late final RequestService _service;
  late final ScrollController _scrollController;
  List<RequestListItem> _requests = const [];
  RequestPagination? _pagination;
  RequestStatus? _status;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _service = widget.requestService ?? RequestService();
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

  Future<({List<RequestListItem> requests, RequestPagination pagination})>
  _getPage(int page) async {
    if (widget.mode == RequestsListMode.sent) {
      final result = await _service.getSentRequests(
        page: page,
        limit: _limit,
        status: _status,
      );
      return (requests: result.requests, pagination: result.pagination);
    }
    final result = await _service.getReceivedRequests(
      page: page,
      limit: _limit,
      status: _status,
    );
    return (requests: result.requests, pagination: result.pagination);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
    });
    try {
      final result = await _getPage(1);
      if (!mounted) return;
      setState(() {
        _requests = result.requests;
        _pagination = result.pagination;
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
          _error = 'No pudimos cargar las solicitudes. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _getPage(1);
      if (!mounted) return;
      setState(() {
        _requests = result.requests;
        _pagination = result.pagination;
        _pageError = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _pageError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _pageError = 'No pudimos actualizar las solicitudes.');
      }
    }
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
      final result = await _getPage(pagination.page + 1);
      if (!mounted) return;
      setState(() {
        _requests = [..._requests, ...result.requests];
        _pagination = result.pagination;
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
          _pageError = 'No pudimos cargar más solicitudes.';
        });
      }
    }
  }

  Future<void> _selectStatus(RequestStatus? status) async {
    if (_status == status) return;
    setState(() => _status = status);
    await _loadInitial();
  }

  void _switchMode(RequestsListMode mode) {
    if (mode == widget.mode) return;
    context.pushReplacement(
      mode == RequestsListMode.sent
          ? AppRoutes.sentRequests
          : AppRoutes.receivedRequests,
    );
  }

  ImageProvider<Object>? _image(RequestListItem request) {
    final reference = request.donation.mainImage;
    final uri = reference == null
        ? null
        : ApiConfig.resolveImageReference(reference);
    return uri == null ? null : NetworkImage(uri.toString());
  }

  ImageProvider<Object>? _profileImage(RequestUserSummary user) {
    final reference = user.profilePhoto;
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
    final sent = widget.mode == RequestsListMode.sent;
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
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
                    key: Key('requestsLoading'),
                    type: AppContentStateType.loading,
                    title: 'Cargando solicitudes',
                  ),
                )
              : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    child: AppContentState(
                      key: const Key('requestsError'),
                      type: AppContentStateType.error,
                      title: 'No pudimos cargar las solicitudes',
                      message: _error,
                      actionText: 'Reintentar',
                      onAction: _loadInitial,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    key: const Key('requestsList'),
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
                              SegmentedButton<RequestsListMode>(
                                key: const Key('requestsModeSelector'),
                                segments: const [
                                  ButtonSegment(
                                    value: RequestsListMode.sent,
                                    label: Text('Enviadas'),
                                    icon: Icon(Icons.north_east),
                                  ),
                                  ButtonSegment(
                                    value: RequestsListMode.received,
                                    label: Text('Recibidas'),
                                    icon: Icon(Icons.south_west),
                                  ),
                                ],
                                selected: {widget.mode},
                                onSelectionChanged: (selection) =>
                                    _switchMode(selection.single),
                              ),
                              SizedBox(height: spacing.large),
                              Text(
                                sent ? 'Solicitudes que has enviado.' : 'Solicitudes recibidas en tus donaciones.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              SizedBox(height: spacing.large),
                              DropdownButtonFormField<RequestStatus?>(
                                key: const Key('requestStatusFilter'),
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
                                  ...RequestStatus.values.map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text('${status.label}s'),
                                    ),
                                  ),
                                ],
                                onChanged: _selectStatus,
                              ),
                              SizedBox(height: spacing.large),
                              if (_requests.isEmpty)
                                AppContentState(
                                  key: const Key('requestsEmpty'),
                                  type: AppContentStateType.empty,
                                  title: sent
                                      ? 'No has enviado solicitudes'
                                      : 'No has recibido solicitudes',
                                  message: 'Las solicitudes aparecerán aquí.',
                                )
                              else
                                ..._requests.map((request) {
                                  final person = switch (request) {
                                    SentRequestListItem item => item.donor,
                                    ReceivedRequestListItem item =>
                                      item.applicant,
                                    _ => throw StateError(
                                      'Tipo de solicitud inesperado',
                                    ),
                                  };
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: spacing.large,
                                    ),
                                    child: RequestCard(
                                      key: ValueKey(
                                        'requestCard-${request.id}',
                                      ),
                                      image: _image(request),
                                      donationTitle: request.donation.title,
                                      personName: person.visibleName,
                                      profileImage: _profileImage(person),
                                      personCity: person.city,
                                      requestStatus: request.status.label,
                                      donationStatus:
                                          request.donation.status.label,
                                      date: _formatDate(request.createdAt),
                                      cancellationCause:
                                          request.cancellationCause?.label,
                                      onTap: () => context.push(
                                        AppRoutes.requestDetailLocation(
                                          request.id,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              if (_loadingMore)
                                const Center(
                                  child: CircularProgressIndicator(
                                    key: Key('requestsLoadingMore'),
                                  ),
                                ),
                              if (_pageError case final message?)
                                AppContentState(
                                  key: const Key('requestsPaginationError'),
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

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
