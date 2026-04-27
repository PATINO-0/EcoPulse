class VehicleCatalogModel {
  final String id;
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
  final String source;
  final bool isExample;

  const VehicleCatalogModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.source,
    required this.isExample,
    this.version,
    this.engine,
    this.powerHp,
    this.weightKg,
    this.transmission,
    this.estimatedCityKmPerGallon,
    this.estimatedHighwayKmPerGallon,
  });

  factory VehicleCatalogModel.fromMap(Map<String, dynamic> map) {
    return VehicleCatalogModel(
      id: map['id'] as String,
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
      source: map['source'] as String,
      isExample: map['is_example'] as bool? ?? false,
    );
  }

  String get displayName {
    final versionText = version == null || version!.isEmpty ? '' : ' $version';
    return '$brand $model$versionText $year';
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = [
      brand,
      model,
      version ?? '',
      year.toString(),
      engine ?? '',
      fuelType,
      transmission ?? '',
    ].join(' ').toLowerCase();

    return searchableText.contains(normalizedQuery);
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