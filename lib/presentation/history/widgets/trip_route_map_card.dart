import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:flutter/material.dart';

class TripRouteMapCard extends StatelessWidget {
  final List<TripPointModel> points;
  final MapColors colors;

  const TripRouteMapCard({
    super.key,
    required this.points,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'No hay suficientes puntos para dibujar la ruta de este trayecto.',
          style: TextStyle(
            fontSize: 12.3,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final routePoints = points.map((point) => point.toLocationSample()).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: colors.chip.withOpacity(0.72),
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primary.withOpacity(0.20)),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vista de ruta',
                    style: TextStyle(
                      fontSize: 13.6,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: EcoPulseMap(
              currentLocation: null,
              routePoints: routePoints,
              fuelStations: const [],
              showFuelStations: false,
              showEndMarker: true,
            ),
          ),
        ],
      ),
    );
  }
}