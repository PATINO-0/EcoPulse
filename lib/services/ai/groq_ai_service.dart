import 'dart:convert';

import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/ai_chat_message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final groqAiServiceProvider = Provider<GroqAiService>((ref) {
  return GroqAiService();
});

class GroqAiService {
  static const String _chatCompletionsUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> generateResponse({
    required List<AiChatMessageModel> messages,
    String? systemInstruction,
  }) async {
    final apiKey = Environment.groqApiKey;

    if (apiKey.isEmpty) {
      return 'No se encontró la API Key de Groq. Configura GROQ_API_KEY en el archivo .env para activar el asistente.';
    }

    final requestMessages = <Map<String, String>>[
      if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
        {
          'role': 'system',
          'content': systemInstruction.trim(),
        },
      ...messages.map((message) => message.toGroqMessage()),
    ];

    try {
      final response = await http.post(
        Uri.parse(_chatCompletionsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': Environment.groqModel,
          'messages': requestMessages,
          'temperature': 0.3,
          'max_completion_tokens': 700,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'No fue posible consultar el asistente IA. Código: ${response.statusCode}. Respuesta: ${response.body}';
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        return 'La IA no devolvió una respuesta válida.';
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      final content = message?['content']?.toString();

      if (content == null || content.trim().isEmpty) {
        return 'La IA respondió sin contenido útil.';
      }

      return content.trim();
    } catch (exception) {
      return 'No fue posible conectar con Groq. Verifica internet, la API key y el modelo configurado. Detalle: $exception';
    }
  }
}