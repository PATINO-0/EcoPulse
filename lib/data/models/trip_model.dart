class TripModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double distanceKm;
  final int durationSeconds;
  final int idleTimeSeconds;
  final int aggressiveAccelerationEvents;
  final int hardBrakingEvents;
  final int irregularDrivingEvents;
  final double estimatedFuelConsumedGallons;
  final double estimatedFuelConsumedLiters;
  final double? estimatedKmPerGallon;
  final double? estimatedLitersPer100Km;
  final double? fuelPricePerGallon;
  final String? fuelPriceSource;
  final bool fuelPriceIsOfficial;
  final double? estimatedCostCop;
  final double? costPerKmCop;
  final double? estimatedSavingsCop;
  final double? ecoScore;
  final String estimationMethod;

  const TripModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startedAt,
    required this.distanceKm,
    required this.durationSeconds,
    required this.idleTimeSeconds,
    required this.aggressiveAccelerationEvents,
    required this.hardBrakingEvents,
    required this.irregularDrivingEvents,
    required this.estimatedFuelConsumedGallons,
    required this.estimatedFuelConsumedLiters,
    required this.estimationMethod,
    required this.fuelPriceIsOfficial,
    this.vehicleId,
    this.endedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.estimatedKmPerGallon,
    this.estimatedLitersPer100Km,
    this.fuelPricePerGallon,
    this.fuelPriceSource,
    this.estimatedCostCop,
    this.costPerKmCop,
    this.estimatedSavingsCop,
    this.ecoScore,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      vehicleId: map['vehicle_id'] as String?,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['started_at'].toString()),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.tryParse(map['ended_at'].toString()),
      startLatitude: _toDouble(map['start_latitude']),
      startLongitude: _toDouble(map['start_longitude']),
      endLatitude: _toDouble(map['end_latitude']),
      endLongitude: _toDouble(map['end_longitude']),
      distanceKm: _toDouble(map['distance_km']) ?? 0,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      idleTimeSeconds: map['idle_time_seconds'] as int? ?? 0,
      aggressiveAccelerationEvents:
          map['aggressive_acceleration_events'] as int? ?? 0,
      hardBrakingEvents: map['hard_braking_events'] as int? ?? 0,
      irregularDrivingEvents: map['irregular_driving_events'] as int? ?? 0,
      estimatedFuelConsumedGallons:
          _toDouble(map['estimated_fuel_consumed_gallons']) ?? 0,
      estimatedFuelConsumedLiters:
          _toDouble(map['estimated_fuel_consumed_liters']) ?? 0,
      estimatedKmPerGallon: _toDouble(map['estimated_km_per_gallon']),
      estimatedLitersPer100Km: _toDouble(map['estimated_liters_per_100km']),
      fuelPricePerGallon: _toDouble(map['fuel_price_per_gallon']),
      fuelPriceSource: map['fuel_price_source'] as String?,
      fuelPriceIsOfficial: map['fuel_price_is_official'] as bool? ?? false,
      estimatedCostCop: _toDouble(map['estimated_cost_cop']),
      costPerKmCop: _toDouble(map['cost_per_km_cop']),
      estimatedSavingsCop: _toDouble(map['estimated_savings_cop']),
      ecoScore: _toDouble(map['eco_score']),
      estimationMethod:
          map['estimation_method'] as String? ?? 'physical_rules_fallback',
    );
  }

  int get totalEvents {
    return aggressiveAccelerationEvents +
        hardBrakingEvents +
        irregularDrivingEvents;
  }

  bool get isCompleted {
    return status == 'completed';
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