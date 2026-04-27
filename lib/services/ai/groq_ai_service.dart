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
      final response = await _postChatCompletion(
        apiKey: apiKey,
        messages: requestMessages,
        temperature: 0.3,
        maxTokens: 700,
      );

      return _extractTextResponse(response);
    } catch (exception) {
      return 'No fue posible conectar con Groq. Verifica internet, la API key y el modelo configurado. Detalle: $exception';
    }
  }

  Future<Map<String, dynamic>> generateJsonObject({
    required String systemInstruction,
    required String userPrompt,
    int maxTokens = 1600,
  }) async {
    final apiKey = Environment.groqApiKey;

    if (apiKey.isEmpty) {
      throw Exception(
        'No se encontró GROQ_API_KEY. Configura la API key antes de sincronizar combustibles.',
      );
    }

    final response = await _postChatCompletion(
      apiKey: apiKey,
      messages: [
        {
          'role': 'system',
          'content': systemInstruction.trim(),
        },
        {
          'role': 'user',
          'content': userPrompt.trim(),
        },
      ],
      temperature: 0.0,
      maxTokens: maxTokens,
      responseFormatJson: true,
    );

    final content = _extractTextResponse(response);
    final cleaned = _cleanJsonContent(content);
    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('La IA no devolvió un objeto JSON válido.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _postChatCompletion({
    required String apiKey,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    bool responseFormatJson = false,
  }) async {
    final body = <String, dynamic>{
      'model': Environment.groqModel,
      'messages': messages,
      'temperature': temperature,
      'max_completion_tokens': maxTokens,
    };

    if (responseFormatJson) {
      body['response_format'] = {
        'type': 'json_object',
      };
    }

    final response = await http.post(
      Uri.parse(_chatCompletionsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Groq respondió con código ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractTextResponse(Map<String, dynamic> decoded) {
    final choices = decoded['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('La IA no devolvió opciones de respuesta.');
    }

    final firstChoice = choices.first as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString();

    if (content == null || content.trim().isEmpty) {
      throw Exception('La IA respondió sin contenido útil.');
    }

    return content.trim();
  }

  String _cleanJsonContent(String content) {
    var cleaned = content.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    return cleaned.trim();
  }
}