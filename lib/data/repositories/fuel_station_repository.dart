import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fuelStationRepositoryProvider = Provider<FuelStationRepository>((ref) {
  return FuelStationRepository();
});

class FuelStationRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  Future<List<FuelStationModel>> getStationsForDefaultCity() async {
    return getStationsByCity(
      city: Environment.defaultCity,
      department: Environment.defaultDepartment,
    );
  }

  Future<List<FuelStationModel>> getStationsByCity({
    required String city,
    required String department,
  }) async {
    final data = await _client
        .from('fuel_stations')
        .select()
        .eq('city', city.trim().toUpperCase())
        .eq('department', department.trim().toUpperCase())
        .order('name', ascending: true);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(FuelStationModel.fromMap).toList();
  }

  Future<bool> hasStationsForCity({
    required String city,
    required String department,
  }) async {
    final data = await _client
        .from('fuel_stations')
        .select('id')
        .eq('city', city.trim().toUpperCase())
        .eq('department', department.trim().toUpperCase())
        .limit(1);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.isNotEmpty;
  }

  Future<int> upsertDiscoveredStations({
    required List<FuelStationModel> stations,
  }) async {
    if (stations.isEmpty) {
      return 0;
    }

    final payload = stations.map((station) => station.toUpsertMap()).toList();

    await _client.from('fuel_stations').upsert(
          payload,
          onConflict: 'data_provider,external_id',
        );

    return payload.length;
  }

  Future<void> updateCityStationPrices({
    required String city,
    required String department,
    required double? regularPrice,
    required double? dieselPrice,
    required String? priceSource,
  }) async {
    if (regularPrice == null && dieselPrice == null) {
      return;
    }

    final values = <String, dynamic>{
      'price_source': priceSource ?? 'Precio de referencia ciudad',
      'price_updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (regularPrice != null && regularPrice > 0) {
      values['price_regular'] = regularPrice;
    }

    if (dieselPrice != null && dieselPrice > 0) {
      values['price_diesel'] = dieselPrice;
    }

    await _client
        .from('fuel_stations')
        .update(values)
        .eq('city', city.trim().toUpperCase())
        .eq('department', department.trim().toUpperCase());
  }
}