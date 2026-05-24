import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_sort_option.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  TripSortOption _sortOption = TripSortOption.newest;
  late Future<List<TripModel>> _tripsFuture;
  bool? _manualDark;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  void _loadTrips() {
    _tripsFuture = ref.read(tripRepositoryProvider).getUserTrips(
          sortOption: _sortOption,
        );
  }

  void _changeSortOption(TripSortOption? option) {
    if (option == null) {
      return;
    }

    setState(() {
      _sortOption = option;
      _loadTrips();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTrips();
    });

    await _tripsFuture;
  }

  String _formatDateOnly(DateTime date) {
    return DateFormat('dd MMM yyyy', 'es_CO').format(date.toLocal());
  }

  String _formatMoney(double? value) {
    if (value == null) {
      return 'Costo no disponible';
    }

    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
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
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
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
                  child: _HistoryHeader(
                    colors: colors,
                    title: 'Historial',
                    subtitle:
                        'Explora tus trayectos finalizados con una lectura más clara, elegante y consistente.',
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
                    title: 'Tus trayectos guardados',
                    dateLabel: 'Historial EcoPulse',
                    subtitle:
                        'Ordena, revisa y abre el detalle de cada recorrido con una vista más pulida.',
                    leftMetricLabel: 'Vista',
                    leftMetricValue: 'Historial',
                    rightMetricLabel: 'Estado',
                    rightMetricValue: 'Sincronizado',
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: DropdownButtonFormField<TripSortOption>(
                      value: _sortOption,
                      borderRadius: BorderRadius.circular(18),
                      dropdownColor: colors.card,
                      decoration: InputDecoration(
                        labelText: 'Ordenar por',
                        labelStyle: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.4,
                        ),
                        filled: true,
                        fillColor: colors.chip.withOpacity(0.72),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                      items: TripSortOption.values.map((option) {
                        return DropdownMenuItem<TripSortOption>(
                          value: option,
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _changeSortOption,
                    ),
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
                  child: FutureBuilder<List<TripModel>>(
                    future: _tripsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _TripLoadingView(colors: colors);
                      }

                      if (snapshot.hasError) {
                        return _TripStatusCard(
                          colors: colors,
                          icon: Icons.error_outline_rounded,
                          accent: colors.danger,
                          title: 'No fue posible cargar el historial',
                          message: 'Detalle: ${snapshot.error}',
                        );
                      }

                      final trips = snapshot.data ?? [];

                      if (trips.isEmpty) {
                        return _TripStatusCard(
                          colors: colors,
                          icon: Icons.history_toggle_off_rounded,
                          accent: colors.warning,
                          title: 'Aún no tienes trayectos finalizados',
                          message:
                              'Inicia y finaliza un trayecto para verlo aquí con sus métricas y resumen.',
                        );
                      }

                      return Column(
                        children: trips.map((trip) {
                          return _TripHistoryCard(
                            colors: colors,
                            trip: trip,
                            dateLabel: _formatDateOnly(trip.startedAt),
                            costLabel: _formatMoney(trip.estimatedCostCop),
                            onTap: () {
                              context.push(AppRoutes.tripDetailPath(trip.id));
                            },
                          );
                        }).toList(),
                      );
                    },
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

class _TripHistoryCard extends StatelessWidget {
  final MapColors colors;
  final TripModel trip;
  final String dateLabel;
  final String costLabel;
  final VoidCallback onTap;

  const _TripHistoryCard({
    required this.colors,
    required this.trip,
    required this.dateLabel,
    required this.costLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ecoScore = trip.ecoScore?.toStringAsFixed(0) ?? 'N/D';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.primary.withOpacity(0.20),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ecoScore,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
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
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 14.8,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  compact
                                      ? '${trip.distanceKm.toStringAsFixed(2)} km • $costLabel'
                                      : '${trip.distanceKm.toStringAsFixed(2)} km • ${trip.estimatedFuelConsumedGallons.toStringAsFixed(4)} gal • $costLabel',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.2,
                                    height: 1.45,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TripTag(
                          label: 'Eco score $ecoScore',
                          color: colors.success,
                        ),
                        _TripTag(
                          label: '${trip.durationSeconds ~/ 60} min',
                          color: colors.accent,
                        ),
                        _TripTag(
                          label: 'Costo estimado',
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTag extends StatelessWidget {
  final String label;
  final Color color;

  const _TripTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.1,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  const _TripStatusCard({
    required this.colors,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
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
                    title,
                    style: TextStyle(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
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
        ],
      ),
    );
  }
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
        Icons.history_rounded,
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
            icon: Icons.sort_rounded,
            label: leftMetricLabel,
            value: leftMetricValue,
          ),
          const SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.check_circle_rounded,
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

class _TripLoadingView extends StatelessWidget {
  final MapColors colors;

  const _TripLoadingView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Cargando historial',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estamos preparando tus trayectos finalizados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
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