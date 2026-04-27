import 'dart:math';

import 'package:ecopulse/data/models/fuel_estimation_result_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fuelEstimationServiceProvider = Provider<FuelEstimationService>((ref) {
  return FuelEstimationService();
});

class FuelEstimationService {
  static const double litersPerGallon = 3.78541;
  static const double defaultCityKmPerGallon = 35;
  static const double defaultIdleGallonsPerHour = 0.25;

  FuelEstimationResultModel estimateIncrement({
    required double previousTotalGallons,
    required double totalDistanceKm,
    required double incrementalDistanceKm,
    required LocationSampleModel? previousLocation,
    required LocationSampleModel currentLocation,
    required double accelerationMps2,
    required int idleTimeSeconds,
    required UserVehicleModel? vehicle,
  }) {
    final warnings = <String>[];

    final baseKmPerGallon = _resolveBaseKmPerGallon(
      vehicle: vehicle,
      warnings: warnings,
    );

    final deltaTimeSeconds = _resolveDeltaTimeSeconds(
      previousLocation: previousLocation,
      currentLocation: currentLocation,
    );

    final roadGradePercent = _calculateRoadGradePercent(
      previousLocation: previousLocation,
      currentLocation: currentLocation,
      incrementalDistanceKm: incrementalDistanceKm,
    );

    final baseGallons = incrementalDistanceKm <= 0
        ? 0.0
        : incrementalDistanceKm / baseKmPerGallon;

    final idleGallons = _calculateIdleGallons(
      speedKmh: currentLocation.speedKmh,
      deltaTimeSeconds: deltaTimeSeconds,
    );

    final penaltyFactor = _calculatePenaltyFactor(
      speedKmh: currentLocation.speedKmh,
      accelerationMps2: accelerationMps2,
      roadGradePercent: roadGradePercent,
      idleTimeSeconds: idleTimeSeconds,
    );

    final incrementalGallons = max(
      0.0,
      (baseGallons * penaltyFactor) + idleGallons,
    );

    final totalGallons = previousTotalGallons + incrementalGallons;
    final totalLiters = totalGallons * litersPerGallon;

    final estimatedKmPerGallon = totalGallons <= 0
        ? 0.0
        : totalDistanceKm / totalGallons;

    final estimatedLitersPer100Km = totalDistanceKm <= 0
        ? 0.0
        : (totalLiters / totalDistanceKm) * 100;

    return FuelEstimationResultModel(
      incrementalGallons: incrementalGallons,
      totalGallons: totalGallons,
      totalLiters: totalLiters,
      estimatedKmPerGallon: estimatedKmPerGallon,
      estimatedLitersPer100Km: estimatedLitersPer100Km,
      roadGradePercent: roadGradePercent,
      estimationMethod: 'physical_rules_fallback',
      warnings: warnings,
    );
  }

  double _resolveBaseKmPerGallon({
    required UserVehicleModel? vehicle,
    required List<String> warnings,
  }) {
    final cityEfficiency = vehicle?.estimatedCityKmPerGallon;
    final highwayEfficiency = vehicle?.estimatedHighwayKmPerGallon;

    if (cityEfficiency != null && cityEfficiency > 0) {
      return cityEfficiency;
    }

    if (highwayEfficiency != null && highwayEfficiency > 0) {
      warnings.add(
        'No hay rendimiento urbano del vehículo. Se usa rendimiento de carretera como aproximación.',
      );
      return highwayEfficiency * 0.82;
    }

    warnings.add(
      'No hay rendimiento del vehículo. Se usa un valor base de referencia.',
    );

    return defaultCityKmPerGallon;
  }

  double _resolveDeltaTimeSeconds({
    required LocationSampleModel? previousLocation,
    required LocationSampleModel currentLocation,
  }) {
    if (previousLocation == null) {
      return 0;
    }

    final seconds = currentLocation.timestamp
            .difference(previousLocation.timestamp)
            .inMilliseconds /
        1000;

    if (seconds <= 0 || seconds > 60) {
      return 0;
    }

    return seconds;
  }

  double _calculateIdleGallons({
    required double speedKmh,
    required double deltaTimeSeconds,
  }) {
    if (speedKmh > 2 || deltaTimeSeconds <= 0) {
      return 0;
    }

    final hours = deltaTimeSeconds / 3600;

    return defaultIdleGallonsPerHour * hours;
  }

  double _calculatePenaltyFactor({
    required double speedKmh,
    required double accelerationMps2,
    required double roadGradePercent,
    required int idleTimeSeconds,
  }) {
    var factor = 1.0;

    if (accelerationMps2 > 2.5) {
      factor += 0.12;
    } else if (accelerationMps2 > 1.6) {
      factor += 0.06;
    }

    if (accelerationMps2 < -3.0) {
      factor += 0.04;
    }

    if (speedKmh > 90) {
      factor += 0.08;
    }

    if (roadGradePercent > 3 && speedKmh > 20) {
      factor += min(0.18, roadGradePercent / 100);
    }

    if (idleTimeSeconds > 180) {
      factor += 0.03;
    }

    return factor;
  }

  double _calculateRoadGradePercent({
    required LocationSampleModel? previousLocation,
    required LocationSampleModel currentLocation,
    required double incrementalDistanceKm,
  }) {
    final previousAltitude = previousLocation?.altitude;
    final currentAltitude = currentLocation.altitude;

    if (previousAltitude == null ||
        currentAltitude == null ||
        incrementalDistanceKm <= 0) {
      return 0;
    }

    final distanceMeters = incrementalDistanceKm * 1000;

    if (distanceMeters < 5) {
      return 0;
    }

    final altitudeDifference = currentAltitude - previousAltitude;

    return (altitudeDifference / distanceMeters) * 100;
  }
}