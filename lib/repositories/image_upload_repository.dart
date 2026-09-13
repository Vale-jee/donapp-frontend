import 'package:image_picker/image_picker.dart';

import '../services/image_upload_service.dart';
import '../data/remote/image_upload_remote_data_source.dart';

class ImageUploadRepository {
  static const maxImages = maxDonationImages;
  ImageUploadRepository({ImageUploadRemoteDataSource? remote})
    : _remote = remote ?? ImageUploadRemoteDataSource();
  final ImageUploadRemoteDataSource _remote;
  ImageUploadRemoteDataSource get _delegate => _remote;
  factory ImageUploadRepository.fromService(ImageUploadService service) =>
      ImageUploadRepository(remote: ImageUploadRemoteDataSource(service));
  Future<void> validateImage(XFile image) => _delegate.validateImage(image);
  Future<List<String>> uploadImages(List<XFile> images) =>
      _delegate.uploadImages(images);
}
