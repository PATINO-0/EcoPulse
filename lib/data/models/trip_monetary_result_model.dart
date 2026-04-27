class TripMonetaryResultModel {
  final double? fuelPricePerGallon;
  final String? fuelPriceSource;
  final bool fuelPriceIsOfficial;
  final double? estimatedCostCop;
  final double? costPerKmCop;
  final double? estimatedSavingsCop;
  final List<String> warnings;

  const TripMonetaryResultModel({
    required this.fuelPricePerGallon,
    required this.fuelPriceSource,
    required this.fuelPriceIsOfficial,
    required this.estimatedCostCop,
    required this.costPerKmCop,
    required this.estimatedSavingsCop,
    required this.warnings,
  });

  factory TripMonetaryResultModel.empty() {
    return const TripMonetaryResultModel(
      fuelPricePerGallon: null,
      fuelPriceSource: null,
      fuelPriceIsOfficial: false,
      estimatedCostCop: null,
      costPerKmCop: null,
      estimatedSavingsCop: null,
      warnings: [
        'No se encontró precio de combustible para calcular el costo monetario.',
      ],
    );
  }
}