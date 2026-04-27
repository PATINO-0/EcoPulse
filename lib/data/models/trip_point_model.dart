import 'package:ecopulse/data/models/location_sample_model.dart';

class TripPointModel {
  final String id;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speedKmh;
  final double? heading;
  final double? accuracy;
  final double? speedAccuracy;
  final double? altitudeAccuracy;
  final double? headingAccuracy;
  final bool isMocked;
  final DateTime recordedAt;

  const TripPointModel({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.altitude,
    this.speedKmh,
    this.heading,
    this.accuracy,
    this.speedAccuracy,
    this.altitudeAccuracy,
    this.headingAccuracy,
    this.isMocked = false,
  });

  factory TripPointModel.fromMap(Map<String, dynamic> map) {
    return TripPointModel(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      latitude: _toDouble(map['latitude']) ?? 0,
      longitude: _toDouble(map['longitude']) ?? 0,
      altitude: _toDouble(map['altitude']),
      speedKmh: _toDouble(map['speed_kmh']),
      heading: _toDouble(map['heading']),
      accuracy: _toDouble(map['accuracy']),
      speedAccuracy: _toDouble(map['speed_accuracy']),
      altitudeAccuracy: _toDouble(map['altitude_accuracy']),
      headingAccuracy: _toDouble(map['heading_accuracy']),
      isMocked: map['is_mocked'] as bool? ?? false,
      recordedAt: DateTime.parse(map['recorded_at'].toString()),
    );
  }

  LocationSampleModel toLocationSample() {
    final speedKmhValue = speedKmh ?? 0;
    final speedMpsValue = speedKmhValue / 3.6;

    return LocationSampleModel(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speedMps: speedMpsValue,
      speedKmh: speedKmhValue,
      rawSpeedMps: speedMpsValue,
      calculatedSpeedMps: speedMpsValue,
      heading: heading ?? 0,
      accuracy: accuracy ?? 0,
      speedAccuracy: speedAccuracy,
      altitudeAccuracy: altitudeAccuracy,
      headingAccuracy: headingAccuracy,
      isMocked: isMocked,
      timestamp: recordedAt,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}