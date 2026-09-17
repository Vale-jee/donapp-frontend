import 'package:geolocator/geolocator.dart';

enum LocationShareStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unavailable,
  error,
}

class LocationShareResult {
  const LocationShareResult._({
    required this.status,
    this.latitude,
    this.longitude,
    this.message,
  });

  const LocationShareResult.granted({
    required double latitude,
    required double longitude,
  }) : this._(
         status: LocationShareStatus.granted,
         latitude: latitude,
         longitude: longitude,
       );

  const LocationShareResult.denied()
    : this._(status: LocationShareStatus.denied);

  const LocationShareResult.permanentlyDenied()
    : this._(status: LocationShareStatus.permanentlyDenied);

  const LocationShareResult.serviceDisabled()
    : this._(status: LocationShareStatus.serviceDisabled);

  const LocationShareResult.unavailable()
    : this._(status: LocationShareStatus.unavailable);

  const LocationShareResult.error(String message)
    : this._(status: LocationShareStatus.error, message: message);

  final LocationShareStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;
}

abstract interface class LocationShareService {
  Future<LocationShareResult> currentApproximateLocation();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationShareService implements LocationShareService {
  @override
  Future<LocationShareResult> currentApproximateLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationShareResult.serviceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return const LocationShareResult.permanentlyDenied();
      }
      if (permission == LocationPermission.unableToDetermine) {
        return const LocationShareResult.unavailable();
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationShareResult.permanentlyDenied();
      }
      if (permission == LocationPermission.unableToDetermine) {
        return const LocationShareResult.unavailable();
      }
      if (permission == LocationPermission.denied) {
        return const LocationShareResult.denied();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationShareResult.granted(
        latitude: _roundApproximate(position.latitude),
        longitude: _roundApproximate(position.longitude),
      );
    } catch (_) {
      return const LocationShareResult.error(
        'No pudimos obtener tu ubicación. Puedes seguir usando el chat normalmente.',
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static double _roundApproximate(double value) =>
      (value * 1000).roundToDouble() / 1000;
}
