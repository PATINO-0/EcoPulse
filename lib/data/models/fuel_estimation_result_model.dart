class FuelEstimationResultModel {
  final double incrementalGallons;
  final double totalGallons;
  final double totalLiters;
  final double estimatedKmPerGallon;
  final double estimatedLitersPer100Km;
  final double roadGradePercent;
  final String estimationMethod;
  final List<String> warnings;

  const FuelEstimationResultModel({
    required this.incrementalGallons,
    required this.totalGallons,
    required this.totalLiters,
    required this.estimatedKmPerGallon,
    required this.estimatedLitersPer100Km,
    required this.roadGradePercent,
    required this.estimationMethod,
    required this.warnings,
  });

  factory FuelEstimationResultModel.initial() {
    return const FuelEstimationResultModel(
      incrementalGallons: 0,
      totalGallons: 0,
      totalLiters: 0,
      estimatedKmPerGallon: 0,
      estimatedLitersPer100Km: 0,
      roadGradePercent: 0,
      estimationMethod: 'physical_rules_fallback',
      warnings: [],
    );
  }
}