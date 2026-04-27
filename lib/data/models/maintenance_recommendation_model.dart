class MaintenanceRecommendationModel {
  final String maintenanceType;
  final String description;
  final int suggestedIntervalDays;
  final String priority;

  const MaintenanceRecommendationModel({
    required this.maintenanceType,
    required this.description,
    required this.suggestedIntervalDays,
    required this.priority,
  });
}