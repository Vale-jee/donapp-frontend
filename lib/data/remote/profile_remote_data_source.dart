import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource([ProfileService? service])
    : _service = service ?? ProfileService();
  final ProfileService _service;
  ProfileService get _delegate => _service;
  Future<UserProfile> getProfile(String accessToken) =>
      _delegate.getProfile(accessToken);

  Future<UserProfile> getAuthenticatedProfile() =>
      _delegate.getAuthenticatedProfile();

  Future<UserProfile> updateProfile({
    required Map<String, dynamic> changes,
  }) =>
      _delegate.updateProfile(changes: changes);
}
