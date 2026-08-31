import 'dart:typed_data';

import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/screens/create_donation_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  const validTitle = 'Mesa para donar';
  const validDescription = 'Mesa de madera en buen estado para donar.';
  const plainTextError =
      'Escribe la descripción como texto simple, sin etiquetas, enlaces ni formatos especiales.';

  final titleCases = <({String name, String value, String? error})>[
    (
      name: 'acepta un título válido después de normalizar espacios',
      value: '  Mesa   para   donar  ',
      error: null,
    ),
    (
      name: 'rechaza espacios repetidos si normalizado queda bajo el mínimo',
      value: 'a    b',
      error: 'El título debe tener al menos 5 caracteres.',
    ),
    (
      name: 'acepta exactamente 5 caracteres normalizados',
      value: 'abcde',
      error: null,
    ),
    (name: 'acepta exactamente 100 caracteres', value: 'a' * 100, error: null),
    (
      name: 'rechaza 101 caracteres',
      value: 'a' * 101,
      error: 'El título no puede superar 100 caracteres.',
    ),
  ];
  for (final testCase in titleCases) {
    testWidgets(testCase.name, (tester) async {
      await _validateFormFields(
        tester,
        title: testCase.value,
        description: validDescription,
      );
      if (testCase.error case final error?) {
        expect(find.text(error), findsOneWidget);
      } else {
        expect(
          find.text('El título debe tener al menos 5 caracteres.'),
          findsNothing,
        );
        expect(
          find.text('El título no puede superar 100 caracteres.'),
          findsNothing,
        );
      }
    });
  }

  final descriptionCases = <({String name, String value, String? error})>[
    (
      name: 'acepta descripción de exactamente 20 caracteres',
      value: 'a' * 20,
      error: null,
    ),
    (
      name: 'acepta descripción de exactamente 1000 caracteres',
      value: 'a' * 1000,
      error: null,
    ),
    (
      name: 'rechaza descripción menor de 20 caracteres',
      value: 'a' * 19,
      error: 'La descripción debe tener al menos 20 caracteres.',
    ),
    (
      name: 'rechaza descripción mayor de 1000 caracteres',
      value: 'a' * 1001,
      error: 'La descripción no puede superar 1000 caracteres.',
    ),
    (
      name: 'rechaza etiqueta HTML',
      value: 'Descripción con <strong>HTML</strong> visible.',
      error: plainTextError,
    ),
    (
      name: 'rechaza enlace Markdown',
      value: 'Descripción con un [enlace](https://example.com).',
      error: plainTextError,
    ),
    (
      name: 'rechaza imagen Markdown',
      value: 'Descripción con ![imagen](https://example.com/a.png).',
      error: plainTextError,
    ),
    (
      name: 'rechaza encabezado Markdown',
      value: '# Encabezado no permitido en esta descripción',
      error: plainTextError,
    ),
    (
      name: 'rechaza cita Markdown',
      value: '> Cita no permitida dentro de esta descripción',
      error: plainTextError,
    ),
    (
      name: 'rechaza bloque cercado',
      value: 'Descripción con bloque ```código``` no permitido.',
      error: plainTextError,
    ),
    (
      name: 'acepta texto plano válido',
      value: 'Una mesa de madera conservada y lista para donar.',
      error: null,
    ),
  ];
  for (final testCase in descriptionCases) {
    testWidgets(testCase.name, (tester) async {
      await _validateFormFields(
        tester,
        title: validTitle,
        description: testCase.value,
      );
      if (testCase.error case final error?) {
        expect(find.text(error), findsOneWidget);
      } else {
        expect(
          find.text('La descripción debe tener al menos 20 caracteres.'),
          findsNothing,
        );
        expect(
          find.text('La descripción no puede superar 1000 caracteres.'),
          findsNothing,
        );
        expect(find.text(plainTextError), findsNothing);
      }
    });
  }

  testWidgets('no muestra errores al construir el formulario', (tester) async {
    await tester.pumpWidget(_app(picker: _Picker(const [])));
    await tester.pumpAndSettle();

    expect(
      find.text('El título debe tener al menos 5 caracteres.'),
      findsNothing,
    );
    expect(
      find.text('La descripción debe tener al menos 20 caracteres.'),
      findsNothing,
    );
    expect(find.text('Selecciona una categoría.'), findsNothing);
    expect(find.text('Selecciona al menos una imagen.'), findsNothing);
  });

  testWidgets(
    'título inválido aparece al perder foco y desaparece al corregir',
    (tester) async {
      await tester.pumpWidget(_app(picker: _Picker(const [])));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('donationTitleField')));
      await tester.enterText(
        find.byKey(const Key('donationTitleField')),
        'a    b',
      );
      await tester.tap(find.byKey(const Key('donationDescriptionField')));
      await tester.pump();
      expect(
        find.text('El título debe tener al menos 5 caracteres.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('donationTitleField')),
        'Mesa válida',
      );
      await tester.tap(find.byKey(const Key('donationDescriptionField')));
      await tester.pump();
      expect(
        find.text('El título debe tener al menos 5 caracteres.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'descripción inválida aparece al perder foco y desaparece al corregir',
    (tester) async {
      await tester.pumpWidget(_app(picker: _Picker(const [])));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('donationDescriptionField')));
      await tester.enterText(
        find.byKey(const Key('donationDescriptionField')),
        'Muy corta',
      );
      await tester.tap(find.byKey(const Key('donationTitleField')));
      await tester.pump();
      expect(
        find.text('La descripción debe tener al menos 20 caracteres.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('donationDescriptionField')),
        validDescription,
      );
      await tester.tap(find.byKey(const Key('donationTitleField')));
      await tester.pump();
      expect(
        find.text('La descripción debe tener al menos 20 caracteres.'),
        findsNothing,
      );
    },
  );

  testWidgets('categoría usa onUnfocus y submit acepta una selección válida', (
    tester,
  ) async {
    await tester.pumpWidget(_app(picker: _Picker(const [])));
    await tester.pumpAndSettle();

    final category = tester.widget<DropdownButtonFormField<int>>(
      find.byKey(const Key('donationCategoryField')),
    );
    expect(category.autovalidateMode, AutovalidateMode.onUnfocus);

    await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pump();
    expect(find.text('Selecciona una categoría.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('donationCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muebles').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pump();
    expect(find.text('Selecciona una categoría.'), findsNothing);
  });

  testWidgets('submit inválido revalida y no inicia peticiones remotas', (
    tester,
  ) async {
    final upload = _UploadService();
    final donation = _DonationService();
    await tester.pumpWidget(
      _app(picker: _Picker(const []), upload: upload, donation: donation),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pump();

    expect(
      find.text('El título debe tener al menos 5 caracteres.'),
      findsOneWidget,
    );
    expect(
      find.text('La descripción debe tener al menos 20 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('Selecciona una categoría.'), findsOneWidget);
    expect(upload.calls, 0);
    expect(donation.calls, 0);
  });

  testWidgets('campos válidos sin imágenes conservan el error manual', (
    tester,
  ) async {
    final upload = _UploadService();
    final donation = _DonationService();
    await tester.pumpWidget(
      _app(picker: _Picker(const []), upload: upload, donation: donation),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('donationTitleField')),
      validTitle,
    );
    await tester.enterText(
      find.byKey(const Key('donationDescriptionField')),
      validDescription,
    );
    await tester.tap(find.byKey(const Key('donationCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muebles').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pump();

    expect(find.text('Selecciona al menos una imagen.'), findsOneWidget);
    expect(upload.calls, 0);
    expect(donation.calls, 0);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('categoría no desborda a 240 px con texto $scale×', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const categoryName = 'Muebles y artículos grandes para el hogar';
      await tester.pumpWidget(
        _app(
          picker: _Picker(const []),
          categoryName: categoryName,
          mediaQuery: MediaQueryData(
            size: const Size(240, 640),
            textScaler: TextScaler.linear(scale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final selector = find.byKey(const Key('donationCategoryField'));
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text(categoryName).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final selectedText = tester.widget<Text>(find.text(categoryName).last);
      expect(selectedText.maxLines, 2);
    });
  }

  testWidgets('cancelar selección no muestra error', (tester) async {
    await tester.pumpWidget(_app(picker: _Picker(const [])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickDonationImagesButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('createDonationError')), findsNothing);
    expect(find.text('Seleccionar imágenes (0/5)'), findsOneWidget);
  });

  testWidgets('fallo del selector muestra un mensaje útil', (tester) async {
    await tester.pumpWidget(_app(picker: _FailingPicker()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pickDonationImagesButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos seleccionar las imágenes. Intenta nuevamente.'),
      findsOneWidget,
    );
  });

  testWidgets('selecciona una y varias imágenes', (tester) async {
    final picker = _Picker([_image('one.jpg'), _image('two.png')]);
    await tester.pumpWidget(_app(picker: picker));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickDonationImagesButton')));
    await tester.pumpAndSettle();
    expect(find.text('Seleccionar imágenes (2/5)'), findsOneWidget);
    expect(find.byKey(const Key('selectedDonationImages')), findsOneWidget);
  });

  testWidgets('rechaza selección superior a cinco', (tester) async {
    await tester.pumpWidget(
      _app(picker: _Picker(List.generate(6, (index) => _image('$index.jpg')))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickDonationImagesButton')));
    await tester.pumpAndSettle();
    expect(find.text('Puedes seleccionar máximo 5 imágenes.'), findsOneWidget);
    expect(find.text('Seleccionar imágenes (0/5)'), findsOneWidget);
  });

  testWidgets('publica solo después de subir todas y preserva orden', (
    tester,
  ) async {
    final upload = _UploadService();
    final donation = _DonationService();
    DonationDetail? created;
    await tester.pumpWidget(
      _app(
        picker: _Picker([_image('one.jpg'), _image('two.jpg')]),
        upload: upload,
        donation: donation,
        onCreated: (value) => created = value,
      ),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();
    expect(donation.calls, 1);
    expect(donation.references, [
      'https://images.test/one.jpg',
      'https://images.test/two.jpg',
    ]);
    expect(created?.id, 9);
  });

  testWidgets('fallo parcial no envía POST y el reintento funciona', (
    tester,
  ) async {
    final upload = _UploadService(failFirst: true);
    final donation = _DonationService();
    await tester.pumpWidget(
      _app(
        picker: _Picker([_image('one.jpg'), _image('two.jpg')]),
        upload: upload,
        donation: donation,
      ),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();
    expect(donation.calls, 0);
    expect(find.byKey(const Key('createDonationError')), findsOneWidget);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();
    expect(donation.calls, 1);
  });

  testWidgets('recupera selección perdida de Android', (tester) async {
    await tester.pumpWidget(
      _app(picker: _Picker(const [], recovered: [_image('recovered.jpg')])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seleccionar imágenes (1/5)'), findsOneWidget);
  });

  testWidgets('mapea varios errores remotos a sus campos con HTTP 422', (
    tester,
  ) async {
    final donation = _DonationService(
      error: const ApiException(
        ApiErrorType.validation,
        'Error remoto de título',
        statusCode: 422,
        fieldErrors: [
          ApiFieldError(field: 'titulo', message: 'Error remoto de título'),
          ApiFieldError(
            field: 'descripcion',
            message: 'Error remoto de descripción',
          ),
          ApiFieldError(
            field: 'categoriaId',
            message: 'Error remoto de categoría',
          ),
          ApiFieldError(field: 'imagenes', message: 'Error remoto de imágenes'),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(picker: _Picker([_image('one.jpg')]), donation: donation),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();

    expect(find.text('Error remoto de título'), findsOneWidget);
    expect(find.text('Error remoto de descripción'), findsOneWidget);
    expect(find.text('Error remoto de categoría'), findsOneWidget);
    expect(find.text('Error remoto de imágenes'), findsOneWidget);
    expect(find.byKey(const Key('createDonationError')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('donationTitleField')),
      'Título corregido',
    );
    await tester.tap(find.byKey(const Key('donationDescriptionField')));
    await tester.pump();
    expect(find.text('Error remoto de título'), findsNothing);
    expect(find.text('Error remoto de descripción'), findsOneWidget);
    expect(donation.calls, 1);

    await tester.ensureVisible(find.byKey(const Key('donationCategoryField')));
    await tester.tap(find.byKey(const Key('donationCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ropa').last);
    await tester.pumpAndSettle();
    expect(find.text('Error remoto de categoría'), findsNothing);
    expect(find.text('Error remoto de descripción'), findsOneWidget);
    expect(donation.calls, 1);

    final picker = find.byKey(const Key('pickDonationImagesButton')).first;
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.text('Error remoto de imágenes'), findsNothing);
    expect(find.text('Error remoto de descripción'), findsOneWidget);
    expect(donation.calls, 1);
  });

  for (final imageField in ['imagenes', 'imagenes.0']) {
    testWidgets('$imageField se muestra como error de imágenes', (
      tester,
    ) async {
      final donation = _DonationService(
        error: ApiException(
          ApiErrorType.validation,
          'Referencia inválida',
          statusCode: 400,
          fieldErrors: [
            ApiFieldError(field: imageField, message: 'Referencia inválida'),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(picker: _Picker([_image('one.jpg')]), donation: donation),
      );
      await tester.pumpAndSettle();
      await _completeForm(tester);
      await tester.tap(find.byKey(const Key('publishDonationButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('donationImagesError')), findsOneWidget);
      expect(find.text('Referencia inválida'), findsOneWidget);
    });
  }

  testWidgets('mantiene _root y campos desconocidos como error general', (
    tester,
  ) async {
    final donation = _DonationService(
      error: const ApiException(
        ApiErrorType.validation,
        'Datos inválidos',
        statusCode: 400,
        fieldErrors: [
          ApiFieldError(field: '_root', message: 'Error general remoto'),
          ApiFieldError(field: 'otroCampo', message: 'Campo no reconocido'),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(picker: _Picker([_image('one.jpg')]), donation: donation),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('createDonationError')), findsOneWidget);
    expect(
      find.text('Error general remoto\nCampo no reconocido'),
      findsOneWidget,
    );
  });

  testWidgets('mantiene un 409 sin errores de campo como error general', (
    tester,
  ) async {
    final donation = _DonationService(
      error: const ApiException(
        ApiErrorType.conflict,
        'La categoría seleccionada no está activa.',
        statusCode: 409,
      ),
    );
    await tester.pumpWidget(
      _app(picker: _Picker([_image('one.jpg')]), donation: donation),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('createDonationError')), findsOneWidget);
    expect(
      find.text('La categoría seleccionada no está activa.'),
      findsOneWidget,
    );
  });

  testWidgets('la validación local tiene prioridad sobre el error remoto', (
    tester,
  ) async {
    final donation = _DonationService(
      error: const ApiException(
        ApiErrorType.validation,
        'Error remoto de título',
        statusCode: 400,
        fieldErrors: [
          ApiFieldError(field: 'titulo', message: 'Error remoto de título'),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(picker: _Picker([_image('one.jpg')]), donation: donation),
    );
    await tester.pumpAndSettle();
    await _completeForm(tester);
    await tester.tap(find.byKey(const Key('publishDonationButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('donationTitleField')), 'abc');
    await tester.tap(find.byKey(const Key('donationDescriptionField')));
    await tester.pump();

    expect(
      find.text('El título debe tener al menos 5 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('Error remoto de título'), findsNothing);
    expect(donation.calls, 1);
  });
}

Future<void> _validateFormFields(
  WidgetTester tester, {
  required String title,
  required String description,
}) async {
  await tester.pumpWidget(_app(picker: _Picker(const [])));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('donationTitleField')), title);
  await tester.enterText(
    find.byKey(const Key('donationDescriptionField')),
    description,
  );
  await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
  await tester.tap(find.byKey(const Key('publishDonationButton')));
  await tester.pump();
}

Future<void> _completeForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('donationTitleField')),
    'Mesa para donar',
  );
  await tester.enterText(
    find.byKey(const Key('donationDescriptionField')),
    'Mesa de madera en buen estado para donar.',
  );
  await tester.tap(find.byKey(const Key('donationCategoryField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Muebles').last);
  await tester.pumpAndSettle();
  final picker = find.byKey(const Key('pickDonationImagesButton')).first;
  await tester.ensureVisible(picker);
  await tester.tap(picker);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('publishDonationButton')));
}

Widget _app({
  required DonationGalleryPicker picker,
  _UploadService? upload,
  _DonationService? donation,
  ValueChanged<DonationDetail>? onCreated,
  String categoryName = 'Muebles',
  MediaQueryData? mediaQuery,
}) {
  final screen = CreateDonationScreen(
    galleryPicker: picker,
    imageUploadService: upload ?? _UploadService(),
    donationService: donation ?? _DonationService(),
    categoryService: _CategoryService(categoryName),
    onCreated: onCreated,
  );
  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null
        ? screen
        : MediaQuery(data: mediaQuery, child: screen),
  );
}

class _Picker implements DonationGalleryPicker {
  _Picker(this.selected, {this.recovered = const []});
  final List<XFile> selected;
  final List<XFile> recovered;
  @override
  Future<List<XFile>> pickImages() async => selected;
  @override
  Future<List<XFile>> retrieveLostImages() async => recovered;
}

class _FailingPicker implements DonationGalleryPicker {
  @override
  Future<List<XFile>> pickImages() async => throw StateError('picker failed');

  @override
  Future<List<XFile>> retrieveLostImages() async => const [];
}

class _UploadService extends ImageUploadService {
  _UploadService({this.failFirst = false});
  final bool failFirst;
  int calls = 0;
  @override
  Future<void> validateImage(XFile image) async {}
  @override
  Future<List<String>> uploadImages(List<XFile> images) async {
    calls++;
    if (failFirst && calls == 1) {
      throw const ApiException(
        ApiErrorType.network,
        'No pudimos subir una imagen.',
      );
    }
    return List.generate(
      images.length,
      (index) => 'https://images.test/${index == 0 ? 'one' : 'two'}.jpg',
      growable: false,
    );
  }
}

class _DonationService extends DonationService {
  _DonationService({this.error});

  ApiException? error;
  int calls = 0;
  List<String>? references;
  @override
  Future<DonationDetail> createDonation({
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) async {
    calls++;
    references = imageReferences;
    if (error case final failure?) throw failure;
    return _detail;
  }
}

class _CategoryService extends CategoryService {
  _CategoryService(this.name);

  final String name;

  @override
  Future<List<Category>> getCategories() async => [
    Category(id: 4, nombre: name, descripcion: null),
    const Category(id: 5, nombre: 'Ropa', descripcion: null),
  ];
}

XFile _image(String name) =>
    XFile.fromData(Uint8List(10), name: name, mimeType: 'image/jpeg');

final _detail = DonationDetail(
  id: 9,
  titulo: 'Mesa para donar',
  descripcion: 'Mesa de madera en buen estado para donar.',
  ciudad: 'Bogotá',
  estado: DonationStatus.publicada,
  createdAt: DateTime.utc(2026, 8, 28),
  updatedAt: DateTime.utc(2026, 8, 28),
  categoriaId: 4,
  categoriaNombre: 'Muebles',
  imagenes: const [],
);
