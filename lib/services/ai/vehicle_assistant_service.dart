import 'package:ecopulse/data/models/ai_chat_message_model.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/services/ai/groq_ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vehicleAssistantServiceProvider =
    Provider<VehicleAssistantService>((ref) {
  return VehicleAssistantService(
    groqAiService: ref.read(groqAiServiceProvider),
  );
});

class VehicleAssistantService {
  final GroqAiService groqAiService;

  const VehicleAssistantService({
    required this.groqAiService,
  });

  Future<String> ask({
    required String question,
    required UserVehicleModel? vehicle,
    required List<AiChatMessageModel> history,
  }) async {
    final systemInstruction = _buildSystemInstruction(vehicle);

    final messages = [
      ...history.take(8),
      AiChatMessageModel(
        role: 'user',
        content: question,
        createdAt: DateTime.now(),
      ),
    ];

    return groqAiService.generateResponse(
      messages: messages,
      systemInstruction: systemInstruction,
    );
  }

  String _buildSystemInstruction(UserVehicleModel? vehicle) {
    final vehicleContext = vehicle == null
        ? 'El usuario aún no tiene un vehículo seleccionado.'
        : '''
Vehículo seleccionado:
- Marca: ${vehicle.brand}
- Modelo: ${vehicle.model}
- Versión: ${vehicle.version ?? 'No disponible'}
- Año: ${vehicle.year}
- Motor: ${vehicle.engine ?? 'No disponible'}
- Combustible: ${vehicle.fuelType}
- Potencia HP: ${vehicle.powerHp?.toStringAsFixed(1) ?? 'No disponible'}
- Peso KG: ${vehicle.weightKg?.toStringAsFixed(1) ?? 'No disponible'}
- Transmisión: ${vehicle.transmission ?? 'No disponible'}
- Rendimiento ciudad km/galón: ${vehicle.estimatedCityKmPerGallon?.toStringAsFixed(2) ?? 'No disponible'}
- Rendimiento carretera km/galón: ${vehicle.estimatedHighwayKmPerGallon?.toStringAsFixed(2) ?? 'No disponible'}
''';

    return '''
Eres el asistente técnico de EcoPulse.

Responde siempre en español.
Ayuda con conducción eficiente, mantenimiento preventivo, explicación de métricas y ahorro de combustible.
No inventes datos críticos del vehículo.
Si no tienes información suficiente, dilo claramente.
No des instrucciones peligrosas de reparación. Recomienda acudir a un técnico certificado cuando corresponda.
No prometas diagnósticos exactos sin revisión mecánica real.
No afirmes precios oficiales si la fuente no está marcada como oficial.

$vehicleContext
''';
  }
}