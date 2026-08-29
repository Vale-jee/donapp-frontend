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
    return _detail;
  }
}

class _CategoryService extends CategoryService {
  _CategoryService(this.name);

  final String name;

  @override
  Future<List<Category>> getCategories() async => [
    Category(id: 4, nombre: name, descripcion: null),
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
