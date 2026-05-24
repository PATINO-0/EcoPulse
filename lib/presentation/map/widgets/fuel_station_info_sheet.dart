import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FuelStationInfoSheet extends StatelessWidget {
  final FuelStationModel station;

  const FuelStationInfoSheet({
    super.key,
    required this.station,
  });

  String _formatPrice(double? value) {
    if (value == null) {
      return 'No disponible';
    }

    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );

    return '${formatter.format(value)} COP/galón';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = MapColors(isDark);

    final sourceLabel = station.isOfficial
        ? 'Ubicación marcada como oficial'
        : 'Ubicación cargada por fuente externa o IA';

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
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
                        color: colors.shadow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.warning.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.local_gas_station_rounded,
                          color: colors.warning,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  label: station.city,
                                  color: Colors.white.withOpacity(0.10),
                                  borderColor: Colors.white.withOpacity(0.12),
                                  textColor: Colors.white,
                                  icon: Icons.location_city_rounded,
                                ),
                                _InfoChip(
                                  label: station.department,
                                  color: Colors.white.withOpacity(0.10),
                                  borderColor: Colors.white.withOpacity(0.12),
                                  textColor: Colors.white,
                                  icon: Icons.map_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  colors: colors,
                  title: 'Información general',
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.place_rounded,
                        label: 'Dirección',
                        value: station.address ?? 'No disponible',
                        colors: colors,
                      ),
                      _DetailRow(
                        icon: Icons.local_offer_rounded,
                        label: 'Combustibles',
                        value: station.fuelTypesText,
                        colors: colors,
                      ),
                      _DetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'Estado',
                        value: sourceLabel,
                        colors: colors,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  colors: colors,
                  title: 'Precios de referencia',
                  child: Column(
                    children: [
                      _PriceTile(
                        colors: colors,
                        label: 'Gasolina corriente',
                        value: _formatPrice(station.priceRegular),
                        accent: colors.primary,
                      ),
                      const SizedBox(height: 10),
                      _PriceTile(
                        colors: colors,
                        label: 'Diésel / ACPM',
                        value: _formatPrice(station.priceDiesel),
                        accent: colors.accent,
                      ),
                      if (station.priceExtra != null) ...[
                        const SizedBox(height: 10),
                        _PriceTile(
                          colors: colors,
                          label: 'Extra',
                          value: _formatPrice(station.priceExtra),
                          accent: colors.warning,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  colors: colors,
                  title: 'Trazabilidad',
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.hub_rounded,
                        label: 'Fuente ubicación',
                        value: station.locationSource ?? station.source,
                        colors: colors,
                      ),
                      _DetailRow(
                        icon: Icons.price_change_rounded,
                        label: 'Fuente precio',
                        value: station.priceSource ?? 'No disponible',
                        colors: colors,
                      ),
                      _DetailRow(
                        icon: Icons.update_rounded,
                        label: 'Precio actualizado',
                        value: _formatDate(station.priceUpdatedAt),
                        colors: colors,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La ubicación de la estación se carga una sola vez. Los precios se actualizan diariamente y se usan como referencia para los cálculos monetarios de EcoPulse.',
                          style: TextStyle(
                            fontSize: 12.4,
                            height: 1.55,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
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

class _SectionCard extends StatelessWidget {
  final MapColors colors;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.colors,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MapColors colors;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.3,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.2,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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

class _PriceTile extends StatelessWidget {
  final MapColors colors;
  final String label;
  final String value;
  final Color accent;

  const _PriceTile({
    required this.colors,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.local_atm_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.6,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}