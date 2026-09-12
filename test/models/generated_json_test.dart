import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/models/refreshed_tokens.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures =
      <(String, Map<String, dynamic>, dynamic Function(Map<String, dynamic>))>[
        ('AuthSession', {...tokens, 'usuario': authUser}, AuthSession.fromJson),
        ('AuthUser', authUser, AuthUser.fromJson),
        ('AuthRole', role, AuthRole.fromJson),
        ('RefreshedTokens', tokens, RefreshedTokens.fromJson),
        (
          'Category',
          {'id': 1, 'nombre': 'Books', 'descripcion': null},
          Category.fromJson,
        ),
        ('UserProfile', profile, UserProfile.fromJson),
        ('ProfileRole', role, ProfileRole.fromJson),
        ('DonationImage', image, DonationImage.fromJson),
        ('DonationDetail', donation, DonationDetail.fromJson),
        ('DonationListItem', donationItem, DonationListItem.fromJson),
        ('DonationPagination', pagination, DonationPagination.fromJson),
        (
          'DonationPage',
          {
            'donaciones': [donationItem],
            'pagination': pagination,
          },
          DonationPage.fromJson,
        ),
        (
          'RequestDonationSummary',
          requestDonation,
          RequestDonationSummary.fromJson,
        ),
        ('RequestUserSummary', user, RequestUserSummary.fromJson),
        (
          'SentRequestListItem',
          {...request, 'donante': user},
          SentRequestListItem.fromJson,
        ),
        (
          'ReceivedRequestListItem',
          {...request, 'solicitante': user},
          ReceivedRequestListItem.fromJson,
        ),
        (
          'CreatedRequest',
          {'id': 1, 'estado': 'PENDIENTE', 'donacion': requestDonation},
          CreatedRequest.fromJson,
        ),
        (
          'RequestDetail',
          {
            ...request,
            'donante': user,
            'solicitante': {...user, 'id': 2},
          },
          RequestDetail.fromJson,
        ),
        ('RequestPagination', pagination, RequestPagination.fromJson),
        (
          'CloudinaryUploadAuthorization',
          authorization,
          CloudinaryUploadAuthorization.fromJson,
        ),
      ];
  for (final fixture in fixtures) {
    test(
      '${fixture.$1}: valid, nullable, nested and extra fields round trip',
      () {
        final parsed = fixture.$3({...fixture.$2, 'ignoredExtra': 'ignored'});
        final output = parsed.toJson() as Map<String, dynamic>;
        expect(output, fixture.$2);
        expect(fixture.$3(output).toJson(), output);
      },
    );
  }
  test('RequestPage generic list round trip', () {
    final json = {
      'solicitudes': [
        {...request, 'donante': user},
      ],
      'pagination': pagination,
    };
    final page = RequestPage<SentRequestListItem>.fromJson(
      json,
      SentRequestListItem.fromJson,
    );
    expect(page.toJson((item) => item.toJson()), json);
    expect(page.requests.single.donor.visibleName, 'ana');
  });
  test(
    'RequestDetail handles both participants without inventing server actor',
    () {
      final detail = RequestDetail.fromJson({
        ...request,
        'donante': user,
        'solicitante': {...user, 'id': 2},
      });
      expect(detail.actor, RequestActor.applicant);
      expect(detail.otherUser.id, 1);
      expect(detail.applicant?.id, 2);
      expect(detail.toJson().containsKey('actor'), isFalse);
      expect(detail.toJson().containsKey('otherUser'), isFalse);
    },
  );
  test('strict integers and nonempty strings remain domain checks', () {
    for (final fixture in fixtures.where((f) => f.$2.containsKey('id'))) {
      expect(
        () => fixture.$3({...fixture.$2, 'id': 1.5}),
        throwsFormatException,
      );
    }
    expect(
      () => AuthSession.fromJson({
        ...tokens,
        'accessToken': '',
        'usuario': authUser,
      }),
      throwsFormatException,
    );
    expect(
      () => RequestUserSummary.fromJson({...user, 'fotoPerfil': ''}),
      throwsFormatException,
    );
    expect(
      Category.fromJson({'id': 1, 'nombre': '', 'descripcion': ''}).nombre,
      '',
    );
  });
  test('local image path is excluded both ways', () {
    expect(
      DonationImage.fromJson({...image, 'cachedLocalPath': '/private'})
          .cachedLocalPath,
      isNull,
    );
    expect(
      const DonationImage(
        id: 1,
        referencia: '/image',
        orden: 1,
        cachedLocalPath: '/private',
      ).toJson(),
      image,
    );
  });
  test('all request enums and nullable dates round trip', () {
    for (final status in ['PENDIENTE', 'ACEPTADA', 'RECHAZADA', 'CANCELADA']) {
      final json = {
        ...request,
        'estado': status,
        'aceptadaAt': date,
        'rechazadaAt': date,
        'canceladaAt': date,
        'donante': user,
      };
      expect(SentRequestListItem.fromJson(json).toJson(), json);
    }
    for (final cause in [
      null,
      'VOLUNTARIA',
      'OTRA_SOLICITUD_ACEPTADA',
      'DONACION_RETIRADA',
      'USUARIO_INACTIVO',
    ]) {
      final json = {...request, 'causaCancelacion': cause, 'donante': user};
      expect(SentRequestListItem.fromJson(json).toJson(), json);
    }
    for (final status in ['PUBLICADA', 'RESERVADA', 'ENTREGADA', 'RETIRADA']) {
      expect(
        DonationDetail.fromJson({...donation, 'estado': status})
            .toJson()['estado'],
        status,
      );
      expect(
        RequestDonationSummary.fromJson({...requestDonation, 'estado': status})
            .toJson()['estado'],
        status,
      );
    }
    expect(
      () => CreatedRequest.fromJson({
        'id': 1,
        'estado': 'UNKNOWN',
        'donacion': requestDonation,
      }),
      throwsFormatException,
    );
  });
  test('mutation permission remains false and images remain sorted', () {
    final detail = DonationDetail.fromMutationJson({
      ...donation,
      'puedeSolicitar': true,
      'imagenes': [
        {...image, 'orden': 2},
        image,
      ],
    });
    expect(detail.puedeSolicitar, isFalse);
    expect(detail.imagenes.map((i) => i.orden), [1, 2]);
    expect(
      () => detail.imagenes.add(DonationImage.fromJson(image)),
      throwsUnsupportedError,
    );
  });
}

const date = '2026-08-20T12:00:00.000Z';
const role = {'codigo': 'USUARIO', 'nombre': 'Usuario'};
const tokens = {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'accessTokenExpiresIn': 900,
  'refreshTokenExpiresIn': 604800,
};
const authUser = {
  'id': 1,
  'nombreVisible': 'ana',
  'fotoPerfil': null,
  'rol': role,
};
const profile = {
  'id': 1,
  'nombreCompleto': 'Ana',
  'nombreVisible': 'ana',
  'email': 'ana@example.test',
  'ciudad': 'City',
  'telefono': null,
  'fotoPerfil': null,
  'activo': true,
  'createdAt': date,
  'updatedAt': date,
  'rol': role,
};
const image = {'id': 1, 'referencia': '/image', 'orden': 1};
const donation = {
  'id': 1,
  'titulo': 'Book',
  'descripcion': 'Good',
  'ciudad': 'City',
  'estado': 'PUBLICADA',
  'createdAt': date,
  'updatedAt': date,
  'categoria': {'id': 1, 'nombre': 'Books'},
  'imagenes': [image],
  'puedeSolicitar': true,
};
const donationItem = {
  'id': 1,
  'titulo': 'Book',
  'ciudad': 'City',
  'estado': 'PUBLICADA',
  'createdAt': date,
  'updatedAt': date,
  'categoria': {'id': 1, 'nombre': 'Books'},
  'imagenPrincipal': null,
  'cantidadImagenes': 0,
};
const pagination = {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1};
const requestDonation = {
  'id': 1,
  'titulo': 'Book',
  'estado': 'PUBLICADA',
  'imagenPrincipal': null,
};
const user = {
  'id': 1,
  'nombreVisible': 'ana',
  'fotoPerfil': null,
  'ciudad': 'City',
};
const request = {
  'id': 1,
  'estado': 'PENDIENTE',
  'causaCancelacion': null,
  'aceptadaAt': null,
  'rechazadaAt': null,
  'canceladaAt': null,
  'createdAt': date,
  'updatedAt': date,
  'donacion': requestDonation,
};
const authorization = {
  'uploadUrl': 'https://api.cloudinary.com/v1_1/demo/image/upload',
  'apiKey': 'key',
  'timestamp': 123,
  'signature': 'sig',
  'folder': 'donapp/donaciones',
  'allowedFormats': 'jpg,jpeg,png,webp',
};
