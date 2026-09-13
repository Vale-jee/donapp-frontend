import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:donapp_mobile/data/remote/auth_remote_data_source.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/data/remote/profile_remote_data_source.dart';
import 'package:donapp_mobile/data/remote/image_upload_remote_data_source.dart';
import 'package:donapp_mobile/data/remote/request_remote_data_source.dart';
import 'package:donapp_mobile/data/local/session_local_data_source.dart';
import 'package:donapp_mobile/repositories/auth_repository.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/repositories/profile_repository.dart';
import 'package:donapp_mobile/repositories/image_upload_repository.dart';
import 'package:donapp_mobile/repositories/request_repository.dart';
import 'package:donapp_mobile/repositories/session_repository.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/services/api_exception.dart';

// A typed failing future works for every asynchronous return type and records
// the exact boundary call, without constructing services or opening transports.
mixin _FailureSpy {
  final calls = <Invocation>[];
  final error = const ApiException(ApiErrorType.network, 'Sin conexion');
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    return Future<Never>.error(error);
  }
}

class _AuthRemote with _FailureSpy implements AuthRemoteDataSource {}

class _AuthService with _FailureSpy implements AuthService {}

class _DonationRemote with _FailureSpy implements DonationRemoteDataSource {}

class _DonationService with _FailureSpy implements DonationService {}

class _ProfileRemote with _FailureSpy implements ProfileRemoteDataSource {}

class _ProfileService with _FailureSpy implements ProfileService {}

class _ImageRemote with _FailureSpy implements ImageUploadRemoteDataSource {}

class _ImageService with _FailureSpy implements ImageUploadService {}

class _RequestRemote with _FailureSpy implements RequestRemoteDataSource {}

class _RequestService with _FailureSpy implements RequestService {}

class _SessionLocal with _FailureSpy implements SessionLocalDataSource {}

class _Storage with _FailureSpy implements TokenStorage {}

void main() {
  for (final throughService in [false, true]) {
    final boundary = throughService
        ? 'repository -> source -> service'
        : 'repository -> source';
    test('$boundary: auth forwards arguments and original errors', () async {
      final spy = throughService ? _AuthService() : _AuthRemote();
      final repo = AuthRepository(
        remote: throughService
            ? AuthRemoteDataSource(spy as AuthService)
            : spy as AuthRemoteDataSource,
      );
      await _check(spy, () => repo.login('a@b.co', 'secret'), #login, [
        'a@b.co',
        'secret',
      ]);
      await _check(
        spy,
        () => repo.register(
          nombreCompleto: 'Ana Perez',
          nombreVisible: 'Ana',
          email: 'a@b.co',
          password: 'secret',
          ciudad: 'Bogota',
        ),
        #register,
        [],
        {
          #nombreCompleto: 'Ana Perez',
          #nombreVisible: 'Ana',
          #email: 'a@b.co',
          #password: 'secret',
          #ciudad: 'Bogota',
        },
      );
      await _check(spy, () => repo.refresh('refresh'), #refresh, ['refresh']);
      await _check(spy, () => repo.logout('refresh'), #logout, ['refresh']);
    });
    test(
      '$boundary: donation operations preserve parameters and errors',
      () async {
        final spy = throughService ? _DonationService() : _DonationRemote();
        final repo = DonationRepository.remote(
          remote: throughService
              ? DonationRemoteDataSource(
                  spy as DonationService,
                  const CategoryService(),
                )
              : spy as DonationRemoteDataSource,
        );
        await _check(spy, () => repo.getDonationById(7), #getDonationById, [7]);
        await _check(
          spy,
          () => repo.getOwnDonations(page: 2, limit: 5),
          #getOwnDonations,
          [],
          {#page: 2, #limit: 5, #status: null},
        );
        await _check(
          spy,
          () => repo.getAvailableDonations(page: 3, limit: 6, categoryId: 9),
          throughService ? #getAvailableDonations : #getExplore,
          [],
          {#page: 3, #limit: 6, #categoryId: 9},
        );
        await _check(
          spy,
          () => repo.createDonation(
            clientId: 'client',
            title: 'Mesa',
            description: 'Descripcion',
            categoryId: 9,
            imageReferences: ['url'],
          ),
          #createDonation,
          [],
          {
            #clientId: 'client',
            #title: 'Mesa',
            #description: 'Descripcion',
            #categoryId: 9,
            #imageReferences: ['url'],
          },
        );
      },
    );
    test(
      '$boundary: profile and images preserve arguments and errors',
      () async {
        final profile = throughService ? _ProfileService() : _ProfileRemote();
        final repo = ProfileRepository(
          remote: throughService
              ? ProfileRemoteDataSource(profile as ProfileService)
              : profile as ProfileRemoteDataSource,
        );
        await _check(profile, () => repo.getProfile('access'), #getProfile, [
          'access',
        ]);
        final images = throughService ? _ImageService() : _ImageRemote();
        final upload = ImageUploadRepository(
          remote: throughService
              ? ImageUploadRemoteDataSource(images as ImageUploadService)
              : images as ImageUploadRemoteDataSource,
        );
        final file = XFile('photo.jpg');
        await _check(images, () => upload.validateImage(file), #validateImage, [
          file,
        ]);
        await _check(images, () => upload.uploadImages([file]), #uploadImages, [
          [file],
        ]);
      },
    );
    test(
      '$boundary: all request operations preserve errors and arguments',
      () async {
        final spy = throughService ? _RequestService() : _RequestRemote();
        final repo = RequestRepository(
          remote: throughService
              ? RequestRemoteDataSource(spy as RequestService)
              : spy as RequestRemoteDataSource,
        );
        await _check(spy, () => repo.createRequest(7), #createRequest, [7]);
        await _check(
          spy,
          () => repo.getSentRequests(page: 2, limit: 5),
          #getSentRequests,
          [],
          {#page: 2, #limit: 5, #status: null},
        );
        await _check(
          spy,
          () => repo.getReceivedRequests(page: 3, limit: 6),
          #getReceivedRequests,
          [],
          {#page: 3, #limit: 6, #status: null},
        );
        await _check(spy, () => repo.getRequestById(8), #getRequestById, [8]);
        await _check(spy, () => repo.acceptRequest(8), #acceptRequest, [8]);
        await _check(spy, () => repo.rejectRequest(8), #rejectRequest, [8]);
        await _check(spy, () => repo.cancelRequest(8), #cancelRequest, [8]);
      },
    );
    test('$boundary: local storage failures are not swallowed', () async {
      final spy = throughService ? _Storage() : _SessionLocal();
      final repo = SessionRepository(
        local: throughService
            ? SessionLocalDataSource(spy as TokenStorage)
            : spy as SessionLocalDataSource,
      );
      await _check(spy, () => repo.readAccessToken(), #readAccessToken, []);
      await _check(spy, () => repo.readRefreshToken(), #readRefreshToken, []);
      await _check(
        spy,
        () => repo.saveTokens(accessToken: 'access', refreshToken: 'refresh'),
        #saveTokens,
        [],
        {#accessToken: 'access', #refreshToken: 'refresh'},
      );
      await _check(spy, () => repo.clearTokens(), #clearTokens, []);
    });
  }
}

Future<void> _check(
  _FailureSpy spy,
  Future<dynamic> Function() operation,
  Symbol method,
  List<Object?> positional, [
  Map<Symbol, Object?> named = const {},
]) async {
  final before = spy.calls.length;
  await expectLater(operation(), throwsA(same(spy.error)));
  expect(spy.calls, hasLength(before + 1));
  final call = spy.calls.last;
  expect(call.memberName, method);
  expect(call.positionalArguments, positional);
  expect(call.namedArguments, named);
}
