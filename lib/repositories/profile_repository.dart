import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../data/remote/profile_remote_data_source.dart';

class ProfileRepository {
  ProfileRepository({ProfileRemoteDataSource? remote})
    : _remote = remote ?? ProfileRemoteDataSource();
  final ProfileRemoteDataSource _remote;
  ProfileRemoteDataSource get _delegate => _remote;
  factory ProfileRepository.fromService(ProfileService service) =>
      ProfileRepository(remote: ProfileRemoteDataSource(service));
  Future<UserProfile> getProfile(String accessToken) =>
      _delegate.getProfile(accessToken);
}
