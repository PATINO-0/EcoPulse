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
  final String? priceSource;
  final DateTime? priceUpdatedAt;
  final String? locationSource;
  final bool locationLocked;
  final String? externalId;
  final String? dataProvider;
  final String? normalizedName;
  final Map<String, dynamic>? rawProviderPayload;
  final DateTime? lastDiscoveredAt;

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
    this.priceSource,
    this.priceUpdatedAt,
    this.locationSource,
    this.locationLocked = true,
    this.externalId,
    this.dataProvider,
    this.normalizedName,
    this.rawProviderPayload,
    this.lastDiscoveredAt,
  });

  factory FuelStationModel.fromMap(Map<String, dynamic> map) {
    return FuelStationModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Estación sin nombre',
      brand: map['brand']?.toString(),
      address: map['address']?.toString(),
      latitude: _toDouble(map['latitude']) ?? 0,
      longitude: _toDouble(map['longitude']) ?? 0,
      city: map['city']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      country: map['country']?.toString() ?? 'COLOMBIA',
      fuelTypes: _toStringList(map['fuel_types']),
      priceRegular: _toDouble(map['price_regular']),
      priceExtra: _toDouble(map['price_extra']),
      priceDiesel: _toDouble(map['price_diesel']),
      source: map['source']?.toString() ?? 'No disponible',
      isOfficial: map['is_official'] as bool? ?? false,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      priceSource: map['price_source']?.toString(),
      priceUpdatedAt: map['price_updated_at'] == null
          ? null
          : DateTime.tryParse(map['price_updated_at'].toString()),
      locationSource: map['location_source']?.toString(),
      locationLocked: map['location_locked'] as bool? ?? true,
      externalId: map['external_id']?.toString(),
      dataProvider: map['data_provider']?.toString(),
      normalizedName: map['normalized_name']?.toString(),
      rawProviderPayload: map['raw_provider_payload'] is Map<String, dynamic>
          ? map['raw_provider_payload'] as Map<String, dynamic>
          : null,
      lastDiscoveredAt: map['last_discovered_at'] == null
          ? null
          : DateTime.tryParse(map['last_discovered_at'].toString()),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'name': name.trim(),
      'brand': brand?.trim(),
      'address': address?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'city': city.trim().toUpperCase(),
      'department': department.trim().toUpperCase(),
      'country': country.trim().toUpperCase(),
      'fuel_types': fuelTypes,
      'price_regular': priceRegular,
      'price_extra': priceExtra,
      'price_diesel': priceDiesel,
      'source': source,
      'is_official': isOfficial,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'price_source': priceSource,
      'price_updated_at': priceUpdatedAt?.toUtc().toIso8601String(),
      'location_source': locationSource ?? source,
      'location_locked': locationLocked,
      'external_id': externalId,
      'data_provider': dataProvider,
      'normalized_name': normalizedName ?? normalizeName(name),
      'raw_provider_payload': rawProviderPayload,
      'last_discovered_at': DateTime.now().toUtc().toIso8601String(),
    };
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

  bool get hasValidCoordinates {
    return latitude != 0 && longitude != 0;
  }

  static String normalizeName(String value) {
    return value
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('ESTACION DE SERVICIO', '')
        .replaceAll('ESTACION SERVICIO', '')
        .replaceAll('EDS', '')
        .replaceAll('GASOLINERA', '')
        .trim();
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

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.').trim(),
    );
  }
}