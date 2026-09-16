import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraCaptureStatus { granted, denied, permanentlyDenied, error }

class CameraCaptureResult {
  const CameraCaptureResult._({required this.status, this.image, this.message});

  const CameraCaptureResult.granted(XFile image)
    : this._(status: CameraCaptureStatus.granted, image: image);
  const CameraCaptureResult.denied()
    : this._(status: CameraCaptureStatus.denied);
  const CameraCaptureResult.permanentlyDenied()
    : this._(status: CameraCaptureStatus.permanentlyDenied);
  const CameraCaptureResult.error(String message)
    : this._(status: CameraCaptureStatus.error, message: message);

  final CameraCaptureStatus status;
  final XFile? image;
  final String? message;
}

abstract interface class CameraCaptureService {
  Future<CameraCaptureResult> capture();
  Future<bool> openSettings();
}

class PermissionCameraCaptureService implements CameraCaptureService {
  PermissionCameraCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CameraCaptureResult> capture() async {
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const CameraCaptureResult.permanentlyDenied();
    }
    final permission = status.isGranted
        ? status
        : await Permission.camera.request();
    if (permission.isPermanentlyDenied || permission.isRestricted) {
      return const CameraCaptureResult.permanentlyDenied();
    }
    if (!permission.isGranted) return const CameraCaptureResult.denied();

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      return image == null
          ? const CameraCaptureResult.denied()
          : CameraCaptureResult.granted(image);
    } catch (_) {
      return const CameraCaptureResult.error(
        'No pudimos acceder a la cámara. Puedes elegir una imagen de la galería.',
      );
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
