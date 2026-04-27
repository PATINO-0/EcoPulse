class AiChatMessageModel {
  final String role;
  final String content;
  final DateTime createdAt;

  const AiChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser {
    return role == 'user';
  }

  bool get isAssistant {
    return role == 'assistant';
  }

  Map<String, String> toGroqMessage() {
    return {
      'role': role,
      'content': content,
    };
  }
}