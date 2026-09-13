import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:donapp_mobile/data/remote/category_remote_data_source.dart';
import 'package:donapp_mobile/data/remote/request_remote_data_source.dart';
import 'package:donapp_mobile/data/local/session_local_data_source.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/repositories/category_repository.dart';
import 'package:donapp_mobile/repositories/request_repository.dart';
import 'package:donapp_mobile/repositories/session_repository.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';

void main() {
  test('screens and UI controllers do not import concrete data access', () {
    final files = Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    files.add(File('lib/services/auth_state_controller.dart'));
    for (final path in ['lib/widgets', 'lib/controllers']) {
      if (Directory(path).existsSync()) {
        files.addAll(
          Directory(path)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')),
        );
      }
    }
    final forbidden = RegExp(
      r'''(?:import|export)\s+['"][^'"]*(api_client|donation_service|request_service|profile_service|category_service|auth_service|image_upload_service|token_storage|data/local|data/remote|package:http|package:drift)''',
    );
    for (final file in files) {
      expect(
        forbidden.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });

  test(
    'category repository delegates once to injected remote source',
    () async {
      final remote = _Categories();
      final result = await CategoryRepository(remote: remote).getCategories();
      expect(result.single.nombre, 'Libros');
      expect(remote.calls, 1);
    },
  );

  test('category remote source preserves service errors', () async {
    const error = ApiException(ApiErrorType.network, 'Sin conexion');
    final repository = CategoryRepository(
      remote: CategoryRemoteDataSource(_FailingCategories(error)),
    );
    await expectLater(repository.getCategories(), throwsA(same(error)));
  });

  test(
    'request repository and remote source preserve routes and errors',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        endpointBuilder: (path) => Uri.parse('https://api.test$path'),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{"message":"No disponible"}', 404);
        }),
      );
      final repository = RequestRepository(
        remote: RequestRemoteDataSource(
          RequestService(apiClient: client, tokenStorage: _Tokens()),
        ),
      );
      final operations = <Future<Object?> Function()>[
        () => repository.createRequest(7),
        () => repository.getSentRequests(page: 2, limit: 5),
        () => repository.getReceivedRequests(page: 3, limit: 6),
        () => repository.getRequestById(8),
        () => repository.acceptRequest(8),
        () => repository.rejectRequest(8),
        () => repository.cancelRequest(8),
      ];
      for (final operation in operations) {
        await expectLater(
          operation(),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'status',
              404,
            ),
          ),
        );
      }
      expect(requests, hasLength(7));
      expect(requests.first.method, 'POST');
      expect(requests.first.body, contains('7'));
      expect(requests[1].url.queryParameters['page'], '2');
      expect(requests[2].url.queryParameters['limit'], '6');
      expect(requests[3].url.path, endsWith('/8'));
      expect(requests[4].url.path, endsWith('/8/aceptar'));
      expect(requests[5].url.path, endsWith('/8/rechazar'));
      expect(requests[6].url.path, endsWith('/8/cancelar'));
    },
  );

  test(
    'session repository uses local source and injected token storage',
    () async {
      final storage = _Tokens();
      final repository = SessionRepository(
        local: SessionLocalDataSource(storage),
      );
      await repository.saveTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );
      expect(await repository.readAccessToken(), 'new-access');
      expect(await repository.readRefreshToken(), 'new-refresh');
      await repository.clearTokens();
      expect(await repository.readAccessToken(), isNull);
      expect(await repository.readRefreshToken(), isNull);
    },
  );
}

class _Categories extends CategoryRemoteDataSource {
  int calls = 0;
  @override
  Future<List<Category>> getCategories() async {
    calls++;
    return [const Category(id: 1, nombre: 'Libros', descripcion: null)];
  }
}

class _FailingCategories extends CategoryService {
  const _FailingCategories(this.error);
  final ApiException error;
  @override
  Future<List<Category>> getCategories() async => throw error;
}

class _Tokens extends TokenStorage {
  String? access = 'access';
  String? refresh = 'refresh';
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}
