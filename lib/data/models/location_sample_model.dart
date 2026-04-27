import 'dart:math';

import 'package:geolocator/geolocator.dart';

class LocationSampleModel {
  final double latitude;
  final double longitude;
  final double? altitude;

  /// Velocidad filtrada que debe usar la app para UI, cálculos y eventos.
  final double speedMps;
  final double speedKmh;

  /// Velocidad cruda reportada por el GPS del sistema operativo.
  final double rawSpeedMps;

  /// Velocidad calculada por distancia / tiempo entre dos puntos.
  final double calculatedSpeedMps;

  final double heading;
  final double accuracy;
  final double? speedAccuracy;
  final double? altitudeAccuracy;
  final double? headingAccuracy;
  final bool isMocked;
  final DateTime timestamp;

  const LocationSampleModel({
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.speedKmh,
    required this.rawSpeedMps,
    required this.calculatedSpeedMps,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
    required this.isMocked,
    this.altitude,
    this.speedAccuracy,
    this.altitudeAccuracy,
    this.headingAccuracy,
  });

  factory LocationSampleModel.fromPosition(
    Position position, {
    double? calculatedSpeedMps,
    double? filteredSpeedMps,
  }) {
    final normalizedRawSpeedMps = _normalizeSpeed(position.speed);
    final normalizedFilteredSpeedMps =
        _normalizeSpeed(filteredSpeedMps ?? normalizedRawSpeedMps);

    return LocationSampleModel(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speedMps: normalizedFilteredSpeedMps,
      speedKmh: normalizedFilteredSpeedMps * 3.6,
      rawSpeedMps: normalizedRawSpeedMps,
      calculatedSpeedMps: _normalizeSpeed(
        calculatedSpeedMps ?? normalizedRawSpeedMps,
      ),
      heading: _normalizeHeading(position.heading),
      accuracy: max(0, position.accuracy),
      speedAccuracy: _normalizeNullableMetric(position.speedAccuracy),
      altitudeAccuracy: _normalizeNullableMetric(position.altitudeAccuracy),
      headingAccuracy: _normalizeNullableMetric(position.headingAccuracy),
      timestamp: position.timestamp ?? DateTime.now(),
      isMocked: position.isMocked,
    );
  }

  LocationSampleModel copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speedMps,
    double? rawSpeedMps,
    double? calculatedSpeedMps,
    double? heading,
    double? accuracy,
    double? speedAccuracy,
    double? altitudeAccuracy,
    double? headingAccuracy,
    DateTime? timestamp,
    bool? isMocked,
  }) {
    final nextSpeedMps = _normalizeSpeed(speedMps ?? this.speedMps);

    return LocationSampleModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speedMps: nextSpeedMps,
      speedKmh: nextSpeedMps * 3.6,
      rawSpeedMps: _normalizeSpeed(rawSpeedMps ?? this.rawSpeedMps),
      calculatedSpeedMps: _normalizeSpeed(
        calculatedSpeedMps ?? this.calculatedSpeedMps,
      ),
      heading: _normalizeHeading(heading ?? this.heading),
      accuracy: max(0, accuracy ?? this.accuracy),
      speedAccuracy: speedAccuracy ?? this.speedAccuracy,
      altitudeAccuracy: altitudeAccuracy ?? this.altitudeAccuracy,
      headingAccuracy: headingAccuracy ?? this.headingAccuracy,
      timestamp: timestamp ?? this.timestamp,
      isMocked: isMocked ?? this.isMocked,
    );
  }

  bool get hasAcceptableAccuracy {
    return !isMocked && accuracy <= 35;
  }

  bool get hasReliableSpeed {
    return speedAccuracy == null || speedAccuracy! <= 4.5;
  }

  bool get isStationary {
    return speedKmh < 2;
  }

  double get rawSpeedKmh {
    return rawSpeedMps * 3.6;
  }

  double get calculatedSpeedKmh {
    return calculatedSpeedMps * 3.6;
  }

  Map<String, dynamic> toDebugMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_kmh': speedKmh,
      'raw_speed_kmh': rawSpeedKmh,
      'calculated_speed_kmh': calculatedSpeedKmh,
      'heading': heading,
      'accuracy': accuracy,
      'speed_accuracy': speedAccuracy,
      'altitude_accuracy': altitudeAccuracy,
      'heading_accuracy': headingAccuracy,
      'is_mocked': isMocked,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static double _normalizeSpeed(double value) {
    if (value.isNaN || value.isInfinite || value < 0) {
      return 0;
    }

    return value;
  }

  static double _normalizeHeading(double value) {
    if (value.isNaN || value.isInfinite || value < 0) {
      return 0;
    }

    return value % 360;
  }

  static double? _normalizeNullableMetric(double? value) {
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return null;
    }

    return value;
  }
}