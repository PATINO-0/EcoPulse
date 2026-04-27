import 'package:ecopulse/data/models/user_settings_model.dart';
import 'package:ecopulse/data/repositories/user_settings_repository.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<UserSettingsModel> _settingsFuture;

  UserSettingsModel? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settingsFuture =
        ref.read(userSettingsRepositoryProvider).getCurrentSettings();
  }

  Future<void> _saveSettings(UserSettingsModel settings) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await ref
          .read(userSettingsRepositoryProvider)
          .updateSettings(settings: settings);

      ref.read(tripSessionServiceProvider.notifier).applyUserSettings(updated);

      setState(() {
        _settings = updated;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente.'),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible guardar configuración: $exception'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updateLocal(UserSettingsModel settings) {
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SafeArea(
        child: FutureBuilder<UserSettingsModel>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _settings == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError && _settings == null) {
              return Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'No fue posible cargar la configuración. Detalle: ${snapshot.error}',
                ),
              );
            }

            final settings = _settings ?? snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  value: settings.realtimeFeedbackEnabled,
                  title: const Text('Eco-feedback en tiempo real'),
                  subtitle: const Text(
                    'Muestra recomendaciones mientras conduces.',
                  ),
                  onChanged: (value) {
                    _updateLocal(
                      settings.copyWith(
                        realtimeFeedbackEnabled: value,
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  value: settings.visualAlertsEnabled,
                  title: const Text('Alertas visuales'),
                  subtitle: const Text(
                    'Muestra tarjetas de advertencia durante el trayecto.',
                  ),
                  onChanged: (value) {
                    _updateLocal(
                      settings.copyWith(
                        visualAlertsEnabled: value,
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  value: settings.voiceAlertsEnabled,
                  title: const Text('Alertas por voz'),
                  subtitle: const Text(
                    'Usa voz para avisar eventos importantes.',
                  ),
                  onChanged: (value) {
                    _updateLocal(
                      settings.copyWith(
                        voiceAlertsEnabled: value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: settings.consumptionUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de consumo',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'km_per_gallon',
                      child: Text('km/galón'),
                    ),
                    DropdownMenuItem(
                      value: 'liters_per_100km',
                      child: Text('L/100 km'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    _updateLocal(
                      settings.copyWith(
                        consumptionUnit: value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          _saveSettings(settings);
                        },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar configuración',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}