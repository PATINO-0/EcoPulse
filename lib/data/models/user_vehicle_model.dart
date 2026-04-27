class UserVehicleModel {
  final String id;
  final String userId;
  final String? catalogVehicleId;
  final String brand;
  final String model;
  final String? version;
  final int year;
  final String? engine;
  final String fuelType;
  final double? powerHp;
  final double? weightKg;
  final String? transmission;
  final double? estimatedCityKmPerGallon;
  final double? estimatedHighwayKmPerGallon;
  final bool isSelected;
  final bool isManual;
  final String? source;

  const UserVehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.isSelected,
    required this.isManual,
    this.catalogVehicleId,
    this.version,
    this.engine,
    this.powerHp,
    this.weightKg,
    this.transmission,
    this.estimatedCityKmPerGallon,
    this.estimatedHighwayKmPerGallon,
    this.source,
  });

  factory UserVehicleModel.fromMap(Map<String, dynamic> map) {
    return UserVehicleModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      catalogVehicleId: map['catalog_vehicle_id'] as String?,
      brand: map['brand'] as String,
      model: map['model'] as String,
      version: map['version'] as String?,
      year: map['year'] as int,
      engine: map['engine'] as String?,
      fuelType: map['fuel_type'] as String,
      powerHp: _toDouble(map['power_hp']),
      weightKg: _toDouble(map['weight_kg']),
      transmission: map['transmission'] as String?,
      estimatedCityKmPerGallon: _toDouble(
        map['estimated_city_km_per_gallon'],
      ),
      estimatedHighwayKmPerGallon: _toDouble(
        map['estimated_highway_km_per_gallon'],
      ),
      isSelected: map['is_selected'] as bool? ?? false,
      isManual: map['is_manual'] as bool? ?? false,
      source: map['source'] as String?,
    );
  }

  String get displayName {
    final versionText = version == null || version!.isEmpty ? '' : ' $version';
    return '$brand $model$versionText $year';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}