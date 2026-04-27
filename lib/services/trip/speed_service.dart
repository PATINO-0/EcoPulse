import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final speedServiceProvider = Provider<SpeedService>((ref) {
  return SpeedService();
});

class SpeedService {
  double calculateDistanceKm({
    required LocationSampleModel previous,
    required LocationSampleModel current,
  }) {
    final meters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    return meters / 1000;
  }

  double calculateAccelerationMps2({
    required LocationSampleModel previous,
    required LocationSampleModel current,
  }) {
    final deltaSpeed = current.speedMps - previous.speedMps;
    final deltaTimeSeconds =
        current.timestamp.difference(previous.timestamp).inMilliseconds / 1000;

    if (deltaTimeSeconds <= 0) {
      return 0;
    }

    return deltaSpeed / deltaTimeSeconds;
  }

  bool isGpsJump({
    required LocationSampleModel previous,
    required LocationSampleModel current,
  }) {
    final distanceKm = calculateDistanceKm(
      previous: previous,
      current: current,
    );

    final deltaSeconds =
        current.timestamp.difference(previous.timestamp).inSeconds;

    if (deltaSeconds <= 0) {
      return true;
    }

    final impliedSpeedKmh = distanceKm / (deltaSeconds / 3600);

    return impliedSpeedKmh > 180 && current.accuracy > 40;
  }
}