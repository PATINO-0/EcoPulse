import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/services/fuel/trip_monetary_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripMonetaryCalculationService', () {
    test('should calculate estimated cost and cost per kilometer', () {
      final service = TripMonetaryCalculationService();

      final result = service.calculate(
        estimatedGallons: 0.36,
        distanceKm: 12.4,
        estimatedFuelImpactGallons: 0.02,
        fuelPrice: FuelPriceModel(
          id: 'fuel-price-test',
          city: 'PASTO',
          department: 'NARIÑO',
          country: 'COLOMBIA',
          fuelType: 'Gasolina corriente',
          pricePerGallon: 13400,
          currency: 'COP',
          source: 'TEST_NO_OFICIAL',
          isOfficial: false,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      expect(result.estimatedCostCop, closeTo(4824, 0.1));
      expect(result.costPerKmCop, closeTo(389.03, 0.1));
      expect(result.estimatedSavingsCop, closeTo(268, 0.1));
      expect(result.warnings, isNotEmpty);
    });

    test('should return empty result when fuel price is missing', () {
      final service = TripMonetaryCalculationService();

      final result = service.calculate(
        estimatedGallons: 0.36,
        distanceKm: 12.4,
        estimatedFuelImpactGallons: 0.02,
        fuelPrice: null,
      );

      expect(result.estimatedCostCop, isNull);
      expect(result.costPerKmCop, isNull);
      expect(result.warnings, isNotEmpty);
    });
  });
}