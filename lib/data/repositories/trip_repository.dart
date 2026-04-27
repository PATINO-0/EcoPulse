import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/data/models/trip_point_sample_model.dart';
import 'package:ecopulse/data/models/trip_sort_option.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

class TripRepository {
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

  Future<String> createTrip({
    required LocationSampleModel startLocation,
    String? vehicleId,
  }) async {
    final data = await _client
        .from('trips')
        .insert({
          'user_id': _currentUserId,
          'vehicle_id': vehicleId,
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
          'start_latitude': startLocation.latitude,
          'start_longitude': startLocation.longitude,
          'distance_km': 0,
          'duration_seconds': 0,
          'idle_time_seconds': 0,
          'estimation_method': 'physical_rules_fallback',
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  Future<void> saveTripPoint({
    required String tripId,
    required TripPointSampleModel point,
  }) async {
    await _client.from('trip_points').insert(
          point.toInsertMap(
            tripId: tripId,
          ),
        );
  }

  Future<void> finishTrip({
    required String tripId,
    required LocationSampleModel endLocation,
    required double distanceKm,
    required int durationSeconds,
    required int idleTimeSeconds,
    required int aggressiveAccelerationEvents,
    required int hardBrakingEvents,
    required int irregularDrivingEvents,
    required double estimatedFuelConsumedGallons,
    required double estimatedFuelConsumedLiters,
    required double estimatedKmPerGallon,
    required double estimatedLitersPer100Km,
    required double ecoScore,
    required String estimationMethod,
    double? fuelPricePerGallon,
    String? fuelPriceSource,
    bool fuelPriceIsOfficial = false,
    double? estimatedCostCop,
    double? costPerKmCop,
    double? estimatedSavingsCop,
  }) async {
    await _client
        .from('trips')
        .update({
          'status': 'completed',
          'ended_at': DateTime.now().toIso8601String(),
          'end_latitude': endLocation.latitude,
          'end_longitude': endLocation.longitude,
          'distance_km': distanceKm,
          'duration_seconds': durationSeconds,
          'idle_time_seconds': idleTimeSeconds,
          'aggressive_acceleration_events': aggressiveAccelerationEvents,
          'hard_braking_events': hardBrakingEvents,
          'irregular_driving_events': irregularDrivingEvents,
          'estimated_fuel_consumed_gallons': estimatedFuelConsumedGallons,
          'estimated_fuel_consumed_liters': estimatedFuelConsumedLiters,
          'estimated_km_per_gallon': estimatedKmPerGallon,
          'estimated_liters_per_100km': estimatedLitersPer100Km,
          'fuel_price_per_gallon': fuelPricePerGallon,
          'fuel_price_source': fuelPriceSource,
          'fuel_price_is_official': fuelPriceIsOfficial,
          'estimated_cost_cop': estimatedCostCop,
          'cost_per_km_cop': costPerKmCop,
          'estimated_savings_cop': estimatedSavingsCop,
          'eco_score': ecoScore,
          'estimation_method': estimationMethod,
        })
        .eq('id', tripId)
        .eq('user_id', _currentUserId);
  }

  Future<void> cancelTrip({
    required String tripId,
  }) async {
    await _client
        .from('trips')
        .update({
          'status': 'cancelled',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tripId)
        .eq('user_id', _currentUserId);
  }

  Future<List<TripModel>> getUserTrips({
    required TripSortOption sortOption,
  }) async {
    final data = await _client
        .from('trips')
        .select()
        .eq('user_id', _currentUserId)
        .eq('status', 'completed')
        .order(
          sortOption.column,
          ascending: sortOption.ascending,
        );

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(TripModel.fromMap).toList();
  }

  Future<TripModel> getTripById({
    required String tripId,
  }) async {
    final data = await _client
        .from('trips')
        .select()
        .eq('id', tripId)
        .eq('user_id', _currentUserId)
        .single();

    return TripModel.fromMap(data);
  }

  Future<List<TripPointModel>> getTripPoints({
    required String tripId,
  }) async {
    final data = await _client
        .from('trip_points')
        .select()
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: true);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(TripPointModel.fromMap).toList();
  }
}