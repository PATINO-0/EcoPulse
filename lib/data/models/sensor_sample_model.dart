class SensorSampleModel {
  final double? accelerationX;
  final double? accelerationY;
  final double? accelerationZ;
  final double? userAccelerationX;
  final double? userAccelerationY;
  final double? userAccelerationZ;
  final double? gyroscopeX;
  final double? gyroscopeY;
  final double? gyroscopeZ;
  final double? magnetometerX;
  final double? magnetometerY;
  final double? magnetometerZ;
  final double? barometerPressure;
  final DateTime timestamp;
  final List<String> warnings;

  const SensorSampleModel({
    required this.timestamp,
    this.accelerationX,
    this.accelerationY,
    this.accelerationZ,
    this.userAccelerationX,
    this.userAccelerationY,
    this.userAccelerationZ,
    this.gyroscopeX,
    this.gyroscopeY,
    this.gyroscopeZ,
    this.magnetometerX,
    this.magnetometerY,
    this.magnetometerZ,
    this.barometerPressure,
    this.warnings = const [],
  });

  factory SensorSampleModel.empty() {
    return SensorSampleModel(
      timestamp: DateTime.now(),
    );
  }

  SensorSampleModel copyWith({
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
    double? userAccelerationX,
    double? userAccelerationY,
    double? userAccelerationZ,
    double? gyroscopeX,
    double? gyroscopeY,
    double? gyroscopeZ,
    double? magnetometerX,
    double? magnetometerY,
    double? magnetometerZ,
    double? barometerPressure,
    DateTime? timestamp,
    List<String>? warnings,
  }) {
    return SensorSampleModel(
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
      userAccelerationX: userAccelerationX ?? this.userAccelerationX,
      userAccelerationY: userAccelerationY ?? this.userAccelerationY,
      userAccelerationZ: userAccelerationZ ?? this.userAccelerationZ,
      gyroscopeX: gyroscopeX ?? this.gyroscopeX,
      gyroscopeY: gyroscopeY ?? this.gyroscopeY,
      gyroscopeZ: gyroscopeZ ?? this.gyroscopeZ,
      magnetometerX: magnetometerX ?? this.magnetometerX,
      magnetometerY: magnetometerY ?? this.magnetometerY,
      magnetometerZ: magnetometerZ ?? this.magnetometerZ,
      barometerPressure: barometerPressure ?? this.barometerPressure,
      timestamp: timestamp ?? this.timestamp,
      warnings: warnings ?? this.warnings,
    );
  }

  double get estimatedUserAccelerationMagnitude {
    final x = userAccelerationX ?? 0;
    final y = userAccelerationY ?? 0;
    final z = userAccelerationZ ?? 0;

    return (x.abs() + y.abs() + z.abs()) / 3;
  }

  bool get hasBarometer {
    return barometerPressure != null;
  }
}