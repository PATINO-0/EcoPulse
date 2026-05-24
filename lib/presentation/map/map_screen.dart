import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/repositories/fuel_station_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:ecopulse/presentation/map/widgets/fuel_station_info_sheet.dart';
import 'package:ecopulse/presentation/map/widgets/map_legend_card.dart';
import 'package:ecopulse/services/fuel/fuel_market_sync_service.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  late Future<List<FuelStationModel>> _stationsFuture;
  bool _showFuelStations = true;
  bool _showLegend = false;
  bool _isReloading = false;
  bool? _manualDark;

  late final AnimationController _legendAnimController;
  late final AnimationController _pulseController;
  late final Animation<double> _legendAnim;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _loadStations();

    _legendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _legendAnim = CurvedAnimation(
      parent: _legendAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _legendAnimController.dispose();
    _pulseController.dispose();
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
  }) async {
    await ref.read(fuelMarketSyncServiceProvider).syncDailyMarketDataIfNeeded(
          forcePrices: forcePrices,
          forceStations: false,
        );

    return ref.read(fuelStationRepositoryProvider).getStationsForDefaultCity();
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

  void _centerOnCurrentLocation() {
    HapticFeedback.lightImpact();
    final location = ref.read(tripSessionServiceProvider).currentLocation;

    if (location == null) {
      _showToast('Todavía no hay una ubicación GPS disponible.');
      return;
    }

    _mapController.move(
      LatLng(location.latitude, location.longitude),
      16,
    );
  }

  Future<void> _reloadStations() async {
    if (_isReloading) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isReloading = true;
      _stationsFuture = _loadStations(forcePrices: true);
    });

    await _stationsFuture;

    if (!mounted) return;
    setState(() => _isReloading = false);
  }

  void _toggleLegend() {
    HapticFeedback.selectionClick();
    setState(() => _showLegend = !_showLegend);

    if (_showLegend) {
      _legendAnimController.forward();
    } else {
      _legendAnimController.reverse();
    }
  }

  void _toggleStations() {
    HapticFeedback.selectionClick();
    setState(() => _showFuelStations = !_showFuelStations);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripSessionServiceProvider);
    final tripController = ref.read(tripSessionServiceProvider.notifier);
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FutureBuilder<List<FuelStationModel>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            final stations = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return Stack(
              children: [
                Positioned.fill(
                  child: EcoPulseMap(
                    mapController: _mapController,
                    currentLocation: tripState.currentLocation,
                    routePoints: tripState.routePoints,
                    fuelStations: stations,
                    showFuelStations: _showFuelStations,
                    onFuelStationTap: _showStationInfo,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _MapHeader(
                    colors: colors,
                    isDark: isDark,
                    onToggleTheme: _toggleTheme,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: 72,
                  left: 14,
                  right: 14,
                  child: _LiveStatusCard(
                    colors: colors,
                    isTracking: tripState.isTracking,
                    speedKmh: tripState.currentSpeedKmh,
                    distanceKm: tripState.distanceKm,
                    points: tripState.routePoints.length,
                    statusMessage: tripState.statusMessage,
                    pulseController: _pulseController,
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 176,
                  child: _SideFabs(
                    colors: colors,
                    showFuelStations: _showFuelStations,
                    isReloading: _isReloading,
                    showLegend: _showLegend,
                    onCenter: _centerOnCurrentLocation,
                    onReload: _reloadStations,
                    onToggleStations: _toggleStations,
                    onToggleLegend: _toggleLegend,
                  ),
                ),
                if (isLoading)
                  Positioned(
                    right: 14,
                    bottom: 124,
                    child: _LoadingChip(colors: colors),
                  ),
                AnimatedBuilder(
                  animation: _legendAnim,
                  builder: (context, child) {
                    return Positioned(
                      right: 76,
                      bottom: 176 + (_showLegend ? 0 : 8),
                      child: IgnorePointer(
                        ignoring: !_showLegend,
                        child: Opacity(
                          opacity: _legendAnim.value,
                          child: Transform.scale(
                            scale: 0.92 + (_legendAnim.value * 0.08),
                            alignment: Alignment.bottomRight,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: MapLegendCard(colors: colors),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomPanel(
                    colors: colors,
                    isTracking: tripState.isTracking,
                    isSaving: tripState.isSaving,
                    showFuelStations: _showFuelStations,
                    onToggleStations: _toggleStations,
                    onStartTrip: tripController.startManualTrip,
                    onFinishTrip: tripController.finishManualTrip,
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

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.colors,
    required this.isDark,
    required this.onToggleTheme,
    required this.onBack,
  });

  final MapColors colors;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.background.withOpacity(0.96),
            colors.background.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          _MapFabButton(
            colors: colors,
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapa en tiempo real',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'GPS · OpenStreetMap',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _MapFabButton(
            colors: colors,
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onTap: onToggleTheme,
          ),
        ],
      ),
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({
    required this.colors,
    required this.isTracking,
    required this.speedKmh,
    required this.distanceKm,
    required this.points,
    required this.statusMessage,
    required this.pulseController,
  });

  final MapColors colors;
  final bool isTracking;
  final double speedKmh;
  final double distanceKm;
  final int points;
  final String statusMessage;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, _) {
                  final pulse = isTracking
                      ? (0.6 + pulseController.value * 0.4)
                      : 1.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isTracking)
                        Container(
                          width: 28 * pulse,
                          height: 28 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent.withOpacity(
                              0.18 * (1 - pulseController.value),
                            ),
                          ),
                        ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTracking
                              ? colors.accent
                              : colors.textMuted.withOpacity(0.3),
                          border: Border.all(
                            color: isTracking
                                ? colors.accent.withOpacity(0.5)
                                : colors.border,
                            width: 2,
                          ),
                        ),
                        child: isTracking
                            ? const Icon(
                                Icons.play_arrow_rounded,
                                size: 10,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTracking ? 'Trayecto activo' : 'En espera',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isTracking ? colors.accent : colors.textMuted,
                      ),
                    ),
                    Text(
                      statusMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.2,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.22),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      speedKmh.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isTracking) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusMetric(
                  colors: colors,
                  label: 'Distancia',
                  value: '${distanceKm.toStringAsFixed(2)} km',
                  icon: Icons.route_rounded,
                  accent: colors.accent,
                ),
                const SizedBox(width: 8),
                _StatusMetric(
                  colors: colors,
                  label: 'Puntos GPS',
                  value: '$points pts',
                  icon: Icons.pin_drop_rounded,
                  accent: colors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.colors,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final MapColors colors;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideFabs extends StatelessWidget {
  const _SideFabs({
    required this.colors,
    required this.showFuelStations,
    required this.isReloading,
    required this.showLegend,
    required this.onCenter,
    required this.onReload,
    required this.onToggleStations,
    required this.onToggleLegend,
  });

  final MapColors colors;
  final bool showFuelStations;
  final bool isReloading;
  final bool showLegend;
  final VoidCallback onCenter;
  final VoidCallback onReload;
  final VoidCallback onToggleStations;
  final VoidCallback onToggleLegend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapFabButton(
          colors: colors,
          icon: Icons.my_location_rounded,
          tooltip: 'Mi ubicación',
          onTap: onCenter,
          accent: true,
        ),
        const SizedBox(height: 10),
        _MapFabButton(
          colors: colors,
          icon: isReloading
              ? Icons.hourglass_top_rounded
              : Icons.refresh_rounded,
          tooltip: 'Actualizar precios',
          onTap: onReload,
          spinning: isReloading,
        ),
        const SizedBox(height: 10),
        _MapFabButton(
          colors: colors,
          icon: showFuelStations
              ? Icons.local_gas_station_rounded
              : Icons.local_gas_station_outlined,
          tooltip: showFuelStations
              ? 'Ocultar estaciones'
              : 'Mostrar estaciones',
          onTap: onToggleStations,
          active: showFuelStations,
        ),
        const SizedBox(height: 10),
        _MapFabButton(
          colors: colors,
          icon: Icons.layers_rounded,
          tooltip: 'Leyenda del mapa',
          onTap: onToggleLegend,
          active: showLegend,
        ),
      ],
    );
  }
}

class _MapFabButton extends StatelessWidget {
  const _MapFabButton({
    required this.colors,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.accent = false,
    this.active = false,
    this.spinning = false,
  });

  final MapColors colors;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool accent;
  final bool active;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? colors.accent
        : active
            ? colors.primary.withOpacity(0.16)
            : colors.card;

    final iconColor = accent
        ? Colors.white
        : active
            ? colors.primary
            : colors.textPrimary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
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
              border: Border.all(
                color: accent
                    ? Colors.transparent
                    : active
                        ? colors.primary.withOpacity(0.28)
                        : colors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: spinning
                ? _SpinningIcon(icon: icon, color: iconColor)
                : Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(widget.icon, size: 22, color: widget.color),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip({required this.colors});
  final MapColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Cargando...',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.colors,
    required this.isTracking,
    required this.isSaving,
    required this.showFuelStations,
    required this.onToggleStations,
    required this.onStartTrip,
    required this.onFinishTrip,
  });

  final MapColors colors;
  final bool isTracking;
  final bool isSaving;
  final bool showFuelStations;
  final VoidCallback onToggleStations;
  final VoidCallback onStartTrip;
  final VoidCallback onFinishTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _BottomButton(
                  colors: colors,
                  icon: showFuelStations
                      ? Icons.visibility_off_rounded
                      : Icons.local_gas_station_rounded,
                  label: showFuelStations
                      ? 'Ocultar estaciones'
                      : 'Ver estaciones',
                  color: colors.primary,
                  filled: false,
                  onTap: onToggleStations,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: isTracking
                      ? _BottomButton(
                          key: const ValueKey('finish'),
                          colors: colors,
                          icon: Icons.stop_rounded,
                          label: 'Finalizar',
                          color: colors.danger,
                          filled: true,
                          enabled: !isSaving,
                          onTap: onFinishTrip,
                        )
                      : _BottomButton(
                          key: const ValueKey('start'),
                          colors: colors,
                          icon: Icons.play_arrow_rounded,
                          label: 'Iniciar trayecto',
                          color: colors.accent,
                          filled: true,
                          enabled: !isSaving,
                          onTap: onStartTrip,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
    this.enabled = true,
  });

  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: filled ? color : color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: filled ? Colors.transparent : color.withOpacity(0.24),
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}