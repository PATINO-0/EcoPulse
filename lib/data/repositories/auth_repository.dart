import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/profile_model.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  SupabaseClient get _client {
    return SupabaseService.client;
  }

  User? get currentUser {
    return _client.auth.currentUser;
  }

  Session? get currentSession {
    return _client.auth.currentSession;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (exception) {
      throw Exception(_translateAuthError(exception.message));
    } catch (exception) {
      throw Exception('No fue posible iniciar sesión. Detalle: $exception');
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedPolicy,
  }) async {
    if (!acceptedPolicy) {
      throw Exception(
        'Debes aceptar la política de tratamiento de datos para crear tu cuenta.',
      );
    }

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'accepted_policy': true,
          'policy_version': Environment.privacyPolicyVersion,
        },
      );

      if (response.user == null) {
        throw Exception('No fue posible crear el usuario en Supabase.');
      }
    } on AuthException catch (exception) {
      throw Exception(_translateAuthError(exception.message));
    } catch (exception) {
      throw Exception('No fue posible registrar la cuenta. Detalle: $exception');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
      );
    } on AuthException catch (exception) {
      throw Exception(_translateAuthError(exception.message));
    } catch (exception) {
      throw Exception(
        'No fue posible enviar el correo de recuperación. Detalle: $exception',
      );
    }
  }

  Future<ProfileModel> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return ProfileModel.empty(
        id: user.id,
        email: user.email,
      );
    }

    return ProfileModel.fromMap(data);
  }

  Future<void> updateProfile({
    required ProfileModel profile,
  }) async {
    await _client
        .from('profiles')
        .update(profile.toUpdateMap())
        .eq('id', profile.id);
  }

  String _translateAuthError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (lowerMessage.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de iniciar sesión.';
    }

    if (lowerMessage.contains('user already registered')) {
      return 'Ya existe una cuenta registrada con este correo.';
    }

    if (lowerMessage.contains('password')) {
      return 'La contraseña no cumple los requisitos mínimos.';
    }

    return message;
  }
}