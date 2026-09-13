import 'package:image_picker/image_picker.dart';

import '../../services/image_upload_service.dart';

class ImageUploadRemoteDataSource {
  ImageUploadRemoteDataSource([ImageUploadService? service])
    : _service = service ?? ImageUploadService();
  final ImageUploadService _service;
  ImageUploadService get _delegate => _service;
  Future<void> validateImage(XFile image) => _delegate.validateImage(image);
  Future<List<String>> uploadImages(List<XFile> images) =>
      _delegate.uploadImages(images);
}
