import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/services/fuel/fuel_estimation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuelEstimationService', () {
    test('should estimate incremental fuel using vehicle efficiency', () {
      final service = FuelEstimationService();

      final previousLocation = LocationSampleModel(
        latitude: 1.21361,
        longitude: -77.28111,
        altitude: 2500,
        speedMps: 8,
        speedKmh: 28.8,
        heading: 0,
        accuracy: 10,
        timestamp: DateTime(2026, 1, 1, 10, 0, 0),
      );

      final currentLocation = LocationSampleModel(
        latitude: 1.21461,
        longitude: -77.28211,
        altitude: 2505,
        speedMps: 10,
        speedKmh: 36,
        heading: 0,
        accuracy: 10,
        timestamp: DateTime(2026, 1, 1, 10, 0, 10),
      );

      const vehicle = UserVehicleModel(
        id: 'vehicle-test',
        userId: 'user-test',
        brand: 'Marca Demo',
        model: 'Sedán',
        year: 2020,
        fuelType: 'Gasolina corriente',
        isSelected: true,
        isManual: true,
        estimatedCityKmPerGallon: 35,
      );

      final result = service.estimateIncrement(
        previousTotalGallons: 0,
        totalDistanceKm: 1,
        incrementalDistanceKm: 1,
        previousLocation: previousLocation,
        currentLocation: currentLocation,
        accelerationMps2: 0.5,
        idleTimeSeconds: 0,
        vehicle: vehicle,
      );

      expect(result.incrementalGallons, greaterThan(0));
      expect(result.totalGallons, greaterThan(0));
      expect(result.totalLiters, greaterThan(0));
      expect(result.estimatedKmPerGallon, greaterThan(0));
    });

    test('should use fallback efficiency when vehicle has no efficiency data', () {
      final service = FuelEstimationService();

      final currentLocation = LocationSampleModel(
        latitude: 1.21361,
        longitude: -77.28111,
        altitude: 2500,
        speedMps: 8,
        speedKmh: 28.8,
        heading: 0,
        accuracy: 10,
        timestamp: DateTime.now(),
      );

      final result = service.estimateIncrement(
        previousTotalGallons: 0,
        totalDistanceKm: 1,
        incrementalDistanceKm: 1,
        previousLocation: null,
        currentLocation: currentLocation,
        accelerationMps2: 0,
        idleTimeSeconds: 0,
        vehicle: null,
      );

      expect(result.totalGallons, greaterThan(0));
      expect(result.warnings, isNotEmpty);
    });
  });
}