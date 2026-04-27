import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final drivingEventRepositoryProvider = Provider<DrivingEventRepository>((ref) {
  return DrivingEventRepository();
});

class DrivingEventRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  Future<void> saveDrivingEvent({
    required DrivingEventModel event,
  }) async {
    await _client.from('driving_events').insert(event.toInsertMap());
  }

  Future<List<DrivingEventModel>> getEventsByTripId({
    required String tripId,
  }) async {
    final data = await _client
        .from('driving_events')
        .select()
        .eq('trip_id', tripId)
        .order('detected_at', ascending: true);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(DrivingEventModel.fromMap).toList();
  }

  Future<double> getEstimatedFuelImpactGallons({
    required String tripId,
  }) async {
    final events = await getEventsByTripId(
      tripId: tripId,
    );

    return events.fold<double>(
      0,
      (total, event) => total + (event.fuelImpactEstimate ?? 0),
    );
  }
}