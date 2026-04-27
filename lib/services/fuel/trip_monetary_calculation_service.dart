import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/data/models/trip_monetary_result_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripMonetaryCalculationServiceProvider =
    Provider<TripMonetaryCalculationService>((ref) {
  return TripMonetaryCalculationService();
});

class TripMonetaryCalculationService {
  TripMonetaryResultModel calculate({
    required double estimatedGallons,
    required double distanceKm,
    required double estimatedFuelImpactGallons,
    required FuelPriceModel? fuelPrice,
  }) {
    if (fuelPrice == null || fuelPrice.pricePerGallon <= 0) {
      return TripMonetaryResultModel.empty();
    }

    final estimatedCostCop = estimatedGallons * fuelPrice.pricePerGallon;

    final costPerKmCop = distanceKm <= 0 ? null : estimatedCostCop / distanceKm;

    final estimatedSavingsCop =
        estimatedFuelImpactGallons <= 0
            ? 0.0
            : estimatedFuelImpactGallons * fuelPrice.pricePerGallon;

    final warnings = <String>[];

    if (!fuelPrice.isOfficial) {
      warnings.add(
        'El precio usado no está marcado como oficial. Verifica la fuente antes de usarlo en producción.',
      );
    }

    return TripMonetaryResultModel(
      fuelPricePerGallon: fuelPrice.pricePerGallon,
      fuelPriceSource: fuelPrice.source,
      fuelPriceIsOfficial: fuelPrice.isOfficial,
      estimatedCostCop: estimatedCostCop,
      costPerKmCop: costPerKmCop,
      estimatedSavingsCop: estimatedSavingsCop,
      warnings: warnings,
    );
  }
}