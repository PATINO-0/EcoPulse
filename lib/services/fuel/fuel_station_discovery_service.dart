import 'dart:convert';
import 'dart:math';

import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final fuelStationDiscoveryServiceProvider =
    Provider<FuelStationDiscoveryService>((ref) {
  return FuelStationDiscoveryService();
});

class FuelStationDiscoveryService {
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  // Área amplia de Pasto urbano y periurbano.
  // Se usa una caja amplia para evitar perder estaciones mal clasificadas por barrio.
  static const double _minLat = 1.1000;
  static const double _maxLat = 1.3100;
  static const double _minLon = -77.3900;
  static const double _maxLon = -77.1600;

  Future<List<FuelStationModel>> discoverStationsForPasto() async {
    final elements = await _fetchFuelElementsFromOverpass();

    final stations = elements
        .map(_mapOverpassElementToStation)
        .whereType<FuelStationModel>()
        .where((station) => station.hasValidCoordinates)
        .where((station) {
      return _isInsidePastoSearchArea(
        station.latitude,
        station.longitude,
      );
    }).toList();

    return _deduplicateStations(stations);
  }

  Future<List<Map<String, dynamic>>> _fetchFuelElementsFromOverpass() async {
    final query = _buildOverpassQuery();

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: {
                'data': query,
              },
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = decoded['elements'] as List<dynamic>? ?? [];

        return elements
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (_) {
        // Si un servidor Overpass falla, se intenta con el siguiente.
        continue;
      }
    }

    return [];
  }

  String _buildOverpassQuery() {
    return '''
[out:json][timeout:50];
(
  node["amenity"="fuel"]($_minLat,$_minLon,$_maxLat,$_maxLon);
  way["amenity"="fuel"]($_minLat,$_minLon,$_maxLat,$_maxLon);
  relation["amenity"="fuel"]($_minLat,$_minLon,$_maxLat,$_maxLon);
);
out center tags;
''';
  }

  FuelStationModel? _mapOverpassElementToStation(
    Map<String, dynamic> element,
  ) {
    final tags = element['tags'] is Map<String, dynamic>
        ? element['tags'] as Map<String, dynamic>
        : <String, dynamic>{};

    final type = element['type']?.toString() ?? 'unknown';
    final osmId = element['id']?.toString();

    if (osmId == null || osmId.trim().isEmpty) {
      return null;
    }

    final latitude = _toDouble(element['lat']) ??
        _toDouble(
          (element['center'] as Map<String, dynamic>?)?['lat'],
        );

    final longitude = _toDouble(element['lon']) ??
        _toDouble(
          (element['center'] as Map<String, dynamic>?)?['lon'],
        );

    if (latitude == null || longitude == null) {
      return null;
    }

    final name = _resolveStationName(
      tags: tags,
      osmId: osmId,
    );

    final brand = _resolveBrand(
      tags: tags,
      name: name,
    );

    return FuelStationModel(
      id: '',
      name: name,
      brand: brand,
      address: _buildAddress(tags),
      latitude: latitude,
      longitude: longitude,
      city: Environment.defaultCity.trim().toUpperCase(),
      department: Environment.defaultDepartment.trim().toUpperCase(),
      country: 'COLOMBIA',
      fuelTypes: _resolveFuelTypes(tags),
      priceRegular: null,
      priceExtra: null,
      priceDiesel: null,
      source: 'OpenStreetMap / Overpass API',
      isOfficial: false,
      updatedAt: DateTime.now(),
      priceSource: null,
      priceUpdatedAt: null,
      locationSource: 'OpenStreetMap / Overpass API',
      locationLocked: true,
      externalId: 'osm:$type:$osmId',
      dataProvider: 'openstreetmap',
      normalizedName: FuelStationModel.normalizeName(name),
      rawProviderPayload: element,
      lastDiscoveredAt: DateTime.now(),
    );
  }

  List<String> _resolveFuelTypes(Map<String, dynamic> tags) {
    final fuelTypes = <String>{};

    final hasPetrol = _tagIsYes(tags['fuel:octane_87']) ||
        _tagIsYes(tags['fuel:octane_90']) ||
        _tagIsYes(tags['fuel:octane_91']) ||
        _tagIsYes(tags['fuel:octane_92']) ||
        _tagIsYes(tags['fuel:octane_95']) ||
        _tagIsYes(tags['fuel:petrol']);

    final hasDiesel = _tagIsYes(tags['fuel:diesel']);

    if (hasPetrol) {
      fuelTypes.add('GASOLINA_CORRIENTE');
    }

    if (hasDiesel) {
      fuelTypes.add('DIESEL');
    }

    // En Colombia muchas estaciones OSM no tienen detalle de combustibles.
    // Para EcoPulse se asume que una estación urbana común puede vender corriente y diésel,
    // pero el precio se actualiza por referencia de ciudad, no desde OSM.
    if (fuelTypes.isEmpty) {
      fuelTypes.add('GASOLINA_CORRIENTE');
      fuelTypes.add('DIESEL');
    }

    return fuelTypes.toList();
  }

  String _resolveStationName({
    required Map<String, dynamic> tags,
    required String osmId,
  }) {
    return _firstNonEmpty([
      tags['name']?.toString(),
      tags['brand']?.toString(),
      tags['operator']?.toString(),
      'Estación de servicio OSM $osmId',
    ]);
  }

  String? _resolveBrand({
    required Map<String, dynamic> tags,
    required String name,
  }) {
    final directBrand = _firstNullableNonEmpty([
      tags['brand']?.toString(),
      tags['operator']?.toString(),
    ]);

    if (directBrand != null) {
      return directBrand;
    }

    final upperName = name.toUpperCase();

    if (upperName.contains('TERPEL')) {
      return 'Terpel';
    }

    if (upperName.contains('BIOMAX')) {
      return 'Biomax';
    }

    if (upperName.contains('TEXACO')) {
      return 'Texaco';
    }

    if (upperName.contains('PRIMAX')) {
      return 'Primax';
    }

    if (upperName.contains('ZEUSS')) {
      return 'Zeuss';
    }

    if (upperName.contains('PETROMIL')) {
      return 'Petromil';
    }

    return null;
  }

  String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      if (_hasText(tags['addr:street'])) tags['addr:street'].toString(),
      if (_hasText(tags['addr:housenumber']))
        tags['addr:housenumber'].toString(),
      if (_hasText(tags['addr:neighbourhood']))
        tags['addr:neighbourhood'].toString(),
      if (_hasText(tags['addr:suburb'])) tags['addr:suburb'].toString(),
    ];

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' ');
  }

  List<FuelStationModel> _deduplicateStations(
    List<FuelStationModel> candidates,
  ) {
    final result = <FuelStationModel>[];
    final seenExternalIds = <String>{};

    for (final station in candidates) {
      final externalId = station.externalId;

      if (externalId != null && seenExternalIds.contains(externalId)) {
        continue;
      }

      final isDuplicated = result.any((existing) {
        final distance = _distanceMeters(
          station.latitude,
          station.longitude,
          existing.latitude,
          existing.longitude,
        );

        final sameNormalizedName =
            FuelStationModel.normalizeName(station.name) ==
                FuelStationModel.normalizeName(existing.name);

        // Si están muy cerca y tienen nombre parecido, se consideran la misma estación.
        return distance <= 70 && sameNormalizedName;
      });

      if (isDuplicated) {
        continue;
      }

      if (externalId != null) {
        seenExternalIds.add(externalId);
      }

      result.add(station);
    }

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  bool _isInsidePastoSearchArea(double latitude, double longitude) {
    return latitude >= _minLat &&
        latitude <= _maxLat &&
        longitude >= _minLon &&
        longitude <= _maxLon;
  }

  bool _tagIsYes(dynamic value) {
    final text = value?.toString().trim().toLowerCase();

    return text == 'yes' || text == 'true' || text == '1';
  }

  bool _hasText(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Estación de servicio';
  }

  String? _firstNullableNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double? _toDouble(dynamic value) {
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