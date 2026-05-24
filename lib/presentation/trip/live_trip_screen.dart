import 'dart:math' as math;

import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final consumptionUnitProvider = FutureProvider<String>((ref) async {
  final user = SupabaseService.client.auth.currentUser;
  if (user == null) return 'km_per_gallon';

  try {
    final data = await SupabaseService.client
        .from('user_settings')
        .select('consumption_unit')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    final map = data as Map<String, dynamic>?;
    final unit = map?['consumption_unit']?.toString().trim();

    if (unit == 'liters_per_100km' || unit == 'km_per_gallon') {
      return unit!;
    }

    return 'km_per_gallon';
  } catch (_) {
    return 'km_per_gallon';
  }
});

class LiveTripScreen extends ConsumerStatefulWidget {
  const LiveTripScreen({super.key});

  @override
  ConsumerState<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends ConsumerState<LiveTripScreen>
    with SingleTickerProviderStateMixin {
  bool? _manualDark;
  late final AnimationController _bgController;
  String? _lastFeedbackCache;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

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

  void _showTopPopupFeedback(
    BuildContext context,
    LiveTripColors colors,
    String severity,
    String message,
  ) {
    final tone = _FeedbackToneResolver.resolve(severity, colors);

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: tone.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tone.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(tone.icon, color: tone.iconColor, size: 20),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tone.text,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              'Cerrar',
              style: TextStyle(
                color: tone.iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripSessionServiceProvider);
    final controller = ref.read(tripSessionServiceProvider.notifier);
    final location = state.currentLocation;
    final sensor = state.latestSensorSample;
    final feedback = state.lastFeedbackMessage;
    final consumptionUnitAsync = ref.watch(consumptionUnitProvider);

    final isDark = _isDark(context);
    final colors = LiveTripColors(isDark);
    final size = MediaQuery.of(context).size;

    final horizontalPadding = size.width >= 1200
        ? size.width * 0.10
        : size.width >= 900
            ? 32.0
            : size.width >= 700
                ? 24.0
                : 18.0;

    ref.listen(tripSessionServiceProvider, (previous, next) {
      final prevMessage = previous?.lastFeedbackMessage?.message;
      final nextFeedback = next.lastFeedbackMessage;

      if (nextFeedback == null) return;
      if (nextFeedback.message == prevMessage ||
          nextFeedback.message == _lastFeedbackCache) {
        return;
      }

      _lastFeedbackCache = nextFeedback.message;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTopPopupFeedback(
          context,
          colors,
          nextFeedback.severity,
          nextFeedback.message,
        );
      });
    });

    final consumptionUnit = consumptionUnitAsync.value ?? 'km_per_gallon';
    final usesLiters = consumptionUnit == 'liters_per_100km';

    final highlightedConsumptionValue = usesLiters
        ? '${_formatNumber(state.estimatedFuelLiters, decimals: 3)} L'
        : '${_formatNumber(state.estimatedFuelGallons, decimals: 4)} gal';

    final highlightedEfficiencyValue = usesLiters
        ? '${_formatNumber(state.estimatedLitersPer100Km)} L/100 km'
        : '${_formatNumber(state.estimatedKmPerGallon)} km/gal';

    final unitMetrics = usesLiters
        ? [
            _GridMetricData(
              title: 'Litros',
              value: _formatNumber(state.estimatedFuelLiters, decimals: 3),
              subtitle: 'Consumo acumulado',
              icon: Icons.opacity_rounded,
              accent: colors.primary,
            ),
            _GridMetricData(
              title: 'L/100 km',
              value: _formatNumber(state.estimatedLitersPer100Km),
              subtitle: 'Rendimiento',
              icon: Icons.analytics_rounded,
              accent: colors.danger,
            ),
          ]
        : [
            _GridMetricData(
              title: 'Galones',
              value: _formatNumber(state.estimatedFuelGallons, decimals: 4),
              subtitle: 'Consumo acumulado',
              icon: Icons.local_gas_station_rounded,
              accent: colors.warning,
            ),
            _GridMetricData(
              title: 'km/galón',
              value: _formatNumber(state.estimatedKmPerGallon),
              subtitle: 'Rendimiento',
              icon: Icons.straighten_rounded,
              accent: colors.accent,
            ),
          ];

    final gridMetrics = [
      _GridMetricData(
        title: 'Velocidad',
        value: '${_formatNumber(state.currentSpeedKmh)} km/h',
        subtitle: 'Lectura en vivo',
        icon: Icons.speed_rounded,
        accent: colors.primary,
      ),
      _GridMetricData(
        title: 'Distancia',
        value: '${_formatNumber(state.distanceKm)} km',
        subtitle: 'Trayecto acumulado',
        icon: Icons.route_rounded,
        accent: colors.accent,
      ),
      _GridMetricData(
        title: 'Duración',
        value: _formatDuration(state.durationSeconds),
        subtitle: 'Tiempo total',
        icon: Icons.timer_rounded,
        accent: colors.warning,
      ),
      _GridMetricData(
        title: 'Eco score',
        value: _formatNumber(state.ecoScore, decimals: 0),
        subtitle: _ecoLabel(state.ecoScore),
        icon: Icons.energy_savings_leaf_rounded,
        accent: _ecoColor(state.ecoScore, colors),
      ),
      ...unitMetrics,
      _GridMetricData(
        title: 'Eventos',
        value: '${state.totalDrivingEvents}',
        subtitle: 'Incidencias detectadas',
        icon: Icons.auto_graph_rounded,
        accent: colors.danger,
      ),
      _GridMetricData(
        title: 'Estado',
        value: state.isTracking ? 'Activo' : 'En espera',
        subtitle: state.isAutoDetectionEnabled
            ? 'Auto detección activa'
            : 'Manual',
        icon: state.isTracking
            ? Icons.play_circle_fill_rounded
            : Icons.pause_circle_filled_rounded,
        accent: state.isTracking ? colors.accent : colors.textMuted,
      ),
    ];

    return AnimatedTheme(
      duration: const Duration(milliseconds: 250),
      data: isDark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            _LiveTripBackground(controller: _bgController, colors: colors),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.selectionClick();
                  ref.invalidate(consumptionUnitProvider);
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    28,
                  ),
                  children: [
                    _TopBar(
                      colors: colors,
                      isDark: isDark,
                      onToggleTheme: _toggleTheme,
                      onBack: () => context.pop(),
                    ),
                    if (feedback != null) ...[
                      const SizedBox(height: 14),
                      _AnimatedFeedbackCard(
                        colors: colors,
                        severity: feedback.severity,
                        message: feedback.message,
                        compact: true,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _HeroStatusCard(
                      colors: colors,
                      isTracking: state.isTracking,
                      statusMessage: state.statusMessage,
                      isSaving: state.isSaving,
                      ecoScore: state.ecoScore,
                      speed: state.currentSpeedKmh,
                      duration: _formatDuration(state.durationSeconds),
                      primaryConsumptionValue: highlightedConsumptionValue,
                      performanceValue: highlightedEfficiencyValue,
                      onPrimaryAction: state.isTracking
                          ? controller.finishManualTrip
                          : controller.startManualTrip,
                      onMap: () => context.push(AppRoutes.map),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(
                      colors: colors,
                      title: 'Controles y asistencia',
                      subtitle:
                          'Configura alertas y comportamiento en tiempo real.',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 12),
                    _AlertSettingsCard(
                      colors: colors,
                      visualAlertsEnabled: state.visualAlertsEnabled,
                      voiceAlertsEnabled: state.voiceAlertsEnabled,
                      realtimeFeedbackEnabled: state.realtimeFeedbackEnabled,
                      onVisualChanged: controller.setVisualAlertsEnabled,
                      onVoiceChanged: controller.setVoiceAlertsEnabled,
                      onRealtimeChanged: controller.setRealtimeFeedbackEnabled,
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(
                      colors: colors,
                      title: 'Métricas del trayecto',
                      subtitle:
                          'Cuadrícula principal adaptada a la unidad elegida por el usuario.',
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(height: 12),
                    _MetricBoard(
                      colors: colors,
                      items: gridMetrics,
                    ),
                    const SizedBox(height: 22),
                    _ResponsiveTwoColumns(
                      spacing: 12,
                      left: _InfoCard(
                        colors: colors,
                        title: 'Eventos detectados',
                        subtitle:
                            'Comportamiento de conducción durante el trayecto.',
                        icon: Icons.auto_graph_rounded,
                        child: Column(
                          children: [
                            _MiniStatRow(
                              colors: colors,
                              label: 'Aceleraciones bruscas',
                              value: '${state.aggressiveAccelerationEvents}',
                              accent: colors.warning,
                            ),
                            const SizedBox(height: 10),
                            _MiniStatRow(
                              colors: colors,
                              label: 'Frenadas fuertes',
                              value: '${state.hardBrakingEvents}',
                              accent: colors.danger,
                            ),
                            const SizedBox(height: 10),
                            _MiniStatRow(
                              colors: colors,
                              label: 'Eventos irregulares',
                              value: '${state.irregularDrivingEvents}',
                              accent: colors.primary,
                            ),
                            const SizedBox(height: 10),
                            _MiniStatRow(
                              colors: colors,
                              label: 'Total de eventos',
                              value: '${state.totalDrivingEvents}',
                              accent: colors.accent,
                              highlighted: true,
                            ),
                          ],
                        ),
                      ),
                      right: _InfoCard(
                        colors: colors,
                        title: 'Ubicación actual',
                        subtitle: 'Lecturas GPS y pendiente estimada.',
                        icon: Icons.my_location_rounded,
                        child: location == null
                            ? _EmptyInfoState(
                                colors: colors,
                                icon: Icons.gps_not_fixed_rounded,
                                text: 'Esperando lectura GPS...',
                              )
                            : Column(
                                children: [
                                  _InfoLine(
                                    colors: colors,
                                    label: 'Latitud',
                                    value: location.latitude.toString(),
                                  ),
                                  _InfoLine(
                                    colors: colors,
                                    label: 'Longitud',
                                    value: location.longitude.toString(),
                                  ),
                                  _InfoLine(
                                    colors: colors,
                                    label: 'Precisión',
                                    value:
                                        '${_formatNumber(location.accuracy)} m',
                                  ),
                                  _InfoLine(
                                    colors: colors,
                                    label: 'Altitud',
                                    value:
                                        '${location.altitude?.toStringAsFixed(2) ?? 'No disponible'} m',
                                  ),
                                  _InfoLine(
                                    colors: colors,
                                    label: 'Pendiente',
                                    value:
                                        '${_formatNumber(state.roadGradePercent)} %',
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      colors: colors,
                      title: 'Sensores',
                      subtitle:
                          'Lecturas compactas para una visualización más limpia.',
                      icon: Icons.sensors_rounded,
                      child: _CompactSensorGrid(
                        colors: colors,
                        items: [
                          _SensorData(
                            'Aceleración GPS',
                            '${_formatNumber(state.currentAccelerationMps2, decimals: 3)} m/s²',
                            colors.primary,
                          ),
                          _SensorData(
                            'Accel X',
                            sensor.accelerationX?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.accent,
                          ),
                          _SensorData(
                            'Accel Y',
                            sensor.accelerationY?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.accent,
                          ),
                          _SensorData(
                            'Accel Z',
                            sensor.accelerationZ?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.accent,
                          ),
                          _SensorData(
                            'Gyro X',
                            sensor.gyroscopeX?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.warning,
                          ),
                          _SensorData(
                            'Gyro Y',
                            sensor.gyroscopeY?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.warning,
                          ),
                          _SensorData(
                            'Gyro Z',
                            sensor.gyroscopeZ?.toStringAsFixed(3) ??
                                'No disponible',
                            colors.warning,
                          ),
                          _SensorData(
                            'Barómetro',
                            '${sensor.barometerPressure?.toStringAsFixed(2) ?? 'No disponible'} hPa',
                            colors.success,
                          ),
                        ],
                      ),
                    ),
                    if (state.warnings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        colors: colors,
                        title: 'Advertencias técnicas',
                        subtitle:
                            'Elementos que requieren revisión o seguimiento.',
                        icon: Icons.warning_amber_rounded,
                        child: Column(
                          children: state.warnings
                              .map(
                                (warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _WarningTile(
                                    colors: colors,
                                    text: warning,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SectionLabel(
                      colors: colors,
                      title: 'Acciones rápidas',
                      subtitle:
                          'Gestiona el trayecto y consulta el resumen más reciente.',
                      icon: Icons.bolt_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ActionButtonsBlock(
                      colors: colors,
                      isTracking: state.isTracking,
                      isSaving: state.isSaving,
                      isAutoDetectionEnabled: state.isAutoDetectionEnabled,
                      hasLastTrip: state.lastCompletedTripId != null,
                      onPrimary: state.isTracking
                          ? controller.finishManualTrip
                          : controller.startManualTrip,
                      onSummary: state.lastCompletedTripId == null
                          ? null
                          : () {
                              context.push(
                                AppRoutes.tripSummaryPath(
                                  state.lastCompletedTripId!,
                                ),
                              );
                            },
                      onAutoDetection: state.isAutoDetectionEnabled
                          ? controller.disableAutoDetection
                          : controller.enableAutoDetection,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ecoLabel(double score) {
    if (score >= 85) return 'Conducción muy eficiente';
    if (score >= 70) return 'Buen rendimiento';
    if (score >= 50) return 'Puede mejorar';
    return 'Conducción exigente';
  }

  static Color _ecoColor(double score, LiveTripColors colors) {
    if (score >= 85) return colors.success;
    if (score >= 70) return colors.accent;
    if (score >= 50) return colors.warning;
    return colors.danger;
  }
}

class _GridMetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _GridMetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class _SensorData {
  final String title;
  final String value;
  final Color accent;

  const _SensorData(this.title, this.value, this.accent);
}

class LiveTripColors {
  final bool isDark;
  const LiveTripColors(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF0A1628) : const Color(0xFFF2F7FB);
  Color get background2 =>
      isDark ? const Color(0xFF0D1F3C) : const Color(0xFFE5EEF5);
  Color get background3 =>
      isDark ? const Color(0xFF08131F) : const Color(0xFFDCEBF4);

  Color get card => isDark ? const Color(0xFF132033) : Colors.white;
  Color get cardAlt =>
      isDark ? const Color(0xFF0F1A2C) : const Color(0xFFF7FAFD);

  Color get border => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get shadow => isDark
      ? Colors.black.withOpacity(0.28)
      : const Color(0xFF5F96B3).withOpacity(0.10);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary =>
      isDark ? const Color(0xFF9BB1C2) : const Color(0xFF5D7383);
  Color get textMuted =>
      isDark ? const Color(0xFF6E8799) : const Color(0xFF8FA5B3);

  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);
  Color get warning => const Color(0xFFF4A261);
  Color get success => const Color(0xFF57B65F);
  Color get danger => const Color(0xFFE76F51);

  Color get heroTop =>
      isDark ? const Color(0xFF12243C) : const Color(0xFF17314E);
  Color get heroBottom =>
      isDark ? const Color(0xFF0E1B2D) : const Color(0xFF0F2339);

  Color get chip => isDark
      ? const Color(0xFF0F1A2C).withOpacity(0.85)
      : const Color(0xFFEAF2F8).withOpacity(0.96);

  Color get chipBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get orb1 => isDark
      ? const Color(0xFF2EC4B6).withOpacity(0.10)
      : const Color(0xFF2EC4B6).withOpacity(0.07);

  Color get orb2 => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.09)
      : const Color(0xFF5F96B3).withOpacity(0.08);

  Color get orb3 => isDark
      ? const Color(0xFFF4A261).withOpacity(0.07)
      : const Color(0xFFF4A261).withOpacity(0.05);

  Color get dots => isDark
      ? Colors.white.withOpacity(0.022)
      : const Color(0xFF5F96B3).withOpacity(0.07);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.isDark,
    required this.onToggleTheme,
    required this.onBack,
  });

  final LiveTripColors colors;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconActionButton(
          colors: colors,
          icon: Icons.arrow_back_rounded,
          tooltip: 'Volver',
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trayecto en vivo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Monitorea tu conducción en tiempo real.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _IconActionButton(
          colors: colors,
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          onTap: onToggleTheme,
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.colors,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final LiveTripColors colors;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: colors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({
    required this.colors,
    required this.isTracking,
    required this.statusMessage,
    required this.isSaving,
    required this.ecoScore,
    required this.speed,
    required this.duration,
    required this.primaryConsumptionValue,
    required this.performanceValue,
    required this.onPrimaryAction,
    required this.onMap,
  });

  final LiveTripColors colors;
  final bool isTracking;
  final String statusMessage;
  final bool isSaving;
  final double ecoScore;
  final double speed;
  final String duration;
  final String primaryConsumptionValue;
  final String performanceValue;
  final VoidCallback onPrimaryAction;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _LiveTripScreenState._ecoColor(ecoScore, colors);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isTracking ? colors.accent : colors.warning)
                          .withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (isTracking ? colors.accent : colors.warning)
                            .withOpacity(0.26),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTracking
                              ? Icons.play_circle_fill_rounded
                              : Icons.pause_circle_filled_rounded,
                          size: 15,
                          color: isTracking ? colors.accent : colors.warning,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isTracking ? 'Trayecto activo' : 'Trayecto inactivo',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scoreColor.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.energy_savings_leaf_rounded,
                      size: 15,
                      color: scoreColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ecoScore.toStringAsFixed(0)} pts',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _HeroCenteredCarGraphic(),
          const SizedBox(height: 18),
          Text(
            isTracking
                ? 'Conducción monitoreada en tiempo real'
                : 'Todo listo para iniciar tu trayecto',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: Colors.white.withOpacity(0.74),
              ),
            ),
          ),
          if (isSaving) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                color: colors.accent,
                backgroundColor: Colors.white.withOpacity(0.10),
              ),
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final metrics = [
                _HeroMetricPill(
                  label: 'Velocidad',
                  value: '${speed.toStringAsFixed(1)} km/h',
                  icon: Icons.speed_rounded,
                ),
                _HeroMetricPill(
                  label: 'Duración',
                  value: duration,
                  icon: Icons.timer_rounded,
                ),
                _HeroMetricPill(
                  label: 'Consumo',
                  value: primaryConsumptionValue,
                  icon: Icons.local_gas_station_rounded,
                ),
                _HeroMetricPill(
                  label: 'Rendimiento',
                  value: performanceValue,
                  icon: Icons.analytics_rounded,
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (int i = 0; i < metrics.length; i++) ...[
                      metrics[i],
                      if (i < metrics.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < metrics.length; i++) ...[
                    Expanded(child: metrics[i]),
                    if (i < metrics.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroActionButton(
                label: isTracking ? 'Finalizar trayecto' : 'Iniciar trayecto',
                icon:
                    isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: isTracking ? colors.danger : colors.accent,
                filled: true,
                onTap: onPrimaryAction,
              ),
              _HeroActionButton(
                label: 'Abrir mapa',
                icon: Icons.map_rounded,
                color: colors.primary,
                onTap: onMap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCenteredCarGraphic extends StatefulWidget {
  const _HeroCenteredCarGraphic();

  @override
  State<_HeroCenteredCarGraphic> createState() =>
      _HeroCenteredCarGraphicState();
}

class _HeroCenteredCarGraphicState extends State<_HeroCenteredCarGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF2EC4B6) : const Color(0xFF5F96B3);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + (_controller.value * 0.16);
        final opacity = 1 - _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withOpacity(0.18 * opacity),
                    width: 12,
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: const Icon(
          Icons.directions_car_filled_rounded,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.86), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.66),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? color : color.withOpacity(0.26),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackToneResolver {
  static _FeedbackTone resolve(String severity, LiveTripColors colors) {
    if (severity == 'high') {
      return _FeedbackTone(
        bg: colors.danger.withOpacity(0.10),
        border: colors.danger.withOpacity(0.22),
        shadow: colors.danger.withOpacity(0.10),
        iconBg: colors.danger.withOpacity(0.14),
        iconColor: colors.danger,
        text: colors.textPrimary,
        icon: Icons.priority_high_rounded,
      );
    }

    if (severity == 'medium') {
      return _FeedbackTone(
        bg: colors.warning.withOpacity(0.12),
        border: colors.warning.withOpacity(0.24),
        shadow: colors.warning.withOpacity(0.10),
        iconBg: colors.warning.withOpacity(0.14),
        iconColor: colors.warning,
        text: colors.textPrimary,
        icon: Icons.tips_and_updates_rounded,
      );
    }

    return _FeedbackTone(
      bg: colors.success.withOpacity(0.10),
      border: colors.success.withOpacity(0.20),
      shadow: colors.success.withOpacity(0.09),
      iconBg: colors.success.withOpacity(0.14),
      iconColor: colors.success,
      text: colors.textPrimary,
      icon: Icons.eco_rounded,
    );
  }
}

class _AnimatedFeedbackCard extends StatelessWidget {
  const _AnimatedFeedbackCard({
    required this.colors,
    required this.severity,
    required this.message,
    this.compact = false,
  });

  final LiveTripColors colors;
  final String severity;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tone = _FeedbackToneResolver.resolve(severity, colors);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: tone.border),
        boxShadow: [
          BoxShadow(
            color: tone.shadow,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: tone.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tone.icon, color: tone.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: compact ? 12.8 : 13.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: tone.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTone {
  final Color bg;
  final Color border;
  final Color shadow;
  final Color iconBg;
  final Color iconColor;
  final Color text;
  final IconData icon;

  _FeedbackTone({
    required this.bg,
    required this.border,
    required this.shadow,
    required this.iconBg,
    required this.iconColor,
    required this.text,
    required this.icon,
  });
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final LiveTripColors colors;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.chip,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: colors.chipBorder),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBoard extends StatelessWidget {
  const _MetricBoard({
    required this.colors,
    required this.items,
  });

  final LiveTripColors colors;
  final List<_GridMetricData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final crossAxisCount = isCompact ? 2 : 3;
        final ratio = isCompact ? 1.15 : 1.08;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return _MetricTile(
              colors: colors,
              data: item,
            );
          },
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.colors,
    required this.data,
  });

  final LiveTripColors colors;
  final _GridMetricData data;

  @override
  Widget build(BuildContext context) {
    return _BasePanel(
      colors: colors,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricIconBox(accent: data.accent, icon: data.icon, small: true),
          const Spacer(),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.2,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.2,
              height: 1.35,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricIconBox extends StatelessWidget {
  const _MetricIconBox({
    required this.accent,
    required this.icon,
    this.small = false,
  });

  final Color accent;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 46.0;
    final iconSize = small ? 19.0 : 22.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Icon(icon, size: iconSize, color: accent),
    );
  }
}

class _ResponsiveTwoColumns extends StatelessWidget {
  const _ResponsiveTwoColumns({
    required this.left,
    required this.right,
    this.spacing = 12,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final LiveTripColors colors;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _BasePanel(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetricIconBox(accent: colors.primary, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.colors,
    required this.label,
    required this.value,
    required this.accent,
    this.highlighted = false,
  });

  final LiveTripColors colors;
  final String label;
  final String value;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? accent.withOpacity(0.12) : colors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? accent.withOpacity(0.22) : colors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.colors,
    required this.label,
    required this.value,
  });

  final LiveTripColors colors;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInfoState extends StatelessWidget {
  const _EmptyInfoState({
    required this.colors,
    required this.icon,
    required this.text,
  });

  final LiveTripColors colors;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.8,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSensorGrid extends StatelessWidget {
  const _CompactSensorGrid({
    required this.colors,
    required this.items,
  });

  final LiveTripColors colors;
  final List<_SensorData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 560 ? 2 : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.cardAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.8,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({
    required this.colors,
    required this.text,
  });

  final LiveTripColors colors;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.danger.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: colors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.8,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsBlock extends StatelessWidget {
  const _ActionButtonsBlock({
    required this.colors,
    required this.isTracking,
    required this.isSaving,
    required this.isAutoDetectionEnabled,
    required this.hasLastTrip,
    required this.onPrimary,
    required this.onSummary,
    required this.onAutoDetection,
  });

  final LiveTripColors colors;
  final bool isTracking;
  final bool isSaving;
  final bool isAutoDetectionEnabled;
  final bool hasLastTrip;
  final VoidCallback onPrimary;
  final VoidCallback? onSummary;
  final VoidCallback onAutoDetection;

  @override
  Widget build(BuildContext context) {
    return _BasePanel(
      colors: colors,
      child: Column(
        children: [
          _ResponsiveButton(
            icon: isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
            label: isTracking ? 'Finalizar trayecto' : 'Iniciar trayecto',
            color: isTracking ? colors.danger : colors.accent,
            filled: true,
            enabled: !isSaving,
            onTap: onPrimary,
          ),
          if (hasLastTrip) ...[
            const SizedBox(height: 10),
            _ResponsiveButton(
              icon: Icons.receipt_long_rounded,
              label: 'Ver resumen del último trayecto',
              color: colors.primary,
              enabled: onSummary != null,
              onTap: onSummary,
            ),
          ],
          const SizedBox(height: 10),
          _ResponsiveButton(
            icon: isAutoDetectionEnabled
                ? Icons.pause_circle_outline_rounded
                : Icons.auto_mode_rounded,
            label: isAutoDetectionEnabled
                ? 'Desactivar detección automática'
                : 'Activar detección automática',
            color: isAutoDetectionEnabled ? colors.warning : colors.primary,
            onTap: onAutoDetection,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveButton extends StatelessWidget {
  const _ResponsiveButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = enabled ? onTap : null;

    return Material(
      color: filled ? color : color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: effectiveOnTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                effectiveOnTap();
              },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? color : color.withOpacity(0.22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : color,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertSettingsCard extends StatelessWidget {
  const _AlertSettingsCard({
    required this.colors,
    required this.visualAlertsEnabled,
    required this.voiceAlertsEnabled,
    required this.realtimeFeedbackEnabled,
    required this.onVisualChanged,
    required this.onVoiceChanged,
    required this.onRealtimeChanged,
  });

  final LiveTripColors colors;
  final bool visualAlertsEnabled;
  final bool voiceAlertsEnabled;
  final bool realtimeFeedbackEnabled;
  final ValueChanged<bool> onVisualChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onRealtimeChanged;

  @override
  Widget build(BuildContext context) {
    return _BasePanel(
      colors: colors,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: colors.primary.withOpacity(0.08),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primary.withOpacity(0.20)),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: colors.primary,
            ),
          ),
          title: Text(
            'Alertas y eco-feedback',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Configura mensajes visuales y voz en tiempo real.',
              style: TextStyle(
                fontSize: 12.2,
                color: colors.textSecondary,
              ),
            ),
          ),
          children: [
            const SizedBox(height: 10),
            _SwitchTile(
              colors: colors,
              value: realtimeFeedbackEnabled,
              onChanged: onRealtimeChanged,
              title: 'Eco-feedback en tiempo real',
              subtitle: 'Consejos inmediatos mientras conduces.',
              icon: Icons.bolt_rounded,
            ),
            _SwitchTile(
              colors: colors,
              value: visualAlertsEnabled,
              onChanged: onVisualChanged,
              title: 'Alertas visuales',
              subtitle: 'Indicadores en pantalla y señales de estado.',
              icon: Icons.visibility_rounded,
            ),
            _SwitchTile(
              colors: colors,
              value: voiceAlertsEnabled,
              onChanged: onVoiceChanged,
              title: 'Alertas por voz',
              subtitle: 'Mensajes hablados durante el trayecto.',
              icon: Icons.record_voice_over_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.colors,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final LiveTripColors colors;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.8,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: colors.accent,
          ),
        ],
      ),
    );
  }
}

class _BasePanel extends StatelessWidget {
  const _BasePanel({
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final LiveTripColors colors;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LiveTripBackground extends StatelessWidget {
  const _LiveTripBackground({
    required this.controller,
    required this.colors,
  });

  final AnimationController controller;
  final LiveTripColors colors;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.background,
                    colors.background2,
                    colors.background3,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.06 + math.sin(t) * size.height * 0.04,
              right: -size.width * 0.22 + math.cos(t) * size.width * 0.03,
              child: _BgOrb(size: size.width * 0.84, color: colors.orb1),
            ),
            Positioned(
              top: size.height * 0.40 +
                  math.sin(t + math.pi) * size.height * 0.04,
              left: -size.width * 0.24 +
                  math.cos(t + math.pi) * size.width * 0.03,
              child: _BgOrb(size: size.width * 0.70, color: colors.orb2),
            ),
            Positioned(
              bottom: size.height * 0.08 +
                  math.cos(t * 0.6) * size.height * 0.03,
              right:
                  size.width * 0.04 + math.sin(t * 0.6) * size.width * 0.04,
              child: _BgOrb(size: size.width * 0.50, color: colors.orb3),
            ),
            CustomPaint(size: size, painter: _DotGrid(colors.dots)),
          ],
        );
      },
    );
  }
}

class _BgOrb extends StatelessWidget {
  const _BgOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _DotGrid extends CustomPainter {
  const _DotGrid(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 26.0;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGrid oldDelegate) {
    return oldDelegate.color != color;
  }
}