class AppPermissionStatusModel {
  final bool locationServiceEnabled;
  final bool locationPermissionGranted;
  final bool locationPermissionDeniedForever;
  final bool notificationPermissionGranted;
  final bool activityRecognitionGranted;
  final List<String> warnings;

  const AppPermissionStatusModel({
    required this.locationServiceEnabled,
    required this.locationPermissionGranted,
    required this.locationPermissionDeniedForever,
    required this.notificationPermissionGranted,
    required this.activityRecognitionGranted,
    required this.warnings,
  });

  bool get canTrackTrips {
    return locationServiceEnabled && locationPermissionGranted;
  }

  String get statusMessage {
    if (!locationServiceEnabled) {
      return 'El GPS está apagado. Activa la ubicación del dispositivo.';
    }

    if (locationPermissionDeniedForever) {
      return 'La ubicación fue denegada permanentemente. Debes activarla desde configuración.';
    }

    if (!locationPermissionGranted) {
      return 'EcoPulse necesita permiso de ubicación para registrar trayectos.';
    }

    return 'Permisos principales listos para registrar trayectos.';
  }
}