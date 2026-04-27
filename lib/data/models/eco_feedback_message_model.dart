class EcoFeedbackMessageModel {
  final String message;
  final String severity;
  final DateTime createdAt;

  const EcoFeedbackMessageModel({
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  factory EcoFeedbackMessageModel.neutral() {
    return EcoFeedbackMessageModel(
      message: 'Mantén una conducción suave y constante para mejorar el consumo.',
      severity: 'low',
      createdAt: DateTime.now(),
    );
  }
}