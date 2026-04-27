import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/ai_chat_message_model.dart';
import 'package:ecopulse/data/repositories/ai_conversation_repository.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/services/ai/vehicle_assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() {
    return _AiAssistantScreenState();
  }
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<AiChatMessageModel> _messages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      AiChatMessageModel(
        role: 'assistant',
        content:
            'Hola, soy el asistente de EcoPulse. Puedo ayudarte con conducción eficiente, mantenimiento preventivo y explicación de métricas del vehículo.',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _messageController.clear();
      _messages.add(
        AiChatMessageModel(
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      );
    });

    try {
      final selectedVehicle =
          await ref.read(vehicleRepositoryProvider).getSelectedVehicle();

      final response = await ref.read(vehicleAssistantServiceProvider).ask(
            question: text,
            vehicle: selectedVehicle,
            history: _messages,
          );

      await ref.read(aiConversationRepositoryProvider).saveConversation(
            userMessage: text,
            assistantResponse: response,
            vehicleId: selectedVehicle?.id,
            modelName: Environment.groqModel,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AiChatMessageModel(
            role: 'assistant',
            content: response,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AiChatMessageModel(
            role: 'assistant',
            content:
                'No fue posible responder en este momento. Detalle: $exception',
            createdAt: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMessageBubble(AiChatMessageModel message) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    final color = message.isUser
        ? const Color(0xFF1F8A4C)
        : const Color(0xFFE8F5E9);

    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(
          maxWidth: 320,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: textColor,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  void _useSuggestion(String text) {
    _messageController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'El asistente no reemplaza una revisión mecánica profesional. Si no hay datos suficientes, debe responder con advertencia.',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _SuggestionChip(
                    text: '¿Cómo puedo reducir el consumo?',
                    onTap: _useSuggestion,
                  ),
                  _SuggestionChip(
                    text: '¿Qué mantenimiento debería revisar?',
                    onTap: _useSuggestion,
                  ),
                  _SuggestionChip(
                    text: 'Explícame mi eco score',
                    onTap: _useSuggestion,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Escribe tu pregunta',
                        hintText: 'Ejemplo: ¿cómo ahorro combustible?',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTap;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          onTap(text);
        },
      ),
    );
  }
}