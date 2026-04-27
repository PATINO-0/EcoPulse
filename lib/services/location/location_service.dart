import 'dart:math';

import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  static const Duration _androidLocationInterval = Duration(milliseconds: 500);
  static const double _speedSmoothingSeconds = 1.0;
  static const double _maxAccelerationMps2 = 4.5;
  static const double _maxBrakingMps2 = 8.0;

  LocationSampleModel? _lastAcceptedLocation;

  Future<LocationSampleModel> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _buildHighAccuracySettings(),
    );

    final sample = LocationSampleModel.fromPosition(position);
    _lastAcceptedLocation = sample;

    return sample;
  }

  Stream<LocationSampleModel> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: _buildHighAccuracySettings(),
    ).map(_buildSampleWithFilteredSpeed);
  }

  void seedLocation(LocationSampleModel location) {
    _lastAcceptedLocation = location;
  }

  void resetTrackingFilter() {
    _lastAcceptedLocation = null;
  }

  LocationSettings _buildHighAccuracySettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: _androidLocationInterval,
        forceLocationManager: false,
        useMSLAltitude: true,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  LocationSampleModel _buildSampleWithFilteredSpeed(Position position) {
    final rawSample = LocationSampleModel.fromPosition(position);
    final previous = _lastAcceptedLocation;

    if (previous == null) {
      _lastAcceptedLocation = rawSample;
      return rawSample;
    }

    final deltaTimeSeconds =
        rawSample.timestamp.difference(previous.timestamp).inMilliseconds /
            1000;

    if (deltaTimeSeconds <= 0) {
      return previous;
    }

    final distanceMeters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      rawSample.latitude,
      rawSample.longitude,
    );

    final calculatedSpeedMps = max(0.0 , distanceMeters / deltaTimeSeconds);
    final measuredSpeedMps = _fuseSpeed(
      rawSample: rawSample,
      calculatedSpeedMps: calculatedSpeedMps,
    );

    final limitedSpeedMps = _limitSpeedChange(
      previousSpeedMps: previous.speedMps,
      measuredSpeedMps: measuredSpeedMps,
      deltaTimeSeconds: deltaTimeSeconds,
    );

    final filteredSpeedMps = _smoothSpeed(
      previousSpeedMps: previous.speedMps,
      measuredSpeedMps: limitedSpeedMps,
      deltaTimeSeconds: deltaTimeSeconds,
    );

    final sample = rawSample.copyWith(
      speedMps: filteredSpeedMps,
      calculatedSpeedMps: calculatedSpeedMps,
    );

    _lastAcceptedLocation = sample;

    return sample;
  }

  double _fuseSpeed({
    required LocationSampleModel rawSample,
    required double calculatedSpeedMps,
  }) {
    final rawSpeedMps = rawSample.rawSpeedMps;

    // Si ambos valores están prácticamente quietos, se fuerza cero para evitar ruido.
    if (rawSpeedMps < 0.35 && calculatedSpeedMps < 0.6) {
      return 0;
    }

    // Si el GPS reporta precisión pobre de velocidad, se prioriza distancia / tiempo.
    if (!rawSample.hasReliableSpeed) {
      return calculatedSpeedMps;
    }

    // Combinación conservadora: el GPS suele ser mejor para velocidad vehicular,
    // pero la distancia / tiempo ayuda a reaccionar cuando el sistema tarda en actualizar.
    return (rawSpeedMps * 0.75) + (calculatedSpeedMps * 0.25);
  }

  double _limitSpeedChange({
    required double previousSpeedMps,
    required double measuredSpeedMps,
    required double deltaTimeSeconds,
  }) {
    final deltaSpeed = measuredSpeedMps - previousSpeedMps;

    final maxPositiveDelta = _maxAccelerationMps2 * deltaTimeSeconds;
    final maxNegativeDelta = _maxBrakingMps2 * deltaTimeSeconds;

    if (deltaSpeed > maxPositiveDelta) {
      return previousSpeedMps + maxPositiveDelta;
    }

    if (deltaSpeed < -maxNegativeDelta) {
      return previousSpeedMps - maxNegativeDelta;
    }

    return measuredSpeedMps;
  }

  double _smoothSpeed({
    required double previousSpeedMps,
    required double measuredSpeedMps,
    required double deltaTimeSeconds,
  }) {
    final alpha = (deltaTimeSeconds /
            (_speedSmoothingSeconds + deltaTimeSeconds))
        .clamp(0.35, 0.85)
        .toDouble();

    final filteredSpeedMps =
        previousSpeedMps + alpha * (measuredSpeedMps - previousSpeedMps);

    if (filteredSpeedMps < 0.35) {
      return 0;
    }

    return max(0.0 , filteredSpeedMps);
  }
}