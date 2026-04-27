import 'package:ecopulse/data/models/app_permission_status_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

final appPermissionServiceProvider = Provider<AppPermissionService>((ref) {
  return AppPermissionService();
});

class AppPermissionService {
  Future<AppPermissionStatusModel> checkPermissions() async {
    final warnings = <String>[];

    final locationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    final locationPermission = await Geolocator.checkPermission();

    final notificationStatus =
        await permissions.Permission.notification.status;

    final activityRecognitionStatus =
        await permissions.Permission.activityRecognition.status;

    final locationGranted =
        locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse;

    final locationDeniedForever =
        locationPermission == LocationPermission.deniedForever;

    if (!locationServiceEnabled) {
      warnings.add('El servicio de ubicación del teléfono está apagado.');
    }

    if (!locationGranted) {
      warnings.add('EcoPulse necesita ubicación mientras usas la app.');
    }

    if (!notificationStatus.isGranted) {
      warnings.add(
        'Las notificaciones no están activas. Algunas alertas podrían no mostrarse.',
      );
    }

    return AppPermissionStatusModel(
      locationServiceEnabled: locationServiceEnabled,
      locationPermissionGranted: locationGranted,
      locationPermissionDeniedForever: locationDeniedForever,
      notificationPermissionGranted: notificationStatus.isGranted,
      activityRecognitionGranted: activityRecognitionStatus.isGranted,
      warnings: warnings,
    );
  }

  Future<AppPermissionStatusModel> requestRequiredPermissions() async {
    var locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    if (await permissions.Permission.notification.isDenied) {
      await permissions.Permission.notification.request();
    }

    if (await permissions.Permission.activityRecognition.isDenied) {
      await permissions.Permission.activityRecognition.request();
    }

    return checkPermissions();
  }

  Future<void> openDeviceSettings() async {
    await permissions.openAppSettings();
  }
}