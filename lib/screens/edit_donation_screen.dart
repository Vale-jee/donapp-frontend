import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/donation.dart';
import '../repositories/category_repository.dart';
import '../repositories/donation_repository.dart';
import '../services/api_exception.dart';
import '../services/read_cancellation.dart';
import '../theme/app_spacing.dart';
import '../validation/donation_validators.dart';
import '../widgets/app_content_state.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

class EditDonationScreen extends StatefulWidget {
  const EditDonationScreen({
    required this.donation,
    required this.cacheUserId,
    required this.donationRepository,
    this.categoryRepository = const CategoryRepository(),
    super.key,
  });

  final DonationDetail donation;
  final int cacheUserId;
  final DonationRepository donationRepository;
  final CategoryRepository categoryRepository;

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  final _reads = ReadCancellation();
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.donation.titulo);
  late final _description = TextEditingController(
    text: widget.donation.descripcion,
  );
  late int _categoryId = widget.donation.categoriaId;
  List<Category> _categories = [];
  bool _loading = true;
  bool _saving = false;
  bool _allowed = false;
  String? _pageError;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reads.cancel();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() => _reads.run(() async {
    setState(() {
      _loading = true;
      _pageError = null;
    });
    try {
      final allowed =
          widget.donation.estado == DonationStatus.publicada &&
          await widget.donationRepository.canEditDonation(widget.donation.id);
      if (!mounted) return;
      if (!allowed) {
        setState(() {
          _allowed = false;
          _pageError = 'Esta donación no está disponible para editar.';
        });
        return;
      }
      final categories = await widget.categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _categories = [
          ...categories,
          // An inactive current category can be retained, but not submitted
          // again unless the user actually chooses another category.
          if (!categories.any((item) => item.id == widget.donation.categoriaId))
            Category(
              id: widget.donation.categoriaId,
              nombre: widget.donation.categoriaNombre,
              descripcion: null,
            ),
        ];
      });
    } on RequestCancelled {
      return;
    } on ApiException catch (error) {
      if (mounted) setState(() => _pageError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _pageError =
              'No pudimos preparar el formulario. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  });

  void _clearError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
    }
  }

  Future<void> _save() async {
    if (_saving || !_allowed || !_formKey.currentState!.validate()) return;
    final original = widget.donation;
    final title = normalizeDonationTitle(_title.text);
    final description = _description.text.trim();
    final titleChanged = title != normalizeDonationTitle(original.titulo);
    final descriptionChanged = description != original.descripcion.trim();
    final categoryChanged = _categoryId != original.categoriaId;
    if (!titleChanged && !descriptionChanged && !categoryChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.donationRepository.updateDonation(
        original.id,
        cacheUserId: widget.cacheUserId,
        title: titleChanged ? title : null,
        description: descriptionChanged ? description : null,
        categoryId: categoryChanged ? _categoryId : null,
      );
      if (!mounted) return;
      // Enable pop before leaving: back is blocked while the write is pending.
      setState(() => _saving = false);
      Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _fieldErrors = {
          for (final field in error.fieldErrors) field.field: field.message,
        };
      });
      _formKey.currentState?.validate();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos guardar los cambios. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar donación')),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: AppContentState(
                    type: AppContentStateType.loading,
                    title: 'Preparando formulario',
                  ),
                )
              : _pageError != null
              ? Center(
                  child: AppContentState(
                    type: AppContentStateType.error,
                    title: 'No pudimos preparar el formulario',
                    message: _pageError,
                    actionText: 'Reintentar',
                    onAction: _load,
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(spacing.large),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              key: const Key('editDonationTitle'),
                              label: 'Título',
                              controller: _title,
                              enabled: !_saving,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              onChanged: (_) => _clearError('titulo'),
                              validator: (value) =>
                                  validateDonationTitle(value) ??
                                  _fieldErrors['titulo'],
                            ),
                            SizedBox(height: spacing.medium),
                            AppTextField(
                              key: const Key('editDonationDescription'),
                              label: 'Descripción',
                              controller: _description,
                              enabled: !_saving,
                              maxLines: 5,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              onChanged: (_) => _clearError('descripcion'),
                              validator: (value) =>
                                  validateDonationDescription(value) ??
                                  _fieldErrors['descripcion'],
                            ),
                            SizedBox(height: spacing.medium),
                            DropdownButtonFormField<int>(
                              key: const Key('editDonationCategory'),
                              initialValue: _categoryId,
                              isExpanded: true,
                              itemHeight: null,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                              ),
                              items: _categories
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.id,
                                      child: Text(
                                        item.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _saving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _categoryId = value;
                                          _fieldErrors.remove('categoriaId');
                                        });
                                      }
                                    },
                              validator: (value) =>
                                  validateDonationCategory(value) ??
                                  _fieldErrors['categoriaId'],
                            ),
                            if (_error != null) ...[
                              SizedBox(height: spacing.medium),
                              Text(
                                _error!,
                                key: const Key('editDonationError'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            SizedBox(height: spacing.large),
                            AppPrimaryButton(
                              key: const Key('saveDonationButton'),
                              text: 'Guardar cambios',
                              icon: Icons.save_outlined,
                              isLoading: _saving,
                              onPressed: _save,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
