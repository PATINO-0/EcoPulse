import 'package:ecopulse/app/app.dart';
import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/core/errors/app_configuration_exception.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Se configura la localización principal de fechas, monedas y textos visibles.
    Intl.defaultLocale = 'es_CO';
    await initializeDateFormatting('es_CO', null);

    await Environment.load();
    await SupabaseService.initialize();

    runApp(
      const ProviderScope(
        child: EcoPulseApp(),
      ),
    );
  } on AppConfigurationException catch (exception) {
    runApp(
      StartupErrorApp(
        message: exception.message,
      ),
    );
  } catch (exception) {
    runApp(
      StartupErrorApp(
        message: 'No fue posible iniciar EcoPulse. Detalle técnico: $exception',
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPulse',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}