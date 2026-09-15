import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:donapp_mobile/repositories/auth_repository.dart';
import 'package:donapp_mobile/repositories/category_repository.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/repositories/profile_repository.dart';
import 'package:donapp_mobile/repositories/request_repository.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _statuses = {
  400: ApiErrorType.validation,
  401: ApiErrorType.authentication,
  403: ApiErrorType.forbidden,
  404: ApiErrorType.notFound,
  409: ApiErrorType.conflict,
  422: ApiErrorType.validation,
  429: ApiErrorType.rateLimited,
  500: ApiErrorType.server,
  502: ApiErrorType.server,
  503: ApiErrorType.server,
  504: ApiErrorType.server,
};

void main() {
  for (final entry in _statuses.entries) {
    for (final body in [
      '',
      '<html>private stack</html>',
      jsonEncode({
        'message': 'TypeError: private stack',
        'errors': [
          {'field': 'titulo', 'message': 'Revisa el titulo.'},
        ],
      }),
    ]) {
      test(
        '${entry.key} atraviesa fuentes y repositories con body $body',
        () async {
          final operations = _operations(
            (_) async => http.Response(body, entry.key),
          );
          for (final operation in operations.entries) {
            final error = await _capture(operation.value());
            expect(
              error.type,
              operation.key == 'login' && entry.key == 401
                  ? ApiErrorType.invalidCredentials
                  : entry.value,
              reason: operation.key,
            );
            expect(error.statusCode, entry.key);
            expect(error.message, isNot(contains('private')));
            if ((entry.key == 400 || entry.key == 409 || entry.key == 422) &&
                body.startsWith('{')) {
              expect(error.fieldErrors.single.field, 'titulo');
              expect(error.fieldErrors.single.message, 'Revisa el titulo.');
            }
          }
        },
      );
    }
  }
  for (final scenario in [
    (const SocketException('private address'), ApiErrorType.network),
    (http.ClientException('private transport'), ApiErrorType.network),
    (TimeoutException('private timeout'), ApiErrorType.timeout),
  ]) {
    test(
      '${scenario.$1.runtimeType} conserva familia hasta repository',
      () async {
        for (final operation in _operations(
          (_) async => throw scenario.$1,
        ).values) {
          final error = await _capture(operation());
          expect(error.type, scenario.$2);
          expect(error.statusCode, isNull);
          expect(error.message, isNot(contains('private')));
        }
      },
    );
  }
  for (final body in [
    '{broken',
    '[]',
    '{"success":true}',
    '{"success":true,"data":{}}',
  ]) {
    test(
      'JSON o contrato invalido no se convierte en error de red: $body',
      () async {
        final operations = _operations((_) async => http.Response(body, 200));
        for (final name in [
          'login',
          'profile',
          'categories',
          'detail',
          'requests',
        ]) {
          final error = await _capture(operations[name]!());
          expect(error.type, ApiErrorType.unexpectedResponse, reason: name);
          expect(error.message, isNot(contains(body)));
        }
      },
    );
  }
}

Map<String, Future<Object?> Function()> _operations(
  Future<http.Response> Function(http.Request) handler,
) {
  final client = ApiClient(
    retryDelay: (_) async {},
    client: MockClient(handler),
    endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
  );
  final auth = AuthRepository.fromService(AuthService(apiClient: client));
  final donations = DonationRepository.fromService(
    DonationService(apiClient: client),
  );
  final requests = RequestRepository.fromService(
    RequestService(apiClient: client),
  );
  return {
    'login': () => auth.login('ana@example.com', 'password'),
    'register': () => auth.register(
      nombreCompleto: 'Ana Perez',
      nombreVisible: 'Ana',
      email: 'ana@example.com',
      password: 'password',
      ciudad: 'Bogota',
    ),
    'profile': () =>
        ProfileRepository.fromService(ProfileService(apiClient: client))
            .getProfile('access'),
    'categories': () =>
        CategoryRepository.fromService(CategoryService(apiClient: client))
            .getCategories(),
    'detail': () => donations.getDonationById(1),
    'create': () => donations.createDonation(
      title: 'Mesa',
      description: 'Mesa para donar',
      categoryId: 1,
      imageReferences: ['https://images.test/a.jpg'],
    ),
    'requests': () => requests.getSentRequests(),
    'requestAction': () => requests.acceptRequest(1),
  };
}

Future<ApiException> _capture(Future<Object?> operation) async {
  try {
    await operation;
    fail('Se esperaba ApiException');
  } on ApiException catch (error) {
    return error;
  }
}
