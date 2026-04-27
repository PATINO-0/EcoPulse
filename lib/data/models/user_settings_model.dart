class UserSettingsModel {
  final String id;
  final String userId;
  final bool visualAlertsEnabled;
  final bool voiceAlertsEnabled;
  final bool realtimeFeedbackEnabled;
  final String consumptionUnit;
  final String defaultCity;
  final String defaultDepartment;
  final String defaultCountry;

  const UserSettingsModel({
    required this.id,
    required this.userId,
    required this.visualAlertsEnabled,
    required this.voiceAlertsEnabled,
    required this.realtimeFeedbackEnabled,
    required this.consumptionUnit,
    required this.defaultCity,
    required this.defaultDepartment,
    required this.defaultCountry,
  });

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      visualAlertsEnabled: map['visual_alerts_enabled'] as bool? ?? true,
      voiceAlertsEnabled: map['voice_alerts_enabled'] as bool? ?? true,
      realtimeFeedbackEnabled:
          map['realtime_feedback_enabled'] as bool? ?? true,
      consumptionUnit:
          map['consumption_unit'] as String? ?? 'km_per_gallon',
      defaultCity: map['default_city'] as String? ?? 'PASTO',
      defaultDepartment: map['default_department'] as String? ?? 'NARIÑO',
      defaultCountry: map['default_country'] as String? ?? 'COLOMBIA',
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'visual_alerts_enabled': visualAlertsEnabled,
      'voice_alerts_enabled': voiceAlertsEnabled,
      'realtime_feedback_enabled': realtimeFeedbackEnabled,
      'consumption_unit': consumptionUnit,
      'default_city': defaultCity,
      'default_department': defaultDepartment,
      'default_country': defaultCountry,
    };
  }

  UserSettingsModel copyWith({
    bool? visualAlertsEnabled,
    bool? voiceAlertsEnabled,
    bool? realtimeFeedbackEnabled,
    String? consumptionUnit,
    String? defaultCity,
    String? defaultDepartment,
    String? defaultCountry,
  }) {
    return UserSettingsModel(
      id: id,
      userId: userId,
      visualAlertsEnabled:
          visualAlertsEnabled ?? this.visualAlertsEnabled,
      voiceAlertsEnabled:
          voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      realtimeFeedbackEnabled:
          realtimeFeedbackEnabled ?? this.realtimeFeedbackEnabled,
      consumptionUnit: consumptionUnit ?? this.consumptionUnit,
      defaultCity: defaultCity ?? this.defaultCity,
      defaultDepartment: defaultDepartment ?? this.defaultDepartment,
      defaultCountry: defaultCountry ?? this.defaultCountry,
    );
  }
}