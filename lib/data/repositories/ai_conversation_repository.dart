import 'package:ecopulse/data/models/ai_conversation_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final aiConversationRepositoryProvider =
    Provider<AiConversationRepository>((ref) {
  return AiConversationRepository();
});

class AiConversationRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    return user.id;
  }

  Future<void> saveConversation({
    required String userMessage,
    required String assistantResponse,
    required String? vehicleId,
    required String? modelName,
  }) async {
    await _client.from('ai_conversations').insert({
      'user_id': _currentUserId,
      'vehicle_id': vehicleId,
      'title': 'Asistente EcoPulse',
      'user_message': userMessage,
      'assistant_response': assistantResponse,
      'model_name': modelName,
    });
  }

  Future<List<AiConversationModel>> getRecentConversations() async {
    final data = await _client
        .from('ai_conversations')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false)
        .limit(30);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(AiConversationModel.fromMap).toList();
  }
}