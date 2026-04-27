class AiConversationModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String? title;
  final String userMessage;
  final String assistantResponse;
  final String? modelName;
  final DateTime createdAt;

  const AiConversationModel({
    required this.id,
    required this.userId,
    required this.userMessage,
    required this.assistantResponse,
    required this.createdAt,
    this.vehicleId,
    this.title,
    this.modelName,
  });

  factory AiConversationModel.fromMap(Map<String, dynamic> map) {
    return AiConversationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      vehicleId: map['vehicle_id'] as String?,
      title: map['title'] as String?,
      userMessage: map['user_message'] as String,
      assistantResponse: map['assistant_response'] as String,
      modelName: map['model_name'] as String?,
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}