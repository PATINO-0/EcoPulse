import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/sensor_sample_model.dart';

class TripPointSampleModel {
  final LocationSampleModel location;
  final SensorSampleModel sensor;
  final double? calculatedAccelerationMps2;

  const TripPointSampleModel({
    required this.location,
    required this.sensor,
    this.calculatedAccelerationMps2,
  });

  Map<String, dynamic> toInsertMap({
    required String tripId,
  }) {
    return {
      'trip_id': tripId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'altitude': location.altitude,
      'speed_kmh': location.speedKmh,
      'heading': location.heading,
      'accuracy': location.accuracy,
      'acceleration_x': sensor.userAccelerationX ?? sensor.accelerationX,
      'acceleration_y': sensor.userAccelerationY ?? sensor.accelerationY,
      'acceleration_z': sensor.userAccelerationZ ?? sensor.accelerationZ,
      'gyroscope_x': sensor.gyroscopeX,
      'gyroscope_y': sensor.gyroscopeY,
      'gyroscope_z': sensor.gyroscopeZ,
      'magnetometer_x': sensor.magnetometerX,
      'magnetometer_y': sensor.magnetometerY,
      'magnetometer_z': sensor.magnetometerZ,
      'barometer_pressure': sensor.barometerPressure,
      'recorded_at': location.timestamp.toIso8601String(),
    };
  }
}