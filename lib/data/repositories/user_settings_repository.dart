import 'package:ecopulse/data/models/user_settings_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userSettingsRepositoryProvider =
    Provider<UserSettingsRepository>((ref) {
  return UserSettingsRepository();
});

class UserSettingsRepository {
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

  Future<UserSettingsModel> getCurrentSettings() async {
    final data = await _client
        .from('user_settings')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (data == null) {
      final created = await _client
          .from('user_settings')
          .insert({
            'user_id': _currentUserId,
          })
          .select()
          .single();

      return UserSettingsModel.fromMap(created);
    }

    return UserSettingsModel.fromMap(data);
  }

  Future<UserSettingsModel> updateSettings({
    required UserSettingsModel settings,
  }) async {
    final data = await _client
        .from('user_settings')
        .update(settings.toUpdateMap())
        .eq('user_id', _currentUserId)
        .select()
        .single();

    return UserSettingsModel.fromMap(data);
  }
}