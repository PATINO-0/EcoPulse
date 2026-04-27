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
      recordedAt: DateTime.parse(map['recorded_at'].toString()),
    );
  }

  LocationSampleModel toLocationSample() {
    final speedKmhValue = speedKmh ?? 0;

    return LocationSampleModel(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speedMps: speedKmhValue / 3.6,
      speedKmh: speedKmhValue,
      heading: heading ?? 0,
      accuracy: accuracy ?? 0,
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