import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/data/repositories/fuel_price_repository.dart';
import 'package:ecopulse/data/repositories/fuel_station_repository.dart';
import 'package:ecopulse/services/ai/groq_ai_service.dart';
import 'package:ecopulse/services/fuel/fuel_price_sanity_service.dart';
import 'package:ecopulse/services/fuel/fuel_station_discovery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fuelMarketSyncServiceProvider = Provider<FuelMarketSyncService>((ref) {
  return FuelMarketSyncService(
    aiService: ref.read(groqAiServiceProvider),
    fuelPriceRepository: ref.read(fuelPriceRepositoryProvider),
    fuelStationRepository: ref.read(fuelStationRepositoryProvider),
    stationDiscoveryService: ref.read(fuelStationDiscoveryServiceProvider),
    sanityService: const FuelPriceSanityService(),
  );
});

class FuelMarketSyncService {
  final GroqAiService aiService;
  final FuelPriceRepository fuelPriceRepository;
  final FuelStationRepository fuelStationRepository;
  final FuelStationDiscoveryService stationDiscoveryService;
  final FuelPriceSanityService sanityService;

  const FuelMarketSyncService({
    required this.aiService,
    required this.fuelPriceRepository,
    required this.fuelStationRepository,
    required this.stationDiscoveryService,
    required this.sanityService,
  });

  Future<void> syncDailyMarketDataIfNeeded({
    bool forcePrices = false,
    bool forceStations = false,
  }) async {
    final city = Environment.defaultCity.trim().toUpperCase();
    final department = Environment.defaultDepartment.trim().toUpperCase();

    await _syncPricesSafely(
      city: city,
      department: department,
      forcePrices: forcePrices,
    );

    await _syncStationsFromOpenStreetMap(
      city: city,
      department: department,
      forceStations: forceStations,
    );
  }

  Future<void> _syncStationsFromOpenStreetMap({
    required String city,
    required String department,
    required bool forceStations,
  }) async {
    final hasStations = await fuelStationRepository.hasStationsForCity(
      city: city,
      department: department,
    );

    if (!forceStations && hasStations) {
      return;
    }

    final discoveredStations =
        await stationDiscoveryService.discoverStationsForPasto();

    if (discoveredStations.isEmpty) {
      return;
    }

    await fuelStationRepository.upsertDiscoveredStations(
      stations: discoveredStations,
    );
  }

  Future<void> _syncPricesSafely({
    required String city,
    required String department,
    required bool forcePrices,
  }) async {
    try {
      final shouldUpdatePrices = forcePrices ||
          !await fuelPriceRepository.hasTodayFuelPrices(
            city: city,
            department: department,
          );

      if (!shouldUpdatePrices) {
        return;
      }

      final prices = await _requestDailyPricesFromAi(
        city: city,
        department: department,
      );

      if (prices.isEmpty) {
        return;
      }

      await fuelPriceRepository.upsertFuelPrices(prices);

      final regularPrice = _findPriceByType(
        prices: prices,
        fuelType: 'GASOLINA_CORRIENTE',
      );

      final dieselPrice = _findPriceByType(
        prices: prices,
        fuelType: 'DIESEL',
      );

      await fuelStationRepository.updateCityStationPrices(
        city: city,
        department: department,
        regularPrice: regularPrice?.pricePerGallon,
        dieselPrice: dieselPrice?.pricePerGallon,
        priceSource: regularPrice?.source ?? dieselPrice?.source,
      );
    } catch (_) {
      // La app sigue funcionando con el último precio válido guardado.
    }
  }

  FuelPriceModel? _findPriceByType({
    required List<FuelPriceModel> prices,
    required String fuelType,
  }) {
    for (final price in prices) {
      if (price.normalizedFuelType == fuelType) {
        return price;
      }
    }

    return null;
  }

  Future<List<FuelPriceModel>> _requestDailyPricesFromAi({
    required String city,
    required String department,
  }) async {
    final today = DateTime.now();

    final response = await aiService.generateJsonObject(
      systemInstruction: '''
Eres un asistente técnico de EcoPulse especializado en normalización de datos de combustibles para Colombia.

Debes responder únicamente JSON válido.
No uses markdown.
No inventes precios.
Si no tienes una fuente oficial o verificable, no devuelvas precios.
El precio debe estar en pesos colombianos por galón.
Para Colombia, un precio normal de gasolina corriente o diésel por galón debe estar entre 5000 y 25000 COP.
Si una fuente muestra 13.487, eso significa 13487 COP.
Solo se necesitan gasolina corriente y diésel/ACPM.
''',
      userPrompt: '''
Normaliza el precio vigente de combustible para:
Ciudad: $city
Departamento: $department
País: COLOMBIA
Fecha de consulta: ${today.toIso8601String()}

Devuelve exactamente esta estructura JSON:

{
  "valid_from": "YYYY-MM-DD",
  "source": "fuente verificable",
  "is_official": true,
  "confidence_score": 0.0,
  "prices": [
    {
      "fuel_type": "GASOLINA_CORRIENTE",
      "price_per_gallon": 13487,
      "currency": "COP",
      "source": "fuente específica",
      "is_official": true,
      "confidence_score": 0.0
    },
    {
      "fuel_type": "DIESEL",
      "price_per_gallon": 10338,
      "currency": "COP",
      "source": "fuente específica",
      "is_official": true,
      "confidence_score": 0.0
    }
  ]
}
''',
    );

    final validFrom = DateTime.tryParse(
          response['valid_from']?.toString() ?? '',
        ) ??
        DateTime.now();

    final pricesRaw = response['prices'] as List<dynamic>? ?? [];
    final prices = <FuelPriceModel>[];

    for (final item in pricesRaw) {
      final map = item as Map<String, dynamic>;

      final fuelType = sanityService.normalizeFuelType(
        map['fuel_type']?.toString() ?? '',
      );

      final parsedPrice = sanityService.parseCopPerGallon(
        map['price_per_gallon'],
      );

      if (parsedPrice == null) {
        continue;
      }

      final isRealistic = sanityService.isRealisticColombianFuelPrice(
        fuelType: fuelType,
        price: parsedPrice,
      );

      if (!isRealistic) {
        continue;
      }

      prices.add(
        FuelPriceModel(
          id: '',
          city: city,
          department: department,
          country: 'COLOMBIA',
          fuelType: fuelType,
          pricePerGallon: parsedPrice,
          currency: map['currency']?.toString() ?? 'COP',
          source: map['source']?.toString() ??
              response['source']?.toString() ??
              'IA - fuente no especificada',
          isOfficial: map['is_official'] as bool? ??
              response['is_official'] as bool? ??
              false,
          validFrom: validFrom,
          updatedAt: DateTime.now(),
          syncDate: DateTime.now(),
          confidenceScore: sanityService.parseCopPerGallon(
                map['confidence_score'],
              ) ??
              sanityService.parseCopPerGallon(
                response['confidence_score'],
              ) ??
              0,
        ),
      );
    }

    final hasRegular = prices.any(
      (price) => price.normalizedFuelType == 'GASOLINA_CORRIENTE',
    );

    final hasDiesel = prices.any(
      (price) => price.normalizedFuelType == 'DIESEL',
    );

    if (!hasRegular || !hasDiesel) {
      throw Exception(
        'La IA no devolvió precios válidos dentro del rango permitido para Pasto.',
      );
    }

    return prices;
  }
}