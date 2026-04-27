class DrivingEventModel {
  final String? id;
  final String tripId;
  final String eventType;
  final String severity;
  final String message;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final double? accelerationMps2;
  final double? fuelImpactEstimate;
  final DateTime detectedAt;

  const DrivingEventModel({
    required this.tripId,
    required this.eventType,
    required this.severity,
    required this.message,
    required this.detectedAt,
    this.id,
    this.latitude,
    this.longitude,
    this.speedKmh,
    this.accelerationMps2,
    this.fuelImpactEstimate,
  });

  factory DrivingEventModel.fromMap(Map<String, dynamic> map) {
    return DrivingEventModel(
      id: map['id'] as String?,
      tripId: map['trip_id'] as String,
      eventType: map['event_type'] as String,
      severity: map['severity'] as String,
      message: map['message'] as String,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      speedKmh: _toDouble(map['speed_kmh']),
      accelerationMps2: _toDouble(map['acceleration_mps2']),
      fuelImpactEstimate: _toDouble(map['fuel_impact_estimate']),
      detectedAt: DateTime.parse(map['detected_at'].toString()),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'trip_id': tripId,
      'event_type': eventType,
      'severity': severity,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh,
      'acceleration_mps2': accelerationMps2,
      'fuel_impact_estimate': fuelImpactEstimate,
      'detected_at': detectedAt.toIso8601String(),
    };
  }

  bool get isAggressiveAcceleration {
    return eventType == 'aggressive_acceleration';
  }

  bool get isHardBraking {
    return eventType == 'hard_braking';
  }

  bool get isIrregularDriving {
    return eventType == 'irregular_speed_change' ||
        eventType == 'inefficient_slope_speed' ||
        eventType == 'idle_prolonged';
  }

  String get eventTypeLabel {
    switch (eventType) {
      case 'aggressive_acceleration':
        return 'Aceleración brusca';
      case 'hard_braking':
        return 'Frenada fuerte';
      case 'idle_prolonged':
        return 'Ralentí prolongado';
      case 'inefficient_slope_speed':
        return 'Pendiente ineficiente';
      case 'irregular_speed_change':
        return 'Cambio brusco de velocidad';
      default:
        return 'Evento de conducción';
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return 'No definida';
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}