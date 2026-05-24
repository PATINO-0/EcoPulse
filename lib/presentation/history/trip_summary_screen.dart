import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:ecopulse/presentation/history/widgets/trip_metric_card.dart';
import 'package:ecopulse/presentation/history/widgets/trip_route_map_card.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TripSummaryScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripSummaryScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  bool? _manualDark;

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<_TripSummaryData> _loadData() async {
    final repository = ref.read(tripRepositoryProvider);

    final trip = await repository.getTripById(
      tripId: widget.tripId,
    );

    final points = await repository.getTripPoints(
      tripId: widget.tripId,
    );

    return _TripSummaryData(
      trip: trip,
      points: points,
    );
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

  String _formatMoney(double? value) {
    if (value == null) {
      return 'No disponible';
    }

    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDateOnly(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd MMM yyyy', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 760;
    final isDesktop = width >= 1140;
    final horizontalPadding = isDesktop
        ? 30.0
        : isTablet
            ? 24.0
            : 18.0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_TripSummaryData>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _TripLoadingView(colors: colors);
            }

            if (snapshot.hasError) {
              return _TripStatusView(
                colors: colors,
                icon: Icons.error_outline_rounded,
                accent: colors.danger,
                title: 'No fue posible cargar el resumen',
                message: 'Detalle: ${snapshot.error}',
                actionLabel: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
              );
            }

            final data = snapshot.data!;
            final trip = data.trip;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      14,
                    ),
                    child: _HistoryHeader(
                      colors: colors,
                      title: 'Resumen del trayecto',
                      subtitle:
                          'Una lectura breve, visual y elegante del recorrido finalizado.',
                      isDark: isDark,
                      onBack: () => Navigator.of(context).maybePop(),
                      onToggleTheme: _toggleTheme,
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
                    child: _TripHeroCard(
                      colors: colors,
                      isWide: isTablet,
                      title: 'Resumen listo',
                      dateLabel: _formatDateOnly(trip.startedAt),
                      subtitle:
                          'Tu recorrido quedó guardado con sus métricas principales y su lectura de eficiencia.',
                      leftMetricLabel: 'Costo',
                      leftMetricValue: _formatMoney(trip.estimatedCostCop),
                      rightMetricLabel: 'Eco score',
                      rightMetricValue:
                          trip.ecoScore?.toStringAsFixed(0) ?? 'N/D',
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
                    child: _InsightCard(
                      colors: colors,
                      accent: colors.primary,
                      icon: Icons.auto_graph_rounded,
                      title: 'Lectura general',
                      content:
                          'En este trayecto recorriste ${trip.distanceKm.toStringAsFixed(2)} km. '
                          'Tu consumo estimado fue de ${trip.estimatedFuelConsumedGallons.toStringAsFixed(4)} galones '
                          'y el costo estimado fue de ${_formatMoney(trip.estimatedCostCop)}.',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Distancia',
                                value: '${trip.distanceKm.toStringAsFixed(2)} km',
                                icon: Icons.route_rounded,
                                accent: colors.primary,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Duración',
                                value: _formatDuration(trip.durationSeconds),
                                icon: Icons.timer_rounded,
                                accent: colors.accent,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Galones',
                                value:
                                    trip.estimatedFuelConsumedGallons.toStringAsFixed(4),
                                icon: Icons.local_gas_station_rounded,
                                accent: colors.warning,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Litros',
                                value:
                                    trip.estimatedFuelConsumedLiters.toStringAsFixed(3),
                                icon: Icons.opacity_rounded,
                                accent: colors.primary,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Costo',
                                value: _formatMoney(trip.estimatedCostCop),
                                icon: Icons.payments_rounded,
                                accent: colors.textPrimary,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'COP/km',
                                value: _formatMoney(trip.costPerKmCop),
                                icon: Icons.attach_money_rounded,
                                accent: colors.accent,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Eco score',
                                value: trip.ecoScore?.toStringAsFixed(0) ?? 'N/D',
                                icon: Icons.energy_savings_leaf_rounded,
                                accent: colors.success,
                                colors: colors,
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: TripMetricCard(
                                title: 'Ahorro posible',
                                value: _formatMoney(trip.estimatedSavingsCop),
                                icon: Icons.savings_rounded,
                                accent: colors.warning,
                                colors: colors,
                              ),
                            ),
                          ],
                        );
                      },
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
                    child: _InsightCard(
                      colors: colors,
                      accent: colors.warning,
                      icon: Icons.warning_amber_rounded,
                      title: 'Eventos detectados',
                      content:
                          'Aceleraciones bruscas: ${trip.aggressiveAccelerationEvents}\n'
                          'Frenadas fuertes: ${trip.hardBrakingEvents}\n'
                          'Eventos irregulares: ${trip.irregularDrivingEvents}\n'
                          'Total: ${trip.totalEvents}',
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
                    child: _InsightCard(
                      colors: colors,
                      accent: colors.primary,
                      icon: Icons.local_gas_station_rounded,
                      title: 'Precio y estimación',
                      content:
                          'Precio usado por galón: ${_formatMoney(trip.fuelPricePerGallon)}\n'
                          'Fuente: ${trip.fuelPriceSource ?? 'No disponible'}\n'
                          'Marcado como oficial: ${trip.fuelPriceIsOfficial ? 'Sí' : 'No'}\n'
                          'Método de estimación: ${trip.estimationMethod}',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      4,
                      horizontalPadding,
                      10,
                    ),
                    child: _SectionTitleCard(
                      colors: colors,
                      title: 'Ruta del trayecto',
                      subtitle:
                          'Vista del recorrido consolidado para una lectura rápida.',
                      icon: Icons.map_rounded,
                      accent: colors.primary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      16,
                    ),
                    child: TripRouteMapCard(
                      points: data.points,
                      colors: colors,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      24,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.card.withOpacity(0.98),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'Nota técnica: el consumo es una estimación aproximada basada en GPS, sensores, datos del vehículo y reglas físico-matemáticas. No reemplaza datos OBD-II ni mediciones directas de la ECU.',
                        style: TextStyle(
                          fontSize: 12.2,
                          height: 1.55,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
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

class _TripSummaryData {
  final TripModel trip;
  final List<TripPointModel> points;

  const _TripSummaryData({
    required this.trip,
    required this.points,
  });
}

class _HistoryHeader extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;

  const _HistoryHeader({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onBack,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 560;

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
                _CircleAction(
                  icon: Icons.arrow_back_rounded,
                  color: colors.primary,
                  bg: colors.chip,
                  border: colors.chipBorder,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
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
                  child: _HeaderActionButton(
                    colors: colors,
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark ? 'Modo claro' : 'Modo oscuro',
                    color: isDark ? colors.warning : colors.primary,
                    onTap: onToggleTheme,
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
          const SizedBox(width: 10),
          _CircleAction(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: isDark ? colors.warning : colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onToggleTheme,
          ),
        ],
      ),
    );
  }
}

class _TripHeroCard extends StatelessWidget {
  final MapColors colors;
  final bool isWide;
  final String title;
  final String dateLabel;
  final String subtitle;
  final String leftMetricLabel;
  final String leftMetricValue;
  final String rightMetricLabel;
  final String rightMetricValue;

  const _TripHeroCard({
    required this.colors,
    required this.isWide,
    required this.title,
    required this.dateLabel,
    required this.subtitle,
    required this.leftMetricLabel,
    required this.leftMetricValue,
    required this.rightMetricLabel,
    required this.rightMetricValue,
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
        borderRadius: BorderRadius.circular(30),
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
                const _HeroTripIcon(),
                const SizedBox(width: 18),
                Expanded(
                  child: _HeroTripText(
                    title: title,
                    dateLabel: dateLabel,
                    subtitle: subtitle,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: _HeroTripPanel(
                    leftMetricLabel: leftMetricLabel,
                    leftMetricValue: leftMetricValue,
                    rightMetricLabel: rightMetricLabel,
                    rightMetricValue: rightMetricValue,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroTripIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeroTripText(
                        title: title,
                        dateLabel: dateLabel,
                        subtitle: subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HeroTripPanel(
                  leftMetricLabel: leftMetricLabel,
                  leftMetricValue: leftMetricValue,
                  rightMetricLabel: rightMetricLabel,
                  rightMetricValue: rightMetricValue,
                ),
              ],
            ),
    );
  }
}

class _HeroTripIcon extends StatelessWidget {
  const _HeroTripIcon();

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
        Icons.summarize_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _HeroTripText extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String subtitle;

  const _HeroTripText({
    required this.title,
    required this.dateLabel,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.08,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 3,
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

class _HeroTripPanel extends StatelessWidget {
  final String leftMetricLabel;
  final String leftMetricValue;
  final String rightMetricLabel;
  final String rightMetricValue;

  const _HeroTripPanel({
    required this.leftMetricLabel,
    required this.leftMetricValue,
    required this.rightMetricLabel,
    required this.rightMetricValue,
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
      child: Column(
        children: [
          _HeroMiniMetric(
            icon: Icons.payments_rounded,
            label: leftMetricLabel,
            value: leftMetricValue,
          ),
          const SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.energy_savings_leaf_rounded,
            label: rightMetricLabel,
            value: rightMetricValue,
          ),
        ],
      ),
    );
  }
}

class _HeroMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMiniMetric({
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

class _SectionTitleCard extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _SectionTitleCard({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.8,
                    height: 1.42,
                    color: colors.textSecondary,
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

class _InsightCard extends StatelessWidget {
  final MapColors colors;
  final Color accent;
  final IconData icon;
  final String title;
  final String content;

  const _InsightCard({
    required this.colors,
    required this.accent,
    required this.icon,
    required this.title,
    required this.content,
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
            color: colors.shadow.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.4,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 12.4,
                      height: 1.55,
                      color: colors.textSecondary,
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

class _TripLoadingView extends StatelessWidget {
  final MapColors colors;

  const _TripLoadingView({required this.colors});

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
                'Cargando resumen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos preparando la lectura del trayecto.',
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

class _TripStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _TripStatusView({
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
        Container(
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
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionButton({
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