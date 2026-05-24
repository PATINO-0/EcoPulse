import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/data/repositories/fuel_price_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/services/fuel/fuel_market_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FuelPricesScreen extends ConsumerStatefulWidget {
  const FuelPricesScreen({super.key});

  @override
  ConsumerState<FuelPricesScreen> createState() => _FuelPricesScreenState();
}

class _FuelPricesScreenState extends ConsumerState<FuelPricesScreen> {
  late Future<List<FuelPriceModel>> _pricesFuture;
  bool _isRefreshing = false;
  bool? _manualDark;

  @override
  void initState() {
    super.initState();
    _pricesFuture = _loadPrices();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<List<FuelPriceModel>> _loadPrices({
    bool forcePrices = false,
  }) async {
    await ref.read(fuelMarketSyncServiceProvider).syncDailyMarketDataIfNeeded(
          forcePrices: forcePrices,
          forceStations: false,
        );

    return ref.read(fuelPriceRepositoryProvider).getFuelPricesForDefaultCity();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isRefreshing = true;
      _pricesFuture = _loadPrices(forcePrices: true);
    });

    await _pricesFuture;

    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd/MM/yyyy', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: colors.primary,
          backgroundColor: colors.card,
          onRefresh: _refresh,
          child: FutureBuilder<List<FuelPriceModel>>(
            future: _pricesFuture,
            builder: (context, snapshot) {
              final prices = snapshot.data ?? [];
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              if (isLoading) {
                return _FuelPricesLoadingView(colors: colors);
              }

              if (snapshot.hasError) {
                return _FuelPricesStatusView(
                  colors: colors,
                  icon: Icons.sync_problem_rounded,
                  accent: colors.danger,
                  title: 'No fue posible cargar los precios',
                  message:
                      'Detalle: ${snapshot.error}\n\nVerifica la sincronización, la conexión y la configuración del servicio.',
                  actionLabel: 'Reintentar',
                  onPressed: _refresh,
                );
              }

              if (prices.isEmpty) {
                return _FuelPricesStatusView(
                  colors: colors,
                  icon: Icons.local_gas_station_rounded,
                  accent: colors.warning,
                  title: 'Sin precios disponibles',
                  message:
                      'No hay precios registrados para Pasto, Nariño. Revisa la sincronización y la tabla fuel_prices.',
                  actionLabel: 'Actualizar',
                  onPressed: _refresh,
                );
              }

              final officialCount = prices.where((e) => e.isOfficial).length;
              final latestSync = prices
                  .map((e) => e.syncDate ?? e.updatedAt)
                  .whereType<DateTime>()
                  .fold<DateTime?>(null, (previous, current) {
                if (previous == null) return current;
                return current.isAfter(previous) ? current : previous;
              });

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isTablet = width >= 700;
                  final isDesktop = width >= 1100;

                  final useGrid = width >= 820;

                  final horizontalPadding = isDesktop
                      ? 30.0
                      : isTablet
                          ? 24.0
                          : 18.0;

                  final topSpacing = isDesktop ? 20.0 : 14.0;

                  final gridCardHeight = isDesktop ? 462.0 : 472.0;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topSpacing,
                            horizontalPadding,
                            14,
                          ),
                          child: _FuelPricesHeader(
                            colors: colors,
                            isDark: isDark,
                            isRefreshing: _isRefreshing,
                            onBack: () => Navigator.of(context).maybePop(),
                            onToggleTheme: _toggleTheme,
                            onRefresh: _refresh,
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
                          child: _FuelPricesHero(
                            colors: colors,
                            totalPrices: prices.length,
                            officialCount: officialCount,
                            latestSync: _formatDate(latestSync),
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
                            16,
                          ),
                          child: _FuelInfoBanner(colors: colors),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          28,
                        ),
                        sliver: useGrid
                            ? SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final price = prices[index];

                                    return _FuelPriceCard(
                                      colors: colors,
                                      price: price,
                                      formatMoney: _formatMoney,
                                      formatDate: _formatDate,
                                    );
                                  },
                                  childCount: prices.length,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      isDesktop ? 520 : 460,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  mainAxisExtent: gridCardHeight,
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final price = prices[index];
                                    final isLast = index == prices.length - 1;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLast ? 0 : 16,
                                      ),
                                      child: _FuelPriceCard(
                                        colors: colors,
                                        price: price,
                                        formatMoney: _formatMoney,
                                        formatDate: _formatDate,
                                      ),
                                    );
                                  },
                                  childCount: prices.length,
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
      ),
    );
  }
}

class _FuelPricesHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onRefresh;

  const _FuelPricesHeader({
    required this.colors,
    required this.isDark,
    required this.isRefreshing,
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
                        'Precios de combustible',
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
                    'Valores sincronizados para cálculos de trayectos y costos.',
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderActionButton(
                        colors: colors,
                        icon: isRefreshing
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        label: isRefreshing ? 'Actualizando' : 'Actualizar',
                        color: isRefreshing ? colors.warning : colors.accent,
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
                      'Precios de combustible',
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
                      'Valores sincronizados para cálculos de trayectos y costos.',
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
              const SizedBox(width: 8),
              _CircleAction(
                icon: isRefreshing
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                color: isRefreshing ? colors.warning : colors.accent,
                bg:
                    (isRefreshing ? colors.warning : colors.accent).withOpacity(
                  0.12,
                ),
                border:
                    (isRefreshing ? colors.warning : colors.accent).withOpacity(
                  0.24,
                ),
                onTap: onRefresh,
              ),
            ],
          ),
        );
      },
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

class _FuelPricesHero extends StatelessWidget {
  final MapColors colors;
  final int totalPrices;
  final int officialCount;
  final String latestSync;
  final bool isWide;

  const _FuelPricesHero({
    required this.colors,
    required this.totalPrices,
    required this.officialCount,
    required this.latestSync,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Panel de precios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  'COP/galón',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      child: _HeroMiniStat(
                        colors: colors,
                        icon: Icons.local_gas_station_rounded,
                        label: 'Combustibles',
                        value: '$totalPrices',
                        accent: colors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMiniStat(
                        colors: colors,
                        icon: Icons.verified_rounded,
                        label: 'Oficiales',
                        value: '$officialCount',
                        accent: colors.accent,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _HeroMiniStat(
                      colors: colors,
                      icon: Icons.local_gas_station_rounded,
                      label: 'Combustibles',
                      value: '$totalPrices',
                      accent: colors.warning,
                    ),
                    const SizedBox(height: 12),
                    _HeroMiniStat(
                      colors: colors,
                      icon: Icons.verified_rounded,
                      label: 'Oficiales',
                      value: '$officialCount',
                      accent: colors.accent,
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.92),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Última sincronización visible: $latestSync',
                    style: TextStyle(
                      fontSize: 12.3,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.88),
                    ),
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

class _HeroMiniStat extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HeroMiniStat({
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
              color: accent.withOpacity(0.18),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _FuelInfoBanner extends StatelessWidget {
  final MapColors colors;

  const _FuelInfoBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primary.withOpacity(0.22)),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: colors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'EcoPulse usa estos valores como referencia monetaria para estimar el costo de cada trayecto y mantener una lectura clara del mercado local.',
              style: TextStyle(
                fontSize: 12.8,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelPriceCard extends StatelessWidget {
  final MapColors colors;
  final FuelPriceModel price;
  final String Function(double value) formatMoney;
  final String Function(DateTime? value) formatDate;

  const _FuelPriceCard({
    required this.colors,
    required this.price,
    required this.formatMoney,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final accent = price.isOfficial ? colors.accent : colors.warning;
    final badgeLabel = price.isOfficial ? 'Oficial' : 'Referencia';

    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTopHeader(
            colors: colors,
            title: price.displayFuelType,
            badgeLabel: badgeLabel,
            accent: accent,
            isOfficial: price.isOfficial,
          ),
          const SizedBox(height: 14),
          _CardPriceBlock(
            colors: colors,
            accent: accent,
            amount: formatMoney(price.pricePerGallon),
          ),
          const SizedBox(height: 12),
          _CardInfoGrid(
            colors: colors,
            location: '${price.city}, ${price.department}',
            validFrom: formatDate(price.validFrom),
            syncDate: formatDate(price.syncDate ?? price.updatedAt),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.source_rounded,
                  size: 17,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fuente: ${price.source}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      height: 1.38,
                      color: colors.textSecondary,
                    ),
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

class _CardTopHeader extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String badgeLabel;
  final Color accent;
  final bool isOfficial;

  const _CardTopHeader({
    required this.colors,
    required this.title,
    required this.badgeLabel,
    required this.accent,
    required this.isOfficial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.22)),
          ),
          child: Icon(
            isOfficial
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color: accent,
            size: 23,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.22)),
                  ),
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.4,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardPriceBlock extends StatelessWidget {
  final MapColors colors;
  final Color accent;
  final String amount;

  const _CardPriceBlock({
    required this.colors,
    required this.accent,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.chipBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 9,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 9,
              height: 30,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio actual',
                  style: TextStyle(
                    fontSize: 11.1,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: colors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'COP/galón',
                          style: TextStyle(
                            fontSize: 11.1,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
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

class _CardInfoGrid extends StatelessWidget {
  final MapColors colors;
  final String location;
  final String validFrom;
  final String syncDate;

  const _CardInfoGrid({
    required this.colors,
    required this.location,
    required this.validFrom,
    required this.syncDate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340;

        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoMetricTile(
                colors: colors,
                icon: Icons.location_on_rounded,
                label: 'Ubicación',
                value: location,
                fullWidth: true,
              ),
              const SizedBox(height: 10),
              _InfoMetricTile(
                colors: colors,
                icon: Icons.calendar_month_rounded,
                label: 'Vigente',
                value: validFrom,
                fullWidth: true,
              ),
              const SizedBox(height: 10),
              _InfoMetricTile(
                colors: colors,
                icon: Icons.sync_rounded,
                label: 'Sincronización',
                value: syncDate,
                fullWidth: true,
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoMetricTile(
                    colors: colors,
                    icon: Icons.location_on_rounded,
                    label: 'Ubicación',
                    value: location,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoMetricTile(
                    colors: colors,
                    icon: Icons.calendar_month_rounded,
                    label: 'Vigente',
                    value: validFrom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoMetricTile(
              colors: colors,
              icon: Icons.sync_rounded,
              label: 'Sincronización',
              value: syncDate,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }
}

class _InfoMetricTile extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoMetricTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.chipBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.6,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      height: 1.34,
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

class _FuelPricesLoadingView extends StatelessWidget {
  final MapColors colors;

  const _FuelPricesLoadingView({required this.colors});

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
                'Cargando precios',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos consultando los valores de combustible disponibles.',
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

class _FuelPricesStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _FuelPricesStatusView({
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