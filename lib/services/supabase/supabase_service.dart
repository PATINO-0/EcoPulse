import 'package:ecopulse/core/environment/environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // Se inicializa Supabase con la URL base y la llave pública del proyecto.
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
  }

  static SupabaseClient get client {
    // Cliente centralizado para evitar crear múltiples instancias en la aplicación.
    return Supabase.instance.client;
  }
}