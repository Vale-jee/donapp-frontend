import 'dart:async';
import 'dart:io';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/read_cancellation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';

void main() {
  for (final streaming in [false, true]) {
    test(
      'IOClient aborta GET real (body iniciado=$streaming) y sigue operativo',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final transport = IOClient();
        final arrived = Completer<void>();
        final release = Completer<void>();
        addTearDown(() async {
          if (!release.isCompleted) release.complete();
          transport.close();
          await server.close(force: true);
        });
        server.listen((request) async {
          try {
            if (request.uri.path == '/hold') {
              if (streaming) {
                request.response.write('{"success":true,"data":');
                await request.response.flush();
              }
              arrived.complete();
              await release.future;
              request.response.write(
                streaming ? 'null}' : '{"success":true,"data":null}',
              );
            } else {
              request.response.write('{"success":true,"data":null}');
            }
            await request.response.close();
          } on Object {
            // The peer may already have aborted the held response.
          }
        });
        final client = ApiClient(
          client: transport,
          endpointBuilder: (path) =>
              Uri.parse('http://127.0.0.1:${server.port}$path'),
          retryDelay: (_) async => fail('Cancelar no debe reintentar'),
        );
        final cancellation = ReadCancellation();
        final operation = client.get(
          '/hold',
          cancellation: cancellation,
          successStatusCodes: {200},
        );
        final expectation = expectLater(
          operation,
          throwsA(isA<RequestCancelled>()),
        );
        await arrived.future.timeout(const Duration(seconds: 5));
        cancellation.cancel();
        // The server still has not replied/finished its body: completion here
        // comes from IOClient's abort, not a discarded eventual response.
        await expectation.timeout(const Duration(seconds: 5));
        expect(release.isCompleted, isFalse);
        expect(
          await client.get(
            '/new',
            cancellation: ReadCancellation(),
            successStatusCodes: {200},
          ),
          {'success': true, 'data': null},
        );
      },
    );
  }

  test('cancelacion previa no envia ni recupera sesion', () async {
    var calls = 0;
    final recovery = _Recovery();
    final client = ApiClient(
      client: MockClient((_) async {
        calls++;
        return _ok();
      }),
      endpointBuilder: _endpoint,
      sessionRecovery: recovery,
    );
    final cancellation = ReadCancellation()..cancel();
    await expectLater(
      client.get(
        '/test',
        cancellation: cancellation,
        context: ApiRequestContext.protectedSession,
        successStatusCodes: {200},
      ),
      throwsA(isA<RequestCancelled>()),
    );
    expect(calls, 0);
    expect(recovery.calls, 0);
  });

  test(
    'RequestAbortedException no es network ni timeout y no reintenta',
    () async {
      var calls = 0;
      final client = ApiClient(
        client: MockClient((_) async {
          calls++;
          throw http.RequestAbortedException();
        }),
        endpointBuilder: _endpoint,
        retryDelay: (_) async => fail('No retry'),
      );
      await expectLater(
        client.get('/test', successStatusCodes: {200}),
        throwsA(allOf(isA<RequestCancelled>(), isNot(isA<ApiException>()))),
      );
      expect(calls, 1);
    },
  );

  test('cancelar durante backoff impide el siguiente intento', () async {
    var calls = 0;
    final waiting = Completer<void>();
    final release = Completer<void>();
    final client = ApiClient(
      client: MockClient((_) async {
        calls++;
        throw http.ClientException('offline');
      }),
      endpointBuilder: _endpoint,
      retryDelay: (_) {
        waiting.complete();
        return release.future;
      },
    );
    final cancellation = ReadCancellation();
    final expectation = expectLater(
      client.get(
        '/test',
        cancellation: cancellation,
        successStatusCodes: {200},
      ),
      throwsA(isA<RequestCancelled>()),
    );
    await waiting.future;
    cancellation.cancel();
    await expectation;
    release.complete();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
  });

  test('cancelar antes de procesar 401 no inicia refresh', () async {
    final cancellation = ReadCancellation();
    final recovery = _Recovery();
    final client = ApiClient(
      client: MockClient((_) async {
        cancellation.cancel();
        return http.Response('', 401);
      }),
      endpointBuilder: _endpoint,
      sessionRecovery: recovery,
    );
    await expectLater(
      client.get(
        '/test',
        cancellation: cancellation,
        headers: {'Authorization': 'Bearer old'},
        context: ApiRequestContext.protectedSession,
        successStatusCodes: {200},
      ),
      throwsA(isA<RequestCancelled>()),
    );
    expect(recovery.calls, 0);
  });

  test('cancelar mientras otro refresh termina no reenvia el GET', () async {
    final cancellation = ReadCancellation();
    final pending = Completer<String>();
    final started = Completer<void>();
    final recovery = _Recovery(() {
      started.complete();
      return pending.future;
    });
    var calls = 0;
    final client = ApiClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 401);
      }),
      endpointBuilder: _endpoint,
      sessionRecovery: recovery,
    );
    final expectation = expectLater(
      client.get(
        '/test',
        cancellation: cancellation,
        headers: {'Authorization': 'Bearer old'},
        context: ApiRequestContext.protectedSession,
        successStatusCodes: {200},
      ),
      throwsA(isA<RequestCancelled>()),
    );
    await started.future;
    cancellation.cancel();
    await expectation;
    pending.complete('new');
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(recovery.calls, 1);
  });

  for (final method in ['POST', 'PATCH']) {
    test(
      '$method no se aborta por cancelar la lectura de su propietario',
      () async {
        final arrived = Completer<void>();
        final response = Completer<http.Response>();
        var calls = 0;
        final client = ApiClient(
          client: MockClient((request) {
            calls++;
            expect(request, isNot(isA<http.Abortable>()));
            arrived.complete();
            return response.future;
          }),
          endpointBuilder: _endpoint,
        );
        final cancellation = ReadCancellation();
        final operation = cancellation.run(
          () => method == 'POST'
              ? client.post('/test', successStatusCodes: {200})
              : client.patch('/test', successStatusCodes: {200}),
        );
        await arrived.future;
        cancellation.cancel();
        response.complete(_ok());
        expect(await operation, {'success': true, 'data': null});
        expect(calls, 1);
      },
    );
  }
}

Uri _endpoint(String path) => Uri.parse('https://donapp.test$path');
http.Response _ok() => http.Response('{"success":true,"data":null}', 200);

class _Recovery implements SessionRecovery {
  _Recovery([this.handler]);
  final Future<String> Function()? handler;
  int calls = 0;
  @override
  Future<String> recoverAfterUnauthorized(String token) {
    calls++;
    return handler?.call() ?? Future.value('new');
  }

  @override
  Future<Never> invalidateAuthentication(ApiException cause) async =>
      throw cause;
  @override
  Future<Never> invalidateInactiveAccount(ApiException cause) async =>
      throw cause;
}
