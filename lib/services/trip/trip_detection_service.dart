import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripDetectionServiceProvider = Provider<TripDetectionService>((ref) {
  return TripDetectionService();
});

class TripDetectionService {
  static const double autoStartSpeedKmh = 10;
  static const double idleSpeedKmh = 2;
  static const Duration autoStartValidationDuration = Duration(seconds: 12);
  static const Duration autoFinishIdleDuration = Duration(minutes: 10);

  DateTime? _movingStartedAt;
  DateTime? _idleStartedAt;

  bool shouldAutoStart(LocationSampleModel location) {
    if (!location.hasAcceptableAccuracy) {
      _movingStartedAt = null;
      return false;
    }

    if (location.speedKmh < autoStartSpeedKmh) {
      _movingStartedAt = null;
      return false;
    }

    _movingStartedAt ??= location.timestamp;

    final movingDuration = location.timestamp.difference(_movingStartedAt!);

    return movingDuration >= autoStartValidationDuration;
  }

  bool shouldAutoFinish(LocationSampleModel location) {
    final idleSeconds = currentIdleSeconds(location);

    return idleSeconds >= autoFinishIdleDuration.inSeconds;
  }

  int currentIdleSeconds(LocationSampleModel location) {
    if (!location.hasAcceptableAccuracy) {
      return _idleStartedAt == null
          ? 0
          : location.timestamp.difference(_idleStartedAt!).inSeconds;
    }

    if (location.speedKmh > idleSpeedKmh) {
      _idleStartedAt = null;
      return 0;
    }

    _idleStartedAt ??= location.timestamp;

    return location.timestamp.difference(_idleStartedAt!).inSeconds;
  }

  void resetAutoStart() {
    _movingStartedAt = null;
  }

  void resetIdle() {
    _idleStartedAt = null;
  }

  void resetAll() {
    resetAutoStart();
    resetIdle();
  }
}