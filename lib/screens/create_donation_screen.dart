import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/donation.dart';
import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';
import '../services/image_upload_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

final _titleWhitespacePattern = RegExp(r'\s+', unicode: true);
final _htmlTagPattern = RegExp(
  r'</?[a-z][^<>]*>',
  caseSensitive: false,
  unicode: true,
);
final _fencedCodePattern = RegExp(r'```', unicode: true);
final _markdownImagePattern = RegExp(
  r'!\[[^\]\r\n]*\]\([^\r\n)]+\)',
  unicode: true,
);
final _markdownLinkPattern = RegExp(
  r'(?<!!)\[[^\]\r\n]+\]\([^\r\n)]+\)',
  unicode: true,
);
final _markdownHeadingPattern = RegExp(
  r'^\s{0,3}#{1,6}\s+\S',
  multiLine: true,
  unicode: true,
);
final _markdownQuotePattern = RegExp(
  r'^\s{0,3}>\s+\S',
  multiLine: true,
  unicode: true,
);

String _normalizeDonationTitle(String value) =>
    value.trim().replaceAll(_titleWhitespacePattern, ' ');

bool _isPlainDonationDescription(String value) =>
    !_htmlTagPattern.hasMatch(value) &&
    !_fencedCodePattern.hasMatch(value) &&
    !_markdownImagePattern.hasMatch(value) &&
    !_markdownLinkPattern.hasMatch(value) &&
    !_markdownHeadingPattern.hasMatch(value) &&
    !_markdownQuotePattern.hasMatch(value);

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({
    this.donationService,
    this.categoryService,
    this.imageUploadService,
    this.galleryPicker,
    this.onCreated,
    super.key,
  });

  final DonationService? donationService;
  final CategoryService? categoryService;
  final ImageUploadService? imageUploadService;
  final DonationGalleryPicker? galleryPicker;
  final ValueChanged<DonationDetail>? onCreated;

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final DonationService _donationService;
  late final CategoryService _categoryService;
  late final ImageUploadService _imageUploadService;
  late final DonationGalleryPicker _galleryPicker;
  List<Category> _categories = const [];
  List<XFile> _images = const [];
  int? _categoryId;
  bool _loadingCategories = true;
  bool _submitting = false;
  String? _pageError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _donationService = widget.donationService ?? DonationService();
    _categoryService = widget.categoryService ?? const CategoryService();
    _imageUploadService = widget.imageUploadService ?? ImageUploadService();
    _galleryPicker = widget.galleryPicker ?? ImagePickerGallery();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingCategories = true;
      _pageError = null;
    });
    try {
      final results = await Future.wait<Object>([
        _categoryService.getCategories(),
        _galleryPicker.retrieveLostImages(),
      ]);
      if (!mounted) return;
      final recovered = results[1] as List<XFile>;
      setState(() {
        _categories = results[0] as List<Category>;
        _images = recovered.take(maxDonationImages).toList(growable: false);
        _loadingCategories = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
          _pageError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
          _pageError = 'No pudimos preparar el formulario. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final selected = await _galleryPicker.pickImages();
      if (!mounted || selected.isEmpty) return;
      final combined = [..._images, ...selected];
      if (combined.length > maxDonationImages) {
        setState(() => _submitError = 'Puedes seleccionar máximo 5 imágenes.');
        return;
      }
      for (final image in selected) {
        await _imageUploadService.validateImage(image);
      }
      if (mounted) {
        setState(() {
          _images = List.unmodifiable(combined);
          _submitError = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _submitError = 'No pudimos seleccionar las imágenes.');
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images = [..._images]..removeAt(index));
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _submitError = 'Selecciona una categoría.');
      return;
    }
    if (_images.isEmpty) {
      setState(() => _submitError = 'Selecciona al menos una imagen.');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final references = await _imageUploadService.uploadImages(_images);
      final donation = await _donationService.createDonation(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _categoryId!,
        imageReferences: references,
      );
      if (!mounted) return;
      widget.onCreated?.call(donation);
      if (widget.onCreated == null && GoRouter.maybeOf(context) != null) {
        context.replace(AppRoutes.donationDetailLocation(donation.id));
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError =
              'No pudimos publicar la donación. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final categoryTextWidth =
        (MediaQuery.sizeOf(context).width - spacing.large * 2 - 80).clamp(
          48.0,
          560.0,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar donación')),
      body: SafeArea(
        child: _loadingCategories
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
                            key: const Key('donationTitleField'),
                            label: 'Título',
                            controller: _titleController,
                            enabled: !_submitting,
                            autovalidateMode: AutovalidateMode.onUnfocus,
                            validator: (value) {
                              final normalized = _normalizeDonationTitle(
                                value ?? '',
                              );
                              if (normalized.length < 5) {
                                return 'Escribe al menos 5 caracteres.';
                              }
                              if (normalized.length > 100) {
                                return 'Usa máximo 100 caracteres.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: spacing.medium),
                          AppTextField(
                            key: const Key('donationDescriptionField'),
                            label: 'Descripción',
                            controller: _descriptionController,
                            enabled: !_submitting,
                            maxLines: 5,
                            autovalidateMode: AutovalidateMode.onUnfocus,
                            validator: (value) {
                              final normalized = value?.trim() ?? '';
                              if (normalized.length < 20) {
                                return 'Escribe al menos 20 caracteres.';
                              }
                              if (normalized.length > 1000) {
                                return 'Usa máximo 1000 caracteres.';
                              }
                              if (!_isPlainDonationDescription(normalized)) {
                                return 'Escribe la descripción como texto simple, sin HTML, enlaces ni formato Markdown no permitido.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: spacing.medium),
                          DropdownButtonFormField<int>(
                            key: const Key('donationCategoryField'),
                            initialValue: _categoryId,
                            isExpanded: true,
                            itemHeight: null,
                            autovalidateMode: AutovalidateMode.onUnfocus,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category.id,
                                    child: _CategoryOption(
                                      name: category.nombre,
                                      maxWidth: categoryTextWidth,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            selectedItemBuilder: (context) => _categories
                                .map(
                                  (category) => _CategoryOption(
                                    name: category.nombre,
                                    maxWidth: categoryTextWidth,
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: _submitting
                                ? null
                                : (value) =>
                                      setState(() => _categoryId = value),
                            validator: (value) => value == null
                                ? 'Selecciona una categoría.'
                                : null,
                          ),
                          SizedBox(height: spacing.large),
                          OutlinedButton(
                            key: const Key('pickDonationImagesButton'),
                            onPressed:
                                _submitting ||
                                    _images.length >= maxDonationImages
                                ? null
                                : _pickImages,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: spacing.small,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_library_outlined),
                                  SizedBox(width: spacing.small),
                                  Expanded(
                                    child: Text(
                                      'Seleccionar imágenes (${_images.length}/5)',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_images.isNotEmpty) ...[
                            SizedBox(height: spacing.medium),
                            SizedBox(
                              height: 112,
                              child: ListView.separated(
                                key: const Key('selectedDonationImages'),
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(width: spacing.small),
                                itemBuilder: (context, index) => _SelectedImage(
                                  image: _images[index],
                                  index: index,
                                  enabled: !_submitting,
                                  onRemove: () => _removeImage(index),
                                ),
                              ),
                            ),
                          ],
                          if (_submitError case final error?) ...[
                            SizedBox(height: spacing.medium),
                            Text(
                              error,
                              key: const Key('createDonationError'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          SizedBox(height: spacing.large),
                          AppPrimaryButton(
                            key: const Key('publishDonationButton'),
                            text: 'Publicar donación',
                            icon: Icons.volunteer_activism_outlined,
                            isLoading: _submitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({required this.name, required this.maxWidth});

  final String name;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: maxWidth,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _SelectedImage extends StatelessWidget {
  const _SelectedImage({
    required this.image,
    required this.index,
    required this.enabled,
    required this.onRemove,
  });
  final XFile image;
  final int index;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List>(
          future: image.readAsBytes(),
          builder: (context, snapshot) => snapshot.hasData
              ? Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  semanticLabel: 'Imagen seleccionada ${index + 1}',
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Colors.transparent,
                    child: Icon(Icons.image_outlined),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton.filled(
            key: ValueKey('removeDonationImage-$index'),
            tooltip: 'Quitar imagen ${index + 1}',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    ),
  );
}
