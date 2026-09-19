import 'package:donapp_mobile/services/camera_capture_service.dart';
import 'package:donapp_mobile/services/donation_gallery_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _Picker picker;
  late List<String> calls;
  late PermissionStatus status;
  late PermissionStatus requested;

  setUp(() {
    picker = _Picker();
    calls = [];
    status = PermissionStatus.granted;
    requested = PermissionStatus.granted;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'checkPermissionStatus') return status.index;
      if (call.method == 'requestPermissions') {
        expect(call.arguments, [Permission.camera.value]);
        return {Permission.camera.value: requested.index};
      }
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('permiso concedido abre cámara sin pedir metadatos completos', () async {
    final result = await PermissionCameraCaptureService(picker: picker)
        .capture();
    expect(result.status, CameraCaptureStatus.granted);
    expect(picker.source, ImageSource.camera);
    expect(picker.metadata, false);
    expect(calls, ['checkPermissionStatus']);
  });

  test('permiso solicitado y concedido abre cámara', () async {
    status = PermissionStatus.denied;
    final result = await PermissionCameraCaptureService(picker: picker)
        .capture();
    expect(result.status, CameraCaptureStatus.granted);
    expect(calls, ['checkPermissionStatus', 'requestPermissions']);
  });

  test('cancelación del selector no es denegación', () async {
    picker.image = null;
    expect(
      (await PermissionCameraCaptureService(picker: picker).capture()).status,
      CameraCaptureStatus.cancelled,
    );
  });

  for (final entry in {
    PermissionStatus.denied: CameraCaptureStatus.denied,
    PermissionStatus.permanentlyDenied: CameraCaptureStatus.permanentlyDenied,
    PermissionStatus.restricted: CameraCaptureStatus.restricted,
  }.entries) {
    test('${entry.key} no abre cámara', () async {
      status = entry.key;
      requested = entry.key;
      expect(
        (await PermissionCameraCaptureService(picker: picker).capture()).status,
        entry.value,
      );
      expect(picker.source, isNull);
    });
  }

  test(
    'fallo de plataforma al consultar permiso permite degradar a galería',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      final result = await PermissionCameraCaptureService(picker: picker)
          .capture();
      expect(result.status, CameraCaptureStatus.error);
      expect(result.message, contains('galería'));
      expect(picker.source, isNull);
    },
  );

  test('cámara no disponible devuelve error seguro', () async {
    picker.fail = true;
    final result = await PermissionCameraCaptureService(picker: picker)
        .capture();
    expect(result.status, CameraCaptureStatus.error);
    expect(result.message, contains('galería'));
    expect(result.message, isNot(contains('technical')));
  });

  test(
    'galería usa selector sin pedir permisos ni metadatos completos',
    () async {
      await ImagePickerGallery(picker: picker).pickImages();
      expect(picker.metadata, false);
      expect(calls, isEmpty);
    },
  );
}

class _Picker extends ImagePicker {
  XFile? image = XFile('camera.jpg');
  ImageSource? source;
  bool? metadata;
  bool fail = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    metadata = requestFullMetadata;
    if (fail) throw PlatformException(code: 'technical');
    return image;
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    metadata = requestFullMetadata;
    return [];
  }
}
