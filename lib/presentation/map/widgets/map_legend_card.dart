import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';

class MapLegendCard extends StatelessWidget {
  const MapLegendCard({
    super.key,
    required this.colors,
    this.fuelOnly = false,
  });

  final MapColors colors;
  final bool fuelOnly;

  @override
  Widget build(BuildContext context) {
    final items = fuelOnly
        ? [
            _LegendItem(
              color: colors.warning,
              label: 'Estación de combustible',
              icon: Icons.local_gas_station_rounded,
            ),
          ]
        : [
            _LegendItem(
              color: colors.accent,
              label: 'Mi ubicación',
              icon: Icons.navigation_rounded,
            ),
            _LegendItem(
              color: colors.primary,
              label: 'Inicio del trayecto',
              icon: Icons.flag_rounded,
            ),
            _LegendItem(
              color: colors.danger,
              label: 'Último punto',
              icon: Icons.sports_score_rounded,
            ),
            _LegendItem(
              color: colors.warning,
              label: 'Estación',
              icon: Icons.local_gas_station_rounded,
            ),
          ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.97),
        borderRadius: BorderRadius.circular(20),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leyenda',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
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

class _LegendItem {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });
}