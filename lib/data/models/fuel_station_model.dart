class FuelStationModel {
  final String id;
  final String name;
  final String? brand;
  final String? address;
  final double latitude;
  final double longitude;
  final String city;
  final String department;
  final String country;
  final List<String> fuelTypes;
  final double? priceRegular;
  final double? priceExtra;
  final double? priceDiesel;
  final String source;
  final bool isOfficial;
  final DateTime? updatedAt;

  const FuelStationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.department,
    required this.country,
    required this.fuelTypes,
    required this.source,
    required this.isOfficial,
    this.brand,
    this.address,
    this.priceRegular,
    this.priceExtra,
    this.priceDiesel,
    this.updatedAt,
  });

  factory FuelStationModel.fromMap(Map<String, dynamic> map) {
    return FuelStationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      address: map['address'] as String?,
      latitude: _toDouble(map['latitude']) ?? 0,
      longitude: _toDouble(map['longitude']) ?? 0,
      city: map['city'] as String,
      department: map['department'] as String,
      country: map['country'] as String? ?? 'COLOMBIA',
      fuelTypes: _toStringList(map['fuel_types']),
      priceRegular: _toDouble(map['price_regular']),
      priceExtra: _toDouble(map['price_extra']),
      priceDiesel: _toDouble(map['price_diesel']),
      source: map['source'] as String,
      isOfficial: map['is_official'] as bool? ?? false,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  String get displayName {
    if (brand == null || brand!.trim().isEmpty) {
      return name;
    }

    return '$name • $brand';
  }

  bool get hasAnyPrice {
    return priceRegular != null || priceExtra != null || priceDiesel != null;
  }

  String get fuelTypesText {
    if (fuelTypes.isEmpty) {
      return 'No disponible';
    }

    return fuelTypes.join(', ');
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}