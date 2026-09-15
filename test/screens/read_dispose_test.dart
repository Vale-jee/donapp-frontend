import 'dart:async';

import 'package:drift/native.dart';
import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';

import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/repositories/category_repository.dart';
import 'package:donapp_mobile/repositories/request_repository.dart';
import 'package:donapp_mobile/screens/explore_donations_screen.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/screens/my_donations_screen.dart';
import 'package:donapp_mobile/screens/requests_screen.dart';
import 'package:donapp_mobile/screens/request_detail_screen.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/services/auth_state_controller.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  for (final flow in [
    'explore',
    'explore-cache',
    'detail',
    'own',
    'sent',
    'received',
    'request',
  ]) {
    testWidgets(
      '$flow dispose propaga aborto por Repository y no muestra error',
      (tester) async {
        final transport = _AbortClient();
        final client = ApiClient(
          client: transport,
          endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
        );
        final donations = DonationRepository.fromService(
          DonationService(apiClient: client),
        );
        final requests = RequestRepository.fromService(
          RequestService(apiClient: client),
        );
        final db = flow == 'explore-cache'
            ? AppDatabase.forTesting(NativeDatabase.memory())
            : null;
        if (db != null) addTearDown(db.close);
        final screen = switch (flow) {
          'explore-cache' => ExploreDonationsScreen(
            cacheUserId: 1,
            repository: DonationRepository(
              DonationLocalDataSource(db!),
              DonationRemoteDataSource(
                DonationService(apiClient: client),
                CategoryService(apiClient: client),
              ),
            ),
          ),
          'explore' => ExploreDonationsScreen(
            donationRepository: donations,
            categoryRepository: CategoryRepository.fromService(
              CategoryService(apiClient: client),
            ),
          ),
          'detail' => DonationDetailScreen(
            donationId: 1,
            donationRepository: donations,
          ),
          'own' => MyDonationsScreen(donationRepository: donations),
          'sent' => SentRequestsScreen(requestRepository: requests),
          'received' => ReceivedRequestsScreen(requestRepository: requests),
          _ => RequestDetailScreen(requestId: 1, requestRepository: requests),
        };
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: screen),
        );
        await tester.pump();
        expect(transport.active, flow.startsWith('explore') ? 2 : 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        if (db != null) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(transport.aborted, transport.active);
        expect(transport.closed, isFalse);
        expect(tester.takeException(), isNull);
        // A new request using the same shared transport is unaffected.
        expect(await client.get('/new', successStatusCodes: {200}), {
          'success': true,
          'data': null,
        });
      },
    );
  }

  test(
    'restauracion global tardia no notifica un controlador descartado',
    () async {
      final coordinator = _Restoration();
      final controller = AuthStateController(sessionCoordinator: coordinator);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final restoration = controller.restore();
      controller.dispose();
      coordinator.result.complete(const SessionRestoreResult.noSession());
      await restoration;
      expect(notifications, 0);
    },
  );
}

class _AbortClient extends http.BaseClient {
  int active = 0;
  int aborted = 0;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.Abortable && request.abortTrigger != null) {
      active++;
      return request.abortTrigger!.then((_) {
        aborted++;
        throw http.RequestAbortedException(request.url);
      });
    }
    return Future.value(
      http.StreamedResponse(
        Stream.value('{"success":true,"data":null}'.codeUnits),
        200,
      ),
    );
  }

  @override
  void close() {
    closed = true;
  }
}

class _Restoration extends SessionCoordinator {
  final result = Completer<SessionRestoreResult>();
  @override
  Future<SessionRestoreResult> restoreSession() => result.future;
}
