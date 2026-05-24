import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/repositories/fuel_station_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:ecopulse/presentation/map/widgets/fuel_station_info_sheet.dart';
import 'package:ecopulse/presentation/map/widgets/map_legend_card.dart';
import 'package:ecopulse/services/fuel/fuel_market_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuelStationsMapScreen extends ConsumerStatefulWidget {
  const FuelStationsMapScreen({super.key});

  @override
  ConsumerState<FuelStationsMapScreen> createState() {
    return _FuelStationsMapScreenState();
  }
}

class _FuelStationsMapScreenState extends ConsumerState<FuelStationsMapScreen>
    with TickerProviderStateMixin {
  late Future<List<FuelStationModel>> _stationsFuture;
  bool _isRefreshing = false;
  bool _showLegend = false;
  bool? _manualDark;

  late final AnimationController _legendController;
  late final Animation<double> _legendAnimation;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _loadStations();

    _legendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _legendAnimation = CurvedAnimation(
      parent: _legendController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _legendController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<List<FuelStationModel>> _loadStations({
    bool forcePrices = false,
    bool forceStations = false,
  }) async {
    await ref.read(fuelMarketSyncServiceProvider).syncDailyMarketDataIfNeeded(
          forcePrices: forcePrices,
          forceStations: forceStations,
        );

    return ref.read(fuelStationRepositoryProvider).getStationsForDefaultCity();
  }

  Future<void> _reloadStations() async {
    if (_isRefreshing) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isRefreshing = true;
      _stationsFuture = _loadStations(
        forcePrices: true,
        forceStations: false,
      );
    });

    await _stationsFuture;

    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
    });
  }

  void _toggleLegend() {
    HapticFeedback.selectionClick();
    setState(() => _showLegend = !_showLegend);

    if (_showLegend) {
      _legendController.forward();
    } else {
      _legendController.reverse();
    }
  }

  void _showStationInfo(FuelStationModel station) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FuelStationInfoSheet(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<FuelStationModel>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _FuelLoadingView(colors: colors);
            }

            if (snapshot.hasError) {
              return _FuelStatusView(
                colors: colors,
                icon: Icons.wifi_off_rounded,
                accent: colors.danger,
                title: 'No fue posible cargar las estaciones',
                message:
                    'Detalle: ${snapshot.error}\n\nVerifica conexión, API key y datos en Supabase.',
                actionLabel: 'Reintentar',
                onPressed: _reloadStations,
              );
            }

            final stations = snapshot.data ?? [];

            if (stations.isEmpty) {
              return _FuelStatusView(
                colors: colors,
                icon: Icons.local_gas_station_rounded,
                accent: colors.warning,
                title: 'Sin estaciones disponibles',
                message:
                    'No hay estaciones registradas para Pasto, Nariño. Verifica la tabla fuel_stations y la sincronización.',
                actionLabel: 'Actualizar',
                onPressed: _reloadStations,
              );
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 88, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.card,
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: EcoPulseMap(
                          currentLocation: null,
                          routePoints: const [],
                          fuelStations: stations,
                          showFuelStations: true,
                          showEndMarker: false,
                          onFuelStationTap: _showStationInfo,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _FuelHeaderCard(
                    colors: colors,
                    title: 'Estaciones de combustible',
                    subtitle:
                        'Consulta puntos cercanos y revisa precios visibles.',
                    onBack: () => Navigator.of(context).maybePop(),
                    onRefresh: _reloadStations,
                    onToggleLegend: _toggleLegend,
                    onToggleTheme: _toggleTheme,
                    isRefreshing: _isRefreshing,
                    isLegendVisible: _showLegend,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: topPadding + 116,
                  left: 28,
                  right: 28,
                  child: _FuelHeroStats(
                    colors: colors,
                    stationsCount: stations.length,
                  ),
                ),
                AnimatedBuilder(
                  animation: _legendAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 20,
                      bottom: 132,
                      child: IgnorePointer(
                        ignoring: !_showLegend,
                        child: Opacity(
                          opacity: _legendAnimation.value,
                          child: Transform.scale(
                            scale: 0.92 + (_legendAnimation.value * 0.08),
                            alignment: Alignment.bottomLeft,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: MapLegendCard(
                    colors: colors,
                    fuelOnly: true,
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: _FuelBottomInfo(
                    colors: colors,
                    stationsCount: stations.length,
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

class _FuelHeaderCard extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onToggleLegend;
  final VoidCallback onToggleTheme;
  final bool isRefreshing;
  final bool isLegendVisible;
  final bool isDark;

  const _FuelHeaderCard({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onRefresh,
    required this.onToggleLegend,
    required this.onToggleTheme,
    required this.isRefreshing,
    required this.isLegendVisible,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.95),
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
          _CircleAction(
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
                  title,
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
                  subtitle,
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
          const SizedBox(width: 8),
          _CircleAction(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: isDark ? colors.warning : colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.layers_rounded,
            color: isLegendVisible ? colors.primary : colors.textSecondary,
            bg: isLegendVisible
                ? colors.primary.withOpacity(0.12)
                : colors.chip,
            border: isLegendVisible
                ? colors.primary.withOpacity(0.24)
                : colors.chipBorder,
            onTap: onToggleLegend,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: isRefreshing
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            color: isRefreshing ? colors.warning : colors.accent,
            bg:
                (isRefreshing ? colors.warning : colors.accent).withOpacity(0.12),
            border: (isRefreshing ? colors.warning : colors.accent)
                .withOpacity(0.24),
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _FuelHeroStats extends StatelessWidget {
  final MapColors colors;
  final int stationsCount;

  const _FuelHeroStats({
    required this.colors,
    required this.stationsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              colors: colors,
              icon: Icons.local_gas_station_rounded,
              label: 'Estaciones',
              value: '$stationsCount',
              accent: colors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              colors: colors,
              icon: Icons.verified_rounded,
              label: 'Cobertura',
              value: 'Pasto',
              accent: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MiniStat({
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

class _FuelBottomInfo extends StatelessWidget {
  final MapColors colors;
  final int stationsCount;

  const _FuelBottomInfo({
    required this.colors,
    required this.stationsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.warning.withOpacity(0.22)),
            ),
            child: Icon(
              Icons.local_gas_station_rounded,
              color: colors.warning,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.8,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$stationsCount estaciones ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text:
                        'disponibles para ${AppConstants.appName}. Toca cualquier marcador para ver detalles y precios.',
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

class _FuelLoadingView extends StatelessWidget {
  final MapColors colors;

  const _FuelLoadingView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
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
              'Cargando estaciones',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estamos consultando estaciones y precios disponibles.',
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
    );
  }
}

class _FuelStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _FuelStatusView({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
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
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _CircleAction({
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