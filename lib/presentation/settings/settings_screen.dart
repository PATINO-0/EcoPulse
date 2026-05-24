import 'package:ecopulse/data/models/user_settings_model.dart';
import 'package:ecopulse/data/repositories/user_settings_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool? _manualDark;

  @override
  void initState() {
    super.initState();
    _settingsFuture =
        ref.read(userSettingsRepositoryProvider).getCurrentSettings();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _reloadSettings() async {
    HapticFeedback.lightImpact();
    setState(() {
      _settingsFuture =
          ref.read(userSettingsRepositoryProvider).getCurrentSettings();
    });
    await _settingsFuture;
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
        SnackBar(
          content: const Text('Configuración guardada correctamente.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible guardar configuración: $exception'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

  int _activeFeaturesCount(UserSettingsModel settings) {
    final values = [
      settings.realtimeFeedbackEnabled,
      settings.visualAlertsEnabled,
      settings.voiceAlertsEnabled,
    ];
    return values.where((value) => value).length;
  }

  String _consumptionLabel(String value) {
    switch (value) {
      case 'km_per_gallon':
        return 'km/galón';
      case 'liters_per_100km':
        return 'L/100 km';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<UserSettingsModel>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _settings == null) {
              return _SettingsLoadingView(colors: colors);
            }

            if (snapshot.hasError && _settings == null) {
              return _SettingsStatusView(
                colors: colors,
                icon: Icons.error_outline_rounded,
                accent: colors.danger,
                title: 'No fue posible cargar la configuración',
                message: 'Detalle: ${snapshot.error}',
                actionLabel: 'Reintentar',
                onPressed: _reloadSettings,
              );
            }

            final settings = _settings ?? snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isTablet = width >= 760;
                final isDesktop = width >= 1140;
                final horizontalPadding = isDesktop
                    ? 30.0
                    : isTablet
                        ? 24.0
                        : 18.0;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          14,
                          horizontalPadding,
                          14,
                        ),
                        child: _SettingsHeader(
                          colors: colors,
                          isDark: isDark,
                          isSaving: _isSaving,
                          onBack: () => Navigator.of(context).maybePop(),
                          onToggleTheme: _toggleTheme,
                          onRefresh: _reloadSettings,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          14,
                        ),
                        child: _SettingsHeroCard(
                          colors: colors,
                          settings: settings,
                          activeFeatures: _activeFeaturesCount(settings),
                          consumptionLabel:
                              _consumptionLabel(settings.consumptionUnit),
                          isWide: isTablet,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          22,
                        ),
                        child: isTablet
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _SettingsSummaryPanel(
                                      colors: colors,
                                      settings: settings,
                                      activeFeatures:
                                          _activeFeaturesCount(settings),
                                      consumptionLabel: _consumptionLabel(
                                        settings.consumptionUnit,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 7,
                                    child: _SettingsFormPanel(
                                      colors: colors,
                                      settings: settings,
                                      isSaving: _isSaving,
                                      onChanged: _updateLocal,
                                      onSave: () => _saveSettings(settings),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _SettingsSummaryPanel(
                                    colors: colors,
                                    settings: settings,
                                    activeFeatures:
                                        _activeFeaturesCount(settings),
                                    consumptionLabel: _consumptionLabel(
                                      settings.consumptionUnit,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SettingsFormPanel(
                                    colors: colors,
                                    settings: settings,
                                    isSaving: _isSaving,
                                    onChanged: _updateLocal,
                                    onSave: () => _saveSettings(settings),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onRefresh;

  const _SettingsHeader({
    required this.colors,
    required this.isDark,
    required this.isSaving,
    required this.onBack,
    required this.onToggleTheme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        if (compact) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card.withOpacity(0.96),
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
            child: Column(
              children: [
                Row(
                  children: [
                    _SettingsCircleAction(
                      icon: Icons.arrow_back_rounded,
                      color: colors.primary,
                      bg: colors.chip,
                      border: colors.chipBorder,
                      onTap: onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configuración',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Personaliza la experiencia de EcoPulse para que tus trayectos sean más claros, útiles e intuitivos.',
                    style: TextStyle(
                      fontSize: 12.2,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SettingsHeaderActionButton(
                        colors: colors,
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: isDark ? 'Modo claro' : 'Modo oscuro',
                        color: isDark ? colors.warning : colors.primary,
                        onTap: onToggleTheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SettingsHeaderActionButton(
                        colors: colors,
                        icon: isSaving
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        label: isSaving ? 'Guardando' : 'Recargar',
                        color: isSaving ? colors.warning : colors.accent,
                        onTap: onRefresh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card.withOpacity(0.96),
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
          child: Row(
            children: [
              _SettingsCircleAction(
                icon: Icons.arrow_back_rounded,
                color: colors.primary,
                bg: colors.chip,
                border: colors.chipBorder,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Personaliza la experiencia de EcoPulse para que tus trayectos sean más claros, útiles e intuitivos.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.2,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SettingsCircleAction(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: isDark ? colors.warning : colors.primary,
                bg: colors.chip,
                border: colors.chipBorder,
                onTap: onToggleTheme,
              ),
              const SizedBox(width: 8),
              _SettingsCircleAction(
                icon: isSaving
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                color: isSaving ? colors.warning : colors.accent,
                bg: (isSaving ? colors.warning : colors.accent).withOpacity(
                  0.12,
                ),
                border: (isSaving ? colors.warning : colors.accent)
                    .withOpacity(0.24),
                onTap: onRefresh,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  final MapColors colors;
  final UserSettingsModel settings;
  final int activeFeatures;
  final String consumptionLabel;
  final bool isWide;

  const _SettingsHeroCard({
    required this.colors,
    required this.settings,
    required this.activeFeatures,
    required this.consumptionLabel,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                const _SettingsHeroIcon(),
                const SizedBox(width: 18),
                Expanded(
                  child: _SettingsHeroIdentity(
                    activeFeatures: activeFeatures,
                    consumptionLabel: consumptionLabel,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: _SettingsHeroStatus(
                    settings: settings,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _SettingsHeroIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SettingsHeroIdentity(
                        activeFeatures: activeFeatures,
                        consumptionLabel: consumptionLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsHeroStatus(settings: settings),
              ],
            ),
    );
  }
}

class _SettingsHeroIcon extends StatelessWidget {
  const _SettingsHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.tune_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _SettingsHeroIdentity extends StatelessWidget {
  final int activeFeatures;
  final String consumptionLabel;

  const _SettingsHeroIdentity({
    required this.activeFeatures,
    required this.consumptionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centro de preferencias',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$activeFeatures funciones activas',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unidad actual: $consumptionLabel',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.8,
            height: 1.4,
            color: Colors.white.withOpacity(0.86),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeroStatus extends StatelessWidget {
  final UserSettingsModel settings;

  const _SettingsHeroStatus({
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final voiceState = settings.voiceAlertsEnabled ? 'Activa' : 'Desactivada';
    final visualState =
        settings.visualAlertsEnabled ? 'Activas' : 'Desactivadas';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _SettingsHeroMiniMetric(
            icon: Icons.record_voice_over_rounded,
            label: 'Alerta por voz',
            value: voiceState,
          ),
          const SizedBox(height: 10),
          _SettingsHeroMiniMetric(
            icon: Icons.visibility_rounded,
            label: 'Alertas visuales',
            value: visualState,
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingsHeroMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.6,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSummaryPanel extends StatelessWidget {
  final MapColors colors;
  final UserSettingsModel settings;
  final int activeFeatures;
  final String consumptionLabel;

  const _SettingsSummaryPanel({
    required this.colors,
    required this.settings,
    required this.activeFeatures,
    required this.consumptionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulta rápidamente el estado actual de tus preferencias de conducción.',
            style: TextStyle(
              fontSize: 12.4,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSummaryTile(
            colors: colors,
            icon: Icons.auto_awesome_rounded,
            label: 'Funciones activas',
            value: '$activeFeatures de 3 activadas',
            accent: colors.primary,
          ),
          const SizedBox(height: 12),
          _SettingsSummaryTile(
            colors: colors,
            icon: Icons.straighten_rounded,
            label: 'Unidad de consumo',
            value: consumptionLabel,
            accent: colors.accent,
          ),
          const SizedBox(height: 12),
          _SettingsSummaryTile(
            colors: colors,
            icon: Icons.speed_rounded,
            label: 'Eco-feedback',
            value: settings.realtimeFeedbackEnabled
                ? 'Visible en trayecto'
                : 'Desactivado',
            accent: colors.warning,
          ),
        ],
      ),
    );
  }
}

class _SettingsSummaryTile extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _SettingsSummaryTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.chipBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.2,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.0,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsFormPanel extends StatelessWidget {
  final MapColors colors;
  final UserSettingsModel settings;
  final bool isSaving;
  final ValueChanged<UserSettingsModel> onChanged;
  final VoidCallback onSave;

  const _SettingsFormPanel({
    required this.colors,
    required this.settings,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: colors.primary.withOpacity(0.20)),
                ),
                child: Icon(
                  Icons.settings_suggest_rounded,
                  size: 22,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferencias inteligentes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Controla cómo EcoPulse te acompaña durante cada trayecto.',
                        style: TextStyle(
                          fontSize: 12.4,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.chipBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistencia durante el trayecto',
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activa o desactiva los módulos que quieres usar mientras conduces.',
                  style: TextStyle(
                    fontSize: 11.6,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSwitchTile(
                  colors: colors,
                  icon: Icons.eco_rounded,
                  title: 'Eco-feedback en tiempo real',
                  subtitle:
                      'Muestra recomendaciones útiles mientras conduces.',
                  value: settings.realtimeFeedbackEnabled,
                  accent: colors.primary,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        realtimeFeedbackEnabled: value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SettingsSwitchTile(
                  colors: colors,
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas visuales',
                  subtitle:
                      'Muestra tarjetas de advertencia durante el trayecto.',
                  value: settings.visualAlertsEnabled,
                  accent: colors.accent,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        visualAlertsEnabled: value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SettingsSwitchTile(
                  colors: colors,
                  icon: Icons.record_voice_over_rounded,
                  title: 'Alertas por voz',
                  subtitle: 'Usa voz para avisar eventos importantes.',
                  value: settings.voiceAlertsEnabled,
                  accent: colors.warning,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        voiceAlertsEnabled: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.chipBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formato de consumo',
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona la unidad en la que prefieres ver tu consumo.',
                  style: TextStyle(
                    fontSize: 11.6,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsDropdownField(
                  colors: colors,
                  value: settings.consumptionUnit,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    onChanged(
                      settings.copyWith(
                        consumptionUnit: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acción principal',
                  style: TextStyle(
                    fontSize: 11.4,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarda tu configuración para aplicarla en tus próximas sesiones.',
                  style: TextStyle(
                    fontSize: 12.2,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _SettingsSaveButton(
                  colors: colors,
                  text: 'Guardar configuración',
                  icon: Icons.save_rounded,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? accent.withOpacity(0.08) : colors.card.withOpacity(0.88),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: value
                  ? accent.withOpacity(0.24)
                  : colors.border.withOpacity(0.85),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(value ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.3,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.9,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: value,
                activeColor: accent,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDropdownField extends StatelessWidget {
  final MapColors colors;
  final String value;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdownField({
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    OutlineInputBorder border(Color color, [double width = 1.15]) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: value,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.textSecondary,
      ),
      dropdownColor: colors.card,
      borderRadius: BorderRadius.circular(18),
      decoration: InputDecoration(
        labelText: 'Unidad de consumo',
        labelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            child: Icon(
              Icons.local_gas_station_rounded,
              size: 18,
              color: colors.primary.withOpacity(0.92),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        filled: true,
        fillColor: colors.card.withOpacity(0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: border(colors.border.withOpacity(0.90)),
        focusedBorder: border(colors.primary.withOpacity(0.95), 1.45),
        disabledBorder: border(colors.border.withOpacity(0.55)),
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
      onChanged: onChanged,
    );
  }
}

class _SettingsSaveButton extends StatelessWidget {
  final MapColors colors;
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SettingsSaveButton({
    required this.colors,
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = colors.textPrimary;
    final softSurface = colors.textPrimary.withOpacity(0.06);
    final borderColor = colors.textPrimary.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isLoading ? softSurface.withOpacity(0.75) : softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: buttonColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Guardando...',
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                    color: buttonColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ] else ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w800,
                      color: buttonColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsLoadingView extends StatelessWidget {
  final MapColors colors;

  const _SettingsLoadingView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando configuración',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos preparando tus preferencias personalizadas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
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

class _SettingsStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _SettingsStatusView({
    required this.colors,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withOpacity(0.22)),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.55,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettingsHeaderActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
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

class _SettingsCircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _SettingsCircleAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}