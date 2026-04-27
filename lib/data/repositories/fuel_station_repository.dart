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
}