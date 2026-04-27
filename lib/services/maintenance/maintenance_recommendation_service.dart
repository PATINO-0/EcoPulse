import 'package:ecopulse/data/models/maintenance_recommendation_model.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final maintenanceRecommendationServiceProvider =
    Provider<MaintenanceRecommendationService>((ref) {
  return MaintenanceRecommendationService();
});

class MaintenanceRecommendationService {
  List<MaintenanceRecommendationModel> buildDefaultRecommendations({
    required UserVehicleModel? vehicle,
  }) {
    return const [
      MaintenanceRecommendationModel(
        maintenanceType: 'Presión de llantas',
        description:
            'Revisa la presión de las llantas. Una presión incorrecta puede aumentar el consumo de combustible.',
        suggestedIntervalDays: 15,
        priority: 'high',
      ),
      MaintenanceRecommendationModel(
        maintenanceType: 'Cambio de aceite',
        description:
            'Programa el cambio de aceite según el manual del vehículo o recomendación del taller.',
        suggestedIntervalDays: 180,
        priority: 'high',
      ),
      MaintenanceRecommendationModel(
        maintenanceType: 'Filtro de aire',
        description:
            'Un filtro de aire sucio puede afectar la eficiencia del motor.',
        suggestedIntervalDays: 120,
        priority: 'medium',
      ),
      MaintenanceRecommendationModel(
        maintenanceType: 'Alineación y balanceo',
        description:
            'Una mala alineación puede generar mayor resistencia al avance y desgaste irregular.',
        suggestedIntervalDays: 180,
        priority: 'medium',
      ),
      MaintenanceRecommendationModel(
        maintenanceType: 'Sistema de frenos',
        description:
            'Revisa el sistema de frenos si percibes vibraciones, ruidos o pérdida de respuesta.',
        suggestedIntervalDays: 180,
        priority: 'high',
      ),
      MaintenanceRecommendationModel(
        maintenanceType: 'Bujías e inyección',
        description:
            'Revisa bujías e inyección si notas pérdida de potencia, consumo elevado o fallos al acelerar.',
        suggestedIntervalDays: 365,
        priority: 'medium',
      ),
    ];
  }
}