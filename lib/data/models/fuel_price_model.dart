class FuelPriceModel {
  final String id;
  final String city;
  final String department;
  final String country;
  final String fuelType;
  final double pricePerGallon;
  final String currency;
  final String source;
  final bool isOfficial;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime? updatedAt;

  const FuelPriceModel({
    required this.id,
    required this.city,
    required this.department,
    required this.country,
    required this.fuelType,
    required this.pricePerGallon,
    required this.currency,
    required this.source,
    required this.isOfficial,
    required this.validFrom,
    this.validUntil,
    this.updatedAt,
  });

  factory FuelPriceModel.fromMap(Map<String, dynamic> map) {
    return FuelPriceModel(
      id: map['id'] as String,
      city: map['city'] as String,
      department: map['department'] as String,
      country: map['country'] as String? ?? 'COLOMBIA',
      fuelType: map['fuel_type'] as String,
      pricePerGallon: _toDouble(map['price_per_gallon']) ?? 0,
      currency: map['currency'] as String? ?? 'COP',
      source: map['source'] as String,
      isOfficial: map['is_official'] as bool? ?? false,
      validFrom: DateTime.parse(map['valid_from'].toString()),
      validUntil: map['valid_until'] == null
          ? null
          : DateTime.tryParse(map['valid_until'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
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