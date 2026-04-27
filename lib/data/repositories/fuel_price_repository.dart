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
    final today = _dateOnly(DateTime.now());

    final data = await _client
        .from('fuel_prices')
        .select()
        .eq('city', (city ?? Environment.defaultCity).trim().toUpperCase())
        .eq(
          'department',
          (department ?? Environment.defaultDepartment).trim().toUpperCase(),
        )
        .eq('fuel_type', _normalizeFuelType(fuelType))
        .lte('valid_from', today)
        .order('valid_from', ascending: false)
        .order('updated_at', ascending: false)
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
        .eq('city', Environment.defaultCity.trim().toUpperCase())
        .eq('department', Environment.defaultDepartment.trim().toUpperCase())
        .order('valid_from', ascending: false)
        .order('fuel_type', ascending: true);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(FuelPriceModel.fromMap).toList();
  }

  Future<bool> hasTodayFuelPrices({
    required String city,
    required String department,
  }) async {
    final today = _dateOnly(DateTime.now());

    final data = await _client
        .from('fuel_prices')
        .select('id, fuel_type, sync_date')
        .eq('city', city.trim().toUpperCase())
        .eq('department', department.trim().toUpperCase())
        .eq('sync_date', today)
        .inFilter('fuel_type', ['GASOLINA_CORRIENTE', 'DIESEL']);

    final rows = List<Map<String, dynamic>>.from(data);
    final types = rows.map((row) => row['fuel_type']?.toString()).toSet();

    return types.contains('GASOLINA_CORRIENTE') && types.contains('DIESEL');
  }

  Future<void> upsertFuelPrices(List<FuelPriceModel> prices) async {
    if (prices.isEmpty) {
      return;
    }

    final payload = prices.map((price) => price.toUpsertMap()).toList();

    await _client.from('fuel_prices').upsert(
          payload,
          onConflict: 'city,department,fuel_type,valid_from',
        );
  }

  static String _normalizeFuelType(String fuelType) {
    final value = fuelType.trim().toUpperCase();

    if (value.contains('DIESEL') || value.contains('DIÉSEL') || value.contains('ACPM')) {
      return 'DIESEL';
    }

    if (value.contains('CORRIENTE') || value.contains('GASOLINA')) {
      return 'GASOLINA_CORRIENTE';
    }

    return value;
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}