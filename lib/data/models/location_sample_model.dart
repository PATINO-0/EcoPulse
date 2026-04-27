import 'package:geolocator/geolocator.dart';

class LocationSampleModel {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double speedMps;
  final double speedKmh;
  final double heading;
  final double accuracy;
  final DateTime timestamp;

  const LocationSampleModel({
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.speedKmh,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
  });

  factory LocationSampleModel.fromPosition(Position position) {
    final normalizedSpeedMps = position.speed.isNegative ? 0.0 : position.speed;

    return LocationSampleModel(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speedMps: normalizedSpeedMps,
      speedKmh: normalizedSpeedMps * 3.6,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  bool get hasAcceptableAccuracy {
    return accuracy <= 50;
  }

  Map<String, dynamic> toDebugMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_kmh': speedKmh,
      'heading': heading,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}