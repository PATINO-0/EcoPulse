import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/data/models/vehicle_catalog_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

class VehicleRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    return user.id;
  }

  Future<List<VehicleCatalogModel>> searchCatalog({
    String query = '',
  }) async {
    final data = await _client
        .from('vehicles_catalog')
        .select()
        .order('brand', ascending: true)
        .limit(500);

    final rows = List<Map<String, dynamic>>.from(data);

    final vehicles = rows.map(VehicleCatalogModel.fromMap).toList();

    return vehicles.where((vehicle) {
      return vehicle.matchesQuery(query);
    }).toList();
  }

  Future<List<UserVehicleModel>> getUserVehicles() async {
    final data = await _client
        .from('user_vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(UserVehicleModel.fromMap).toList();
  }

  Future<UserVehicleModel?> getSelectedVehicle() async {
    final data = await _client
        .from('user_vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .eq('is_selected', true)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return UserVehicleModel.fromMap(data);
  }

  Future<void> selectCatalogVehicle({
    required VehicleCatalogModel vehicle,
  }) async {
    final userId = _currentUserId;

    await _clearSelectedVehicle(userId);

    final existingVehicle = await _client
        .from('user_vehicles')
        .select('id')
        .eq('user_id', userId)
        .eq('catalog_vehicle_id', vehicle.id)
        .maybeSingle();

    if (existingVehicle != null) {
      await _client
          .from('user_vehicles')
          .update({
            'is_selected': true,
          })
          .eq('id', existingVehicle['id'] as String)
          .eq('user_id', userId);

      return;
    }

    await _client.from('user_vehicles').insert({
      'user_id': userId,
      'catalog_vehicle_id': vehicle.id,
      'brand': vehicle.brand,
      'model': vehicle.model,
      'version': vehicle.version,
      'year': vehicle.year,
      'engine': vehicle.engine,
      'fuel_type': vehicle.fuelType,
      'power_hp': vehicle.powerHp,
      'weight_kg': vehicle.weightKg,
      'transmission': vehicle.transmission,
      'estimated_city_km_per_gallon': vehicle.estimatedCityKmPerGallon,
      'estimated_highway_km_per_gallon': vehicle.estimatedHighwayKmPerGallon,
      'is_selected': true,
      'is_manual': false,
      'source': vehicle.source,
    });
  }

  Future<void> createManualVehicle({
    required String brand,
    required String model,
    String? version,
    required int year,
    String? engine,
    required String fuelType,
    double? powerHp,
    double? weightKg,
    String? transmission,
    double? estimatedCityKmPerGallon,
    double? estimatedHighwayKmPerGallon,
  }) async {
    final userId = _currentUserId;

    await _clearSelectedVehicle(userId);

    await _client.from('user_vehicles').insert({
      'user_id': userId,
      'catalog_vehicle_id': null,
      'brand': brand.trim(),
      'model': model.trim(),
      'version': _emptyToNull(version),
      'year': year,
      'engine': _emptyToNull(engine),
      'fuel_type': fuelType.trim(),
      'power_hp': powerHp,
      'weight_kg': weightKg,
      'transmission': _emptyToNull(transmission),
      'estimated_city_km_per_gallon': estimatedCityKmPerGallon,
      'estimated_highway_km_per_gallon': estimatedHighwayKmPerGallon,
      'is_selected': true,
      'is_manual': true,
      'source': 'USER_MANUAL_ENTRY',
    });
  }

  Future<void> setSelectedVehicle({
    required String userVehicleId,
  }) async {
    final userId = _currentUserId;

    await _clearSelectedVehicle(userId);

    await _client
        .from('user_vehicles')
        .update({
          'is_selected': true,
        })
        .eq('id', userVehicleId)
        .eq('user_id', userId);
  }

  Future<void> _clearSelectedVehicle(String userId) async {
    await _client
        .from('user_vehicles')
        .update({
          'is_selected': false,
        })
        .eq('user_id', userId);
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}