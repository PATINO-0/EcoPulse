import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/sensor_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drivingBehaviorServiceProvider = Provider<DrivingBehaviorService>((ref) {
  return DrivingBehaviorService();
});

class DrivingBehaviorService {
  static const double aggressiveAccelerationThreshold = 2.5;
  static const double mediumAccelerationThreshold = 1.8;
  static const double hardBrakingThreshold = -3.0;
  static const double mediumBrakingThreshold = -2.2;
  static const double inefficientSlopeThreshold = 4.0;
  static const double irregularSensorAccelerationThreshold = 3.8;
  static const double irregularGyroscopeThreshold = 1.6;
  static const Duration eventCooldown = Duration(seconds: 18);

  final Map<String, DateTime> _lastEventTimes = {};

  List<DrivingEventModel> detectEvents({
    required String tripId,
    required LocationSampleModel currentLocation,
    required SensorSampleModel sensorSample,
    required double accelerationMps2,
    required double roadGradePercent,
    required int idleTimeSeconds,
  }) {
    final events = <DrivingEventModel>[];
    final now = DateTime.now();

    final accelerationEvent = _detectAccelerationEvent(
      tripId: tripId,
      location: currentLocation,
      accelerationMps2: accelerationMps2,
      now: now,
    );

    if (accelerationEvent != null) {
      events.add(accelerationEvent);
    }

    final brakingEvent = _detectBrakingEvent(
      tripId: tripId,
      location: currentLocation,
      accelerationMps2: accelerationMps2,
      now: now,
    );

    if (brakingEvent != null) {
      events.add(brakingEvent);
    }

    final sensorMotionEvent = _detectIrregularSensorMotionEvent(
      tripId: tripId,
      location: currentLocation,
      sensorSample: sensorSample,
      accelerationMps2: accelerationMps2,
      now: now,
    );

    if (sensorMotionEvent != null) {
      events.add(sensorMotionEvent);
    }

    final slopeEvent = _detectInefficientSlopeEvent(
      tripId: tripId,
      location: currentLocation,
      accelerationMps2: accelerationMps2,
      roadGradePercent: roadGradePercent,
      now: now,
    );

    if (slopeEvent != null) {
      events.add(slopeEvent);
    }

    final idleEvent = _detectIdleEvent(
      tripId: tripId,
      location: currentLocation,
      idleTimeSeconds: idleTimeSeconds,
      now: now,
    );

    if (idleEvent != null) {
      events.add(idleEvent);
    }

    return events;
  }

  DrivingEventModel? _detectAccelerationEvent({
    required String tripId,
    required LocationSampleModel location,
    required double accelerationMps2,
    required DateTime now,
  }) {
    if (location.speedKmh < 5) {
      return null;
    }

    if (accelerationMps2 < mediumAccelerationThreshold) {
      return null;
    }

    final severity = accelerationMps2 >= aggressiveAccelerationThreshold
        ? 'high'
        : 'medium';

    return _buildEventIfAllowed(
      tripId: tripId,
      eventType: 'aggressive_acceleration',
      severity: severity,
      message:
          'Evita acelerar bruscamente. Mantén una presión suave sobre el acelerador para reducir el consumo.',
      location: location,
      accelerationMps2: accelerationMps2,
      fuelImpactEstimate: severity == 'high' ? 0.015 : 0.008,
      now: now,
    );
  }

  DrivingEventModel? _detectBrakingEvent({
    required String tripId,
    required LocationSampleModel location,
    required double accelerationMps2,
    required DateTime now,
  }) {
    if (location.speedKmh < 5) {
      return null;
    }

    if (accelerationMps2 > mediumBrakingThreshold) {
      return null;
    }

    final severity = accelerationMps2 <= hardBrakingThreshold
        ? 'high'
        : 'medium';

    return _buildEventIfAllowed(
      tripId: tripId,
      eventType: 'hard_braking',
      severity: severity,
      message:
          'Reduce la velocidad de forma progresiva. Las frenadas bruscas aumentan el desperdicio de energía.',
      location: location,
      accelerationMps2: accelerationMps2,
      fuelImpactEstimate: severity == 'high' ? 0.01 : 0.005,
      now: now,
    );
  }

  DrivingEventModel? _detectIrregularSensorMotionEvent({
    required String tripId,
    required LocationSampleModel location,
    required SensorSampleModel sensorSample,
    required double accelerationMps2,
    required DateTime now,
  }) {
    if (location.speedKmh < 8) {
      return null;
    }

    if (!sensorSample.hasMotionSensors || !sensorSample.isRecent(now: now)) {
      return null;
    }

    final hasStrongLinearMotion =
        sensorSample.userAccelerationMagnitude >= irregularSensorAccelerationThreshold;

    final hasStrongRotation =
        sensorSample.gyroscopeMagnitude >= irregularGyroscopeThreshold;

    if (!hasStrongLinearMotion && !hasStrongRotation) {
      return null;
    }

    return _buildEventIfAllowed(
      tripId: tripId,
      eventType: 'irregular_sensor_motion',
      severity: hasStrongLinearMotion ? 'medium' : 'low',
      message:
          'Movimiento brusco detectado. Conduce con suavidad y evita maniobras repentinas.',
      location: location,
      accelerationMps2: accelerationMps2,
      fuelImpactEstimate: 0.006,
      now: now,
    );
  }

  DrivingEventModel? _detectInefficientSlopeEvent({
    required String tripId,
    required LocationSampleModel location,
    required double accelerationMps2,
    required double roadGradePercent,
    required DateTime now,
  }) {
    if (roadGradePercent < inefficientSlopeThreshold) {
      return null;
    }

    if (location.speedKmh < 45) {
      return null;
    }

    if (accelerationMps2 < 1.2) {
      return null;
    }

    return _buildEventIfAllowed(
      tripId: tripId,
      eventType: 'inefficient_slope_speed',
      severity: 'medium',
      message:
          'En pendiente, evita acelerar con fuerza. Mantén una velocidad estable para reducir el consumo.',
      location: location,
      accelerationMps2: accelerationMps2,
      fuelImpactEstimate: 0.012,
      now: now,
    );
  }

  DrivingEventModel? _detectIdleEvent({
    required String tripId,
    required LocationSampleModel location,
    required int idleTimeSeconds,
    required DateTime now,
  }) {
    if (idleTimeSeconds < 180) {
      return null;
    }

    return _buildEventIfAllowed(
      tripId: tripId,
      eventType: 'idle_prolonged',
      severity: idleTimeSeconds > 420 ? 'high' : 'medium',
      message:
          'Has estado detenido varios minutos. Si es seguro hacerlo, apaga el motor para evitar consumo innecesario.',
      location: location,
      accelerationMps2: 0,
      fuelImpactEstimate: 0.01,
      now: now,
    );
  }

  DrivingEventModel? _buildEventIfAllowed({
    required String tripId,
    required String eventType,
    required String severity,
    required String message,
    required LocationSampleModel location,
    required double accelerationMps2,
    required double fuelImpactEstimate,
    required DateTime now,
  }) {
    final lastTime = _lastEventTimes[eventType];

    if (lastTime != null && now.difference(lastTime) < eventCooldown) {
      return null;
    }

    _lastEventTimes[eventType] = now;

    return DrivingEventModel(
      tripId: tripId,
      eventType: eventType,
      severity: severity,
      message: message,
      latitude: location.latitude,
      longitude: location.longitude,
      speedKmh: location.speedKmh,
      accelerationMps2: accelerationMps2,
      fuelImpactEstimate: fuelImpactEstimate,
      detectedAt: now,
    );
  }

  void resetCooldowns() {
    _lastEventTimes.clear();
  }
}