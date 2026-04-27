import 'package:ecopulse/data/models/maintenance_record_model.dart';
import 'package:ecopulse/data/models/maintenance_recommendation_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

class MaintenanceRepository {
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

  Future<List<MaintenanceRecordModel>> getMaintenanceRecords() async {
    final data = await _client
        .from('maintenance_records')
        .select()
        .eq('user_id', _currentUserId)
        .order('next_due_at', ascending: true);

    final rows = List<Map<String, dynamic>>.from(data);

    return rows.map(MaintenanceRecordModel.fromMap).toList();
  }

  Future<void> createRecord({
    required String maintenanceType,
    required String? vehicleId,
    required DateTime? lastDoneAt,
    required DateTime? nextDueAt,
    String? notes,
    String status = 'pending',
  }) async {
    await _client.from('maintenance_records').insert({
      'user_id': _currentUserId,
      'vehicle_id': vehicleId,
      'maintenance_type': maintenanceType,
      'last_done_at': _dateToSql(lastDoneAt),
      'next_due_at': _dateToSql(nextDueAt),
      'notes': notes,
      'status': status,
    });
  }

  Future<void> createRecommendedRecords({
    required String? vehicleId,
    required List<MaintenanceRecommendationModel> recommendations,
  }) async {
    final now = DateTime.now();

    for (final recommendation in recommendations) {
      final nextDueAt = now.add(
        Duration(days: recommendation.suggestedIntervalDays),
      );

      await createRecord(
        maintenanceType: recommendation.maintenanceType,
        vehicleId: vehicleId,
        lastDoneAt: null,
        nextDueAt: nextDueAt,
        notes: recommendation.description,
      );
    }
  }

  Future<void> markAsCompleted({
    required MaintenanceRecordModel record,
  }) async {
    final now = DateTime.now();

    await _client
        .from('maintenance_records')
        .update({
          'last_done_at': _dateToSql(now),
          'next_due_at': _dateToSql(now.add(const Duration(days: 180))),
          'status': 'completed',
        })
        .eq('id', record.id)
        .eq('user_id', _currentUserId);
  }

  Future<void> deleteRecord({
    required String recordId,
  }) async {
    await _client
        .from('maintenance_records')
        .delete()
        .eq('id', recordId)
        .eq('user_id', _currentUserId);
  }

  String? _dateToSql(DateTime? value) {
    if (value == null) {
      return null;
    }

    return value.toIso8601String().substring(0, 10);
  }
}