import 'dart:math';

import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final speedServiceProvider = Provider<SpeedService>((ref) {
  return SpeedService();
});

class SpeedService {
  static const double maxAcceptedAccelerationMps2 = 6.0;
  static const double maxAcceptedBrakingMps2 = -9.0;
  static const double maxReasonableRoadSpeedKmh = 180;

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

    if (meters.isNaN || meters.isInfinite || meters < 0) {
      return 0;
    }

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

    final acceleration = deltaSpeed / deltaTimeSeconds;

    return acceleration.clamp(
      maxAcceptedBrakingMps2,
      maxAcceptedAccelerationMps2,
    );
  }

  double smoothAccelerationMps2({
    required double? previousAccelerationMps2,
    required double currentAccelerationMps2,
  }) {
    if (previousAccelerationMps2 == null) {
      return currentAccelerationMps2;
    }

    return (previousAccelerationMps2 * 0.35) + (currentAccelerationMps2 * 0.65);
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
        current.timestamp.difference(previous.timestamp).inMilliseconds / 1000;

    if (deltaSeconds <= 0) {
      return true;
    }

    final impliedSpeedKmh = distanceKm / (deltaSeconds / 3600);

    final hasImpossibleSpeed = impliedSpeedKmh > maxReasonableRoadSpeedKmh;
    final hasPoorAccuracy = current.accuracy > 35;
    final hasLargeSpeedMismatch =
        (impliedSpeedKmh - current.speedKmh).abs() > 80 && current.accuracy > 25;

    return hasImpossibleSpeed && (hasPoorAccuracy || hasLargeSpeedMismatch);
  }

  double calculateImpliedSpeedKmh({
    required LocationSampleModel previous,
    required LocationSampleModel current,
  }) {
    final distanceKm = calculateDistanceKm(
      previous: previous,
      current: current,
    );

    final deltaHours =
        current.timestamp.difference(previous.timestamp).inMilliseconds /
            1000 /
            3600;

    if (deltaHours <= 0) {
      return 0;
    }

    return max(0, distanceKm / deltaHours);
  }
}