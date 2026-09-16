import '../services/read_cancellation.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/donation.dart';
import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../repositories/category_repository.dart';
import '../repositories/donation_repository.dart';
import '../repositories/image_upload_repository.dart';
import '../services/donation_gallery_picker.dart';
import '../services/camera_capture_service.dart';
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
    this.donationRepository,
    this.categoryRepository,
    this.imageUploadRepository,
    this.galleryPicker,
    this.cameraCaptureService,
    this.onCreated,
    this.cacheUserId,
    this.city = '',
    super.key,
  });

  final DonationRepository? donationRepository;
  final CategoryRepository? categoryRepository;
  final ImageUploadRepository? imageUploadRepository;
  final DonationGalleryPicker? galleryPicker;
  final CameraCaptureService? cameraCaptureService;
  final ValueChanged<DonationDetail>? onCreated;
  final int? cacheUserId;
  final String city;

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _reads = ReadCancellation();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final DonationRepository _donationRepository;
  late final CategoryRepository _categoryRepository;
  late final ImageUploadRepository _imageUploadRepository;
  late final DonationGalleryPicker _galleryPicker;
  late final CameraCaptureService _cameraCaptureService;
  List<Category> _categories = const [];
  List<XFile> _images = const [];
  int? _categoryId;
  bool _loadingCategories = true;
  bool _submitting = false;
  bool _queued = false;
  String? _pageError;
  String? _submitError;
  Map<String, String> _remoteFieldErrors = const {};

  void _clearRemoteFieldError(String field) {
    if (!_remoteFieldErrors.containsKey(field)) return;
    setState(() {
      _remoteFieldErrors = Map.of(_remoteFieldErrors)..remove(field);
    });
  }

  void _applyRemoteFieldErrors(ApiException error) {
    final fieldErrors = <String, String>{};
    final generalErrors = <String>[];

    for (final fieldError in error.fieldErrors) {
      final field = switch (fieldError.field) {
        'titulo' => 'titulo',
        'descripcion' => 'descripcion',
        'categoriaId' => 'categoriaId',
        'imagenes' => 'imagenes',
        final field when field.startsWith('imagenes.') => 'imagenes',
        _ => null,
      };
      if (field == null) {
        generalErrors.add(fieldError.message);
      } else {
        fieldErrors.putIfAbsent(field, () => fieldError.message);
      }
    }

    setState(() {
      _remoteFieldErrors = fieldErrors;
      _submitError = generalErrors.isNotEmpty
          ? generalErrors.toSet().join('\n')
          : fieldErrors.isEmpty
          ? error.message
          : null;
    });
    _formKey.currentState?.validate();
  }

  @override
  void initState() {
    super.initState();
    _donationRepository =
        widget.donationRepository ?? DonationRepository.remote();
    _categoryRepository =
        widget.categoryRepository ?? const CategoryRepository();
    _imageUploadRepository =
        widget.imageUploadRepository ?? ImageUploadRepository();
    _galleryPicker = widget.galleryPicker ?? ImagePickerGallery();
    _cameraCaptureService =
      widget.cameraCaptureService ?? PermissionCameraCaptureService();
    _load();
  }

  @override
  void dispose() {
    _reads.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() => _reads.run(() async {
    if (!mounted) return;
    setState(() {
      _loadingCategories = true;
      _pageError = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.cacheUserId == null
            ? _categoryRepository.getCategories()
            : _donationRepository.getLocalFirstCategories(),
        _galleryPicker.retrieveLostImages(),
      ]);
      if (!mounted) return;
      final recovered = results[1] as List<XFile>;
      setState(() {
        _categories = results[0] as List<Category>;
        _images = recovered
            .take(ImageUploadRepository.maxImages)
            .toList(growable: false);
        _loadingCategories = false;
      });
    } on RequestCancelled {
      return;
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
  });

  Future<void> _pickImages() async {
    try {
      final selected = await _galleryPicker.pickImages();
      await _addSelectedImages(selected);
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError =
              'No pudimos seleccionar las imágenes. Intenta nuevamente.',
        );
      }
    }
  }

  Future<void> _addSelectedImages(List<XFile> selected) async {
    if (!mounted || selected.isEmpty) return;
    final combined = [..._images, ...selected];
    if (combined.length > ImageUploadRepository.maxImages) {
      setState(() => _submitError = 'Puedes seleccionar máximo 5 imágenes.');
      return;
    }
    for (final image in selected) {
      await _imageUploadRepository.validateImage(image);
    }
    if (mounted) {
      setState(() {
        _images = List.unmodifiable(combined);
        _submitError = null;
        _remoteFieldErrors = Map.of(_remoteFieldErrors)..remove('imagenes');
      });
    }
  }

  Future<void> _takePhoto() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tomar una foto'),
        content: const Text(
          'DonnaP necesita acceso a la cámara para tomar fotografías de los artículos que deseas donar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (shouldContinue != true || !mounted) return;

    final result = await _cameraCaptureService.capture();
    if (!mounted) return;
    switch (result.status) {
      case CameraCaptureStatus.granted:
        if (result.image != null) await _addSelectedImages([result.image!]);
      case CameraCaptureStatus.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado. Puedes usar la galería.')),
        );
      case CameraCaptureStatus.permanentlyDenied:
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permiso de cámara bloqueado'),
            content: const Text(
              'Activa el permiso de cámara desde los ajustes del sistema para tomar una foto.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Abrir ajustes'),
              ),
            ],
          ),
        );
        if (openSettings == true) await _cameraCaptureService.openSettings();
      case CameraCaptureStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'La cámara no está disponible. Puedes usar la galería.')),
        );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images = [..._images]..removeAt(index);
      _remoteFieldErrors = Map.of(_remoteFieldErrors)..remove('imagenes');
    });
  }

  Future<void> _submit() async {
    if (_queued || _submitting || !_formKey.currentState!.validate()) return;
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
      if (widget.cacheUserId case final userId?) {
        for (final image in _images) {
          await _imageUploadRepository.validateImage(image);
        }
        await _donationRepository.enqueueCreation(
          cacheUserId: userId,
          city: widget.city,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _categories.firstWhere((item) => item.id == _categoryId),
          images: _images,
        );
        if (!mounted) return;
        setState(() => _queued = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Donación guardada. Se publicará cuando haya conexión.',
            ),
          ),
        );
        if (GoRouter.maybeOf(context) != null) context.go(AppRoutes.home);
        return;
      }
      final references = await _imageUploadRepository.uploadImages(_images);
      final donation = await _donationRepository.createDonation(
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
      if (mounted) _applyRemoteFieldErrors(error);
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
                            onChanged: (_) => _clearRemoteFieldError('titulo'),
                            validator: (value) {
                              final normalized = _normalizeDonationTitle(
                                value ?? '',
                              );
                              if (normalized.length < 5) {
                                return 'El título debe tener al menos 5 caracteres.';
                              }
                              if (normalized.length > 100) {
                                return 'El título no puede superar 100 caracteres.';
                              }
                              return _remoteFieldErrors['titulo'];
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
                            onChanged: (_) =>
                                _clearRemoteFieldError('descripcion'),
                            validator: (value) {
                              final normalized = value?.trim() ?? '';
                              if (normalized.length < 20) {
                                return 'La descripción debe tener al menos 20 caracteres.';
                              }
                              if (normalized.length > 1000) {
                                return 'La descripción no puede superar 1000 caracteres.';
                              }
                              if (!_isPlainDonationDescription(normalized)) {
                                return 'Escribe la descripción como texto simple, sin etiquetas, enlaces ni formatos especiales.';
                              }
                              return _remoteFieldErrors['descripcion'];
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
                                : (value) {
                                    setState(() {
                                      _categoryId = value;
                                      _remoteFieldErrors = Map.of(
                                        _remoteFieldErrors,
                                      )..remove('categoriaId');
                                    });
                                    _formKey.currentState?.validate();
                                  },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecciona una categoría.';
                              }
                              return _remoteFieldErrors['categoriaId'];
                            },
                          ),
                          SizedBox(height: spacing.large),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const Key('takeDonationPhotoButton'),
                                  onPressed:
                                      _submitting ||
                                          _images.length >=
                                              ImageUploadRepository.maxImages
                                      ? null
                                      : _takePhoto,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: const Text('Tomar foto'),
                                ),
                              ),
                              SizedBox(width: spacing.small),
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const Key('pickDonationImagesButton'),
                                  onPressed:
                                      _submitting ||
                                          _images.length >=
                                              ImageUploadRepository.maxImages
                                      ? null
                                      : _pickImages,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: Text('Galería (${_images.length}/5)'),
                                ),
                              ),
                            ],
                          ),
                          if (_remoteFieldErrors['imagenes']
                              case final error?) ...[
                            SizedBox(height: spacing.small),
                            Text(
                              error,
                              key: const Key('donationImagesError'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
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
