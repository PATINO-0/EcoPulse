import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:flutter/material.dart';

class TripRouteMapCard extends StatelessWidget {
  final List<TripPointModel> points;

  const TripRouteMapCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No hay suficientes puntos para dibujar la ruta de este trayecto.',
          ),
        ),
      );
    }

    final routePoints = points.map((point) => point.toLocationSample()).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 320,
        child: EcoPulseMap(
          currentLocation: null,
          routePoints: routePoints,
          fuelStations: const [],
          showFuelStations: false,
          showEndMarker: true,
        ),
      ),
    );
  }
}