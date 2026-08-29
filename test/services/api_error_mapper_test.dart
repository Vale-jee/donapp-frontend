import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiErrorMapper', () {
    test('traduce los códigos comunes con mensajes aprobados', () {
      final cases = <int, (ApiErrorType, String)>{
        400: (
          ApiErrorType.validation,
          'Revisa los datos ingresados e intenta nuevamente.',
        ),
        404: (
          ApiErrorType.notFound,
          'No encontramos la información solicitada.',
        ),
        409: (
          ApiErrorType.conflict,
          'No pudimos completar la acción porque la información cambió. '
              'Actualiza e intenta nuevamente.',
        ),
        429: (
          ApiErrorType.rateLimited,
          'Has realizado demasiados intentos. Espera un momento y vuelve a intentarlo.',
        ),
        500: (
          ApiErrorType.server,
          'DonApp no está disponible en este momento. Intenta nuevamente más tarde.',
        ),
        503: (
          ApiErrorType.server,
          'DonApp no está disponible en este momento. Intenta nuevamente más tarde.',
        ),
      };

      for (final MapEntry(key: status, value: expected) in cases.entries) {
        final error = ApiErrorMapper.fromHttp(
          statusCode: status,
          body: const {'message': 'detalle interno'},
        );
        expect(error.type, expected.$1);
        expect(error.message, expected.$2);
      }
    });

    test('diferencia 401 de login y sesión protegida', () {
      final login = ApiErrorMapper.fromHttp(
        statusCode: 401,
        body: const {},
        context: ApiRequestContext.login,
      );
      final session = ApiErrorMapper.fromHttp(
        statusCode: 401,
        body: const {},
        context: ApiRequestContext.protectedSession,
      );

      expect(login.type, ApiErrorType.invalidCredentials);
      expect(login.message, 'El correo o la contraseña son incorrectos.');
      expect(session.type, ApiErrorType.authentication);
      expect(
        session.message,
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
      );
    });

    test('diferencia cuenta inactiva y falta de permisos', () {
      final inactive = ApiErrorMapper.fromHttp(
        statusCode: 403,
        body: const {'message': 'La cuenta se encuentra inactiva.'},
        context: ApiRequestContext.protectedSession,
      );
      final forbidden = ApiErrorMapper.fromHttp(
        statusCode: 403,
        body: const {
          'message': 'No tiene permisos para realizar esta operación.',
        },
        context: ApiRequestContext.protectedSession,
      );

      expect(inactive.type, ApiErrorType.inactiveAccount);
      expect(
        inactive.message,
        'Tu cuenta está inactiva. Comunícate con soporte.',
      );
      expect(forbidden.type, ApiErrorType.forbidden);
      expect(forbidden.message, 'No tienes permiso para realizar esta acción.');
    });

    test(
      'un 403 protegido sin causa de inactividad es permiso insuficiente',
      () {
        final error = ApiErrorMapper.fromHttp(
          statusCode: 403,
          body: const {},
          context: ApiRequestContext.protectedSession,
        );

        expect(error.type, ApiErrorType.forbidden);
        expect(error.message, 'No tienes permiso para realizar esta acción.');
      },
    );

    test('trata 422 defensivamente como validación', () {
      final error = ApiErrorMapper.fromHttp(statusCode: 422, body: const {});
      expect(error.type, ApiErrorType.validation);
      expect(error.message, isNot(contains('422')));
    });

    test('un código desconocido usa respuesta inesperada', () {
      final error = ApiErrorMapper.fromHttp(statusCode: 418, body: const {});
      expect(error.type, ApiErrorType.unexpectedResponse);
      expect(
        error.message,
        'Recibimos una respuesta inesperada. Intenta nuevamente más tarde.',
      );
    });

    test('conserva mensaje seguro y errores por campo', () {
      final error = ApiErrorMapper.fromHttp(
        statusCode: 400,
        body: const {
          'message': 'Datos inválidos.',
          'errors': [
            {'field': 'email', 'message': 'El correo ya está en uso.'},
          ],
        },
        allowSafeBackendMessage: true,
      );

      expect(error.message, 'El correo ya está en uso.');
      expect(error.fieldErrors, hasLength(1));
      expect(error.fieldErrors.single.field, 'email');
    });

    test('conserva un conflicto funcional seguro', () {
      final error = ApiErrorMapper.fromHttp(
        statusCode: 409,
        body: const {
          'message': 'Ya enviaste una solicitud para esta donación.',
        },
        allowSafeBackendMessage: true,
      );
      expect(error.message, 'Ya enviaste una solicitud para esta donación.');
    });

    test('rechaza mensaje técnico y usa fallback local', () {
      final error = ApiErrorMapper.fromHttp(
        statusCode: 400,
        body: const {'message': 'HTTP API backend status code'},
        allowSafeBackendMessage: true,
      );
      expect(
        error.message,
        'Revisa los datos ingresados e intenta nuevamente.',
      );
    });

    test('500 nunca expone el mensaje recibido', () {
      final error = ApiErrorMapper.fromHttp(
        statusCode: 500,
        body: const {'message': 'contraseña SQL secreta'},
        allowSafeBackendMessage: true,
      );
      expect(error.message, isNot(contains('SQL')));
      expect(error.message, isNot(contains('secreta')));
    });
  });
}
