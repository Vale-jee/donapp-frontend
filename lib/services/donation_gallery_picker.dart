import 'package:image_picker/image_picker.dart';

abstract interface class DonationGalleryPicker {
  Future<List<XFile>> pickImages();
  Future<List<XFile>> retrieveLostImages();
}

class ImagePickerGallery implements DonationGalleryPicker {
  ImagePickerGallery({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<List<XFile>> pickImages() => _picker.pickMultiImage(imageQuality: 85);

  @override
  Future<List<XFile>> retrieveLostImages() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.exception != null) return const [];
    return response.files ?? const [];
  }
}
