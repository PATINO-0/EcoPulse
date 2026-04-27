import 'package:ecopulse/services/fuel/fuel_price_sanity_service.dart';

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
  final DateTime? syncDate;
  final double confidenceScore;

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
    this.syncDate,
    this.confidenceScore = 0,
  });

  factory FuelPriceModel.fromMap(Map<String, dynamic> map) {
    const sanity = FuelPriceSanityService();

    return FuelPriceModel(
      id: map['id']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      country: map['country']?.toString() ?? 'COLOMBIA',
      fuelType: map['fuel_type']?.toString() ?? '',
      pricePerGallon: sanity.parseCopPerGallon(map['price_per_gallon']) ?? 0,
      currency: map['currency']?.toString() ?? 'COP',
      source: map['source']?.toString() ?? 'No disponible',
      isOfficial: map['is_official'] as bool? ?? false,
      validFrom: DateTime.parse(map['valid_from'].toString()),
      validUntil: map['valid_until'] == null
          ? null
          : DateTime.tryParse(map['valid_until'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      syncDate: map['sync_date'] == null
          ? null
          : DateTime.tryParse(map['sync_date'].toString()),
      confidenceScore: sanity.parseCopPerGallon(map['confidence_score']) ?? 0,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'city': city.trim().toUpperCase(),
      'department': department.trim().toUpperCase(),
      'country': country.trim().toUpperCase(),
      'fuel_type': normalizedFuelType,
      'price_per_gallon': pricePerGallon,
      'currency': currency.trim().toUpperCase(),
      'source': source,
      'is_official': isOfficial,
      'valid_from': _dateOnly(validFrom),
      'valid_until': validUntil == null ? null : _dateOnly(validUntil!),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'sync_date': _dateOnly(DateTime.now()),
      'confidence_score': confidenceScore,
    };
  }

  String get normalizedFuelType {
    const sanity = FuelPriceSanityService();

    return sanity.normalizeFuelType(fuelType);
  }

  String get displayFuelType {
    switch (normalizedFuelType) {
      case 'GASOLINA_CORRIENTE':
        return 'Gasolina corriente';
      case 'DIESEL':
        return 'Diésel / ACPM';
      default:
        return fuelType;
    }
  }

  bool get isUsable {
    const sanity = FuelPriceSanityService();

    return pricePerGallon > 0 &&
        currency.trim().toUpperCase() == 'COP' &&
        sanity.isRealisticColombianFuelPrice(
          fuelType: normalizedFuelType,
          price: pricePerGallon,
        );
  }

  bool get isSyncedToday {
    if (syncDate == null) {
      return false;
    }

    final now = DateTime.now();

    return syncDate!.year == now.year &&
        syncDate!.month == now.month &&
        syncDate!.day == now.day;
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}