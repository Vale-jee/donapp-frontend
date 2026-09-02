import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/category.dart';
import '../models/donation.dart';
import '../navigation/app_router.dart';
import '../repositories/donation_repository.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/donation_card.dart';

class ExploreDonationsScreen extends StatefulWidget {
  const ExploreDonationsScreen({
    this.donationService,
    this.categoryService,
    this.cacheUserId,
    this.repository,
    super.key,
  });

  final DonationService? donationService;
  final CategoryService? categoryService;
  final int? cacheUserId;
  final DonationRepository? repository;

  @override
  State<ExploreDonationsScreen> createState() => _ExploreDonationsScreenState();
}

class _ExploreDonationsScreenState extends State<ExploreDonationsScreen> {
  static const _pageLimit = 20;

  late final DonationService _donationService;
  late final CategoryService _categoryService;
  late final ScrollController _scrollController;
  DonationRepository? _repository;
  StreamSubscription<List<DonationListItem>>? _donationsSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  List<Category> _categories = const [];
  List<DonationListItem> _donations = const [];
  DonationPagination? _pagination;
  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _paginationError;

  @override
  void initState() {
    super.initState();
    _donationService = widget.donationService ?? DonationService();
    _categoryService = widget.categoryService ?? const CategoryService();
    _scrollController = ScrollController()..addListener(_onScroll);
    if (widget.cacheUserId != null) {
      _repository =
          widget.repository ??
          DonationRepository.create(
            donationService: _donationService,
            categoryService: _categoryService,
          );
      _categoriesSubscription = _repository!.watchCategories().listen((
        categories,
      ) {
        if (mounted) setState(() => _categories = categories);
      });
      _watchLocalDonations();
    }
    _loadInitial();
  }

  @override
  void dispose() {
    _donationsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    unawaited(_repository?.close());
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) _loadNextPage();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paginationError = null;
    });
    final repository = _repository;
    if (repository != null) {
      try {
        await Future.wait<void>([
          repository.refreshCategories(),
          repository
              .refreshExplore(
                cacheUserId: widget.cacheUserId!,
                limit: _pageLimit,
                categoryId: _selectedCategoryId,
              )
              .then((page) {
                if (mounted) setState(() => _pagination = page.pagination);
              }),
        ]);
        if (mounted) setState(() => _isLoading = false);
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (_donations.isEmpty) _errorMessage = error.message;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (_donations.isEmpty) {
            _errorMessage = 'No hay datos disponibles todavía sin conexión.';
          }
        });
      }
      return;
    }
    try {
      final results = await Future.wait<Object>([
        _categoryService.getCategories(),
        _donationService.getAvailableDonations(
          limit: _pageLimit,
          categoryId: _selectedCategoryId,
        ),
      ]);
      if (!mounted) return;
      final categories = results[0] as List<Category>;
      final page = results[1] as DonationPage;
      setState(() {
        _categories = categories;
        _donations = page.donations;
        _pagination = page.pagination;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No pudimos cargar las donaciones. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _refresh() async {
    final repository = _repository;
    if (repository != null) {
      try {
        final page = await repository.refreshExplore(
          cacheUserId: widget.cacheUserId!,
          limit: _pageLimit,
          categoryId: _selectedCategoryId,
        );
        if (mounted) {
          setState(() {
            _pagination = page.pagination;
            _paginationError = null;
          });
        }
      } on ApiException catch (error) {
        if (mounted && _donations.isEmpty) {
          setState(() => _errorMessage = error.message);
        }
      }
      return;
    }
    try {
      final page = await _donationService.getAvailableDonations(
        limit: _pageLimit,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _donations = page.donations;
        _pagination = page.pagination;
        _paginationError = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _paginationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _paginationError =
              'No pudimos actualizar las donaciones. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _selectCategory(int? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    if (_repository != null) _watchLocalDonations();
    await _loadInitial();
  }

  Future<void> _loadNextPage() async {
    final pagination = _pagination;
    if (_isLoadingMore ||
        pagination == null ||
        !pagination.hasNextPage ||
        _isLoading) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
      _paginationError = null;
    });
    try {
      final page = _repository == null
          ? await _donationService.getAvailableDonations(
              page: pagination.page + 1,
              limit: pagination.limit,
              categoryId: _selectedCategoryId,
            )
          : await _repository!.refreshExplore(
              cacheUserId: widget.cacheUserId!,
              page: pagination.page + 1,
              limit: pagination.limit,
              categoryId: _selectedCategoryId,
            );
      if (!mounted) return;
      setState(() {
        if (_repository == null) {
          _donations = [..._donations, ...page.donations];
        }
        _pagination = page.pagination;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _paginationError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _paginationError =
              'No pudimos cargar más donaciones. Intenta nuevamente.';
        });
      }
    }
  }

  void _watchLocalDonations() {
    unawaited(_donationsSubscription?.cancel());
    _donationsSubscription = _repository!
        .watchExplore(
          cacheUserId: widget.cacheUserId!,
          categoryId: _selectedCategoryId,
        )
        .listen((donations) {
          if (!mounted) return;
          setState(() {
            _donations = donations;
            if (donations.isNotEmpty) {
              _isLoading = false;
              _errorMessage = null;
            }
          });
        });
  }

  ImageProvider<Object>? _imageFor(DonationListItem donation) {
    final reference = donation.imagenPrincipal?.referencia;
    if (reference == null) return null;
    final uri = ApiConfig.resolveImageReference(reference);
    return uri == null ? null : NetworkImage(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar donaciones')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, colors.background],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: AppContentState(
                    key: Key('exploreLoading'),
                    type: AppContentStateType.loading,
                    title: 'Buscando donaciones',
                  ),
                )
              : _errorMessage != null
              ? Center(
                  child: SingleChildScrollView(
                    child: AppContentState(
                      key: const Key('exploreError'),
                      type: AppContentStateType.error,
                      title: 'No pudimos cargar las donaciones',
                      message: _errorMessage,
                      actionText: 'Reintentar',
                      onAction: _loadInitial,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    key: const Key('exploreList'),
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
                                'Encuentra algo que pueda ser útil para ti.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              SizedBox(height: spacing.large),
                              DropdownButtonFormField<int?>(
                                key: const Key('categoryFilter'),
                                initialValue: _selectedCategoryId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Todas las categorías'),
                                  ),
                                  ..._categories.map(
                                    (category) => DropdownMenuItem<int?>(
                                      value: category.id,
                                      child: Text(category.nombre),
                                    ),
                                  ),
                                ],
                                onChanged: _selectCategory,
                              ),
                              SizedBox(height: spacing.large),
                              if (_donations.isEmpty)
                                const AppContentState(
                                  key: Key('exploreEmpty'),
                                  type: AppContentStateType.empty,
                                  title: 'No hay donaciones disponibles',
                                  message: 'Prueba otra categoría o vuelve más tarde.',
                                )
                              else
                                ..._donations.map(
                                  (donation) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: spacing.large,
                                    ),
                                    child: DonationCard(
                                      key: ValueKey(
                                        'donationCard-${donation.id}',
                                      ),
                                      image: _imageFor(donation),
                                      imageFit: BoxFit.contain,
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
                              if (_isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      key: Key('exploreLoadingMore'),
                                    ),
                                  ),
                                ),
                              if (_paginationError case final message?)
                                AppContentState(
                                  key: const Key('explorePaginationError'),
                                  type: AppContentStateType.error,
                                  title: 'No pudimos cargar más donaciones',
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
