import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fuelPriceRepositoryProvider = Provider<FuelPriceRepository>((ref) {
  return FuelPriceRepository();
});

class FuelPriceRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  Future<FuelPriceModel?> getLatestFuelPrice({
    required String fuelType,
    String? city,
    String? department,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final data = await _client
        .from('fuel_prices')
        .select()
        .eq('city', (city ?? Environment.defaultCity).trim().toUpperCase())
        .eq(
          'department',
          (department ?? Environment.defaultDepartment).trim().toUpperCase(),
        )
        .eq('fuel_type', fuelType.trim())
        .lte('valid_from', today)
        .order('valid_from', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return FuelPriceModel.fromMap(data);
  }

  Future<List<FuelPriceModel>> getFuelPricesForDefaultCity() async {
    final data = await _client
        .from('fuel_prices')
        .select()
        .eq('city', Environment.defaultCity)
        .eq('department', Environment.defaultDepartment)
        .order('valid_from', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(FuelPriceModel.fromMap).toList();
  }
}