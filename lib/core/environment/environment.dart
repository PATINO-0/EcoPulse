import 'package:ecopulse/core/errors/app_configuration_exception.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> load() async {
    // Se carga el archivo .env local. En producción se puede reemplazar por configuración segura del entorno.
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
    );
  }

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'] ?? '';

    if (value.trim().isEmpty) {
      throw const AppConfigurationException(
        'Falta configurar SUPABASE_URL en el archivo .env.',
      );
    }

    if (value.contains('/rest/v1') || value.contains('/auth/v1')) {
      throw const AppConfigurationException(
        'SUPABASE_URL debe ser solo la URL base del proyecto. Ejemplo: https://xxxx.supabase.co',
      );
    }

    return _removeTrailingSlash(value.trim());
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (value.trim().isEmpty) {
      throw const AppConfigurationException(
        'Falta configurar SUPABASE_ANON_KEY en el archivo .env.',
      );
    }

    return value.trim();
  }

  static String get groqApiKey {
    return dotenv.env['GROQ_API_KEY']?.trim() ?? '';
  }

  static String get mapsApiKey {
    return dotenv.env['MAPS_API_KEY']?.trim() ?? '';
  }

  static String get defaultCity {
    return dotenv.env['DEFAULT_CITY']?.trim().toUpperCase() ?? 'PASTO';
  }

  static String get defaultDepartment {
    return dotenv.env['DEFAULT_DEPARTMENT']?.trim().toUpperCase() ?? 'NARIÑO';
  }

  static String get defaultCountry {
    return dotenv.env['DEFAULT_COUNTRY']?.trim().toUpperCase() ?? 'COLOMBIA';
  }

  static String get privacyPolicyVersion {
    return dotenv.env['PRIVACY_POLICY_VERSION']?.trim() ?? '1.0.0';
  }

  static String _removeTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }
  
  static String get groqModel {
    return dotenv.env['GROQ_MODEL']?.trim() ?? 'llama-3.1-8b-instant';
  }

}