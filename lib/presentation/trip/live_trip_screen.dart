import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LiveTripScreen extends ConsumerWidget {
  const LiveTripScreen({super.key});

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripSessionServiceProvider);
    final controller = ref.read(tripSessionServiceProvider.notifier);
    final location = state.currentLocation;
    final sensor = state.latestSensorSample;
    final feedback = state.lastFeedbackMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trayecto en vivo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isTracking ? 'Trayecto activo' : 'Trayecto inactivo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.statusMessage),
                    if (state.isSaving) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            if (feedback != null) ...[
              const SizedBox(height: 14),
              Card(
                color: _feedbackColor(feedback.severity),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feedback.message,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _AlertSettingsCard(
              visualAlertsEnabled: state.visualAlertsEnabled,
              voiceAlertsEnabled: state.voiceAlertsEnabled,
              realtimeFeedbackEnabled: state.realtimeFeedbackEnabled,
              onVisualChanged: controller.setVisualAlertsEnabled,
              onVoiceChanged: controller.setVoiceAlertsEnabled,
              onRealtimeChanged: controller.setRealtimeFeedbackEnabled,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Velocidad',
                    value: '${_formatNumber(state.currentSpeedKmh)} km/h',
                    icon: Icons.speed_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Distancia',
                    value: '${_formatNumber(state.distanceKm)} km',
                    icon: Icons.route_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Duración',
                    value: _formatDuration(state.durationSeconds),
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Eco score',
                    value: _formatNumber(state.ecoScore, decimals: 0),
                    icon: Icons.energy_savings_leaf_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Galones',
                    value: _formatNumber(state.estimatedFuelGallons, decimals: 4),
                    icon: Icons.local_gas_station_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Litros',
                    value: _formatNumber(state.estimatedFuelLiters, decimals: 3),
                    icon: Icons.opacity_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'km/galón',
                    value: _formatNumber(state.estimatedKmPerGallon),
                    icon: Icons.straighten_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'L/100 km',
                    value: _formatNumber(state.estimatedLitersPer100Km),
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Eventos detectados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aceleraciones bruscas: ${state.aggressiveAccelerationEvents}\n'
                      'Frenadas fuertes: ${state.hardBrakingEvents}\n'
                      'Eventos irregulares: ${state.irregularDrivingEvents}\n'
                      'Total de eventos: ${state.totalDrivingEvents}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación actual',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location == null
                          ? 'Esperando lectura GPS...'
                          : 'Latitud: ${location.latitude}\n'
                              'Longitud: ${location.longitude}\n'
                              'Precisión: ${_formatNumber(location.accuracy)} m\n'
                              'Altitud: ${location.altitude?.toStringAsFixed(2) ?? 'No disponible'} m\n'
                              'Pendiente estimada: ${_formatNumber(state.roadGradePercent)} %',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensores',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aceleración estimada GPS: ${_formatNumber(state.currentAccelerationMps2, decimals: 3)} m/s²\n'
                      'Acelerómetro X: ${sensor.accelerationX?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Acelerómetro Y: ${sensor.accelerationY?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Acelerómetro Z: ${sensor.accelerationZ?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Giroscopio X: ${sensor.gyroscopeX?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Giroscopio Y: ${sensor.gyroscopeY?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Giroscopio Z: ${sensor.gyroscopeZ?.toStringAsFixed(3) ?? 'No disponible'}\n'
                      'Barómetro: ${sensor.barometerPressure?.toStringAsFixed(2) ?? 'No disponible'} hPa',
                    ),
                  ],
                ),
              ),
            ),
            if (state.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Advertencias técnicas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.warnings.map(
                        (warning) => Text('• $warning'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!state.isTracking)
              FilledButton.icon(
                onPressed: state.isSaving ? null : controller.startManualTrip,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar trayecto'),
              )
            else
              FilledButton.icon(
                onPressed: state.isSaving ? null : controller.finishManualTrip,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Finalizar trayecto'),
              ),

            // ── BOTÓN RESUMEN ÚLTIMO TRAYECTO ─────────────────────────────────
            if (!state.isTracking && state.lastCompletedTripId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    AppRoutes.tripSummaryPath(state.lastCompletedTripId!),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Ver resumen del último trayecto'),
              ),
            ],
            // ─────────────────────────────────────────────────────────────────

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: state.isAutoDetectionEnabled
                  ? controller.disableAutoDetection
                  : controller.enableAutoDetection,
              icon: Icon(
                state.isAutoDetectionEnabled
                    ? Icons.pause_circle_outline_rounded
                    : Icons.auto_mode_rounded,
              ),
              label: Text(
                state.isAutoDetectionEnabled
                    ? 'Desactivar detección automática'
                    : 'Activar detección automática',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _feedbackColor(String severity) {
    if (severity == 'high') {
      return const Color(0xFFFFE0E0);
    }

    if (severity == 'medium') {
      return const Color(0xFFFFF3CD);
    }

    return const Color(0xFFE3F8E8);
  }
}

class _AlertSettingsCard extends StatelessWidget {
  final bool visualAlertsEnabled;
  final bool voiceAlertsEnabled;
  final bool realtimeFeedbackEnabled;
  final ValueChanged<bool> onVisualChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onRealtimeChanged;

  const _AlertSettingsCard({
    required this.visualAlertsEnabled,
    required this.voiceAlertsEnabled,
    required this.realtimeFeedbackEnabled,
    required this.onVisualChanged,
    required this.onVoiceChanged,
    required this.onRealtimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.notifications_active_rounded),
        title: const Text('Alertas y eco-feedback'),
        subtitle: const Text('Configura mensajes visuales y voz en tiempo real.'),
        children: [
          SwitchListTile(
            value: realtimeFeedbackEnabled,
            onChanged: onRealtimeChanged,
            title: const Text('Eco-feedback en tiempo real'),
          ),
          SwitchListTile(
            value: visualAlertsEnabled,
            onChanged: onVisualChanged,
            title: const Text('Alertas visuales'),
          ),
          SwitchListTile(
            value: voiceAlertsEnabled,
            onChanged: onVoiceChanged,
            title: const Text('Alertas por voz'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}