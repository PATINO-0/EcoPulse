import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EcoPulseMap extends StatelessWidget {
  final LocationSampleModel? currentLocation;
  final List<LocationSampleModel> routePoints;
  final List<FuelStationModel> fuelStations;
  final bool showFuelStations;
  final bool showEndMarker;
  final void Function(FuelStationModel station)? onFuelStationTap;
  final MapController? mapController;

  const EcoPulseMap({
    super.key,
    required this.currentLocation,
    required this.routePoints,
    required this.fuelStations,
    this.showFuelStations = true,
    this.showEndMarker = true,
    this.onFuelStationTap,
    this.mapController,
  });

  LatLng get _initialCenter {
    if (currentLocation != null) {
      return LatLng(
        currentLocation!.latitude,
        currentLocation!.longitude,
      );
    }

    return const LatLng(
      AppConstants.pastoLatitude,
      AppConstants.pastoLongitude,
    );
  }

  List<LatLng> get _polylinePoints {
    return routePoints.map((point) {
      return LatLng(
        point.latitude,
        point.longitude,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      ..._buildRouteMarkers(),
      if (showFuelStations) ..._buildFuelStationMarkers(context),
      if (currentLocation != null) _buildCurrentLocationMarker(),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: AppConstants.defaultMapZoom,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ecopulse.app',
            ),
            if (_polylinePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    strokeWidth: 5,
                    color: const Color(0xFF1F8A4C),
                  ),
                ],
              ),
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black26,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                'Mapa base: OpenStreetMap. Los datos de estaciones y precios deben verificarse con fuentes oficiales antes de producción.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildRouteMarkers() {
    final routeMarkers = <Marker>[];

    if (routePoints.isNotEmpty) {
      final startPoint = routePoints.first;

      routeMarkers.add(
        Marker(
          point: LatLng(
            startPoint.latitude,
            startPoint.longitude,
          ),
          width: 46,
          height: 46,
          child: const _MapMarkerBubble(
            icon: Icons.flag_rounded,
            color: Color(0xFF1565C0),
            tooltip: 'Inicio',
          ),
        ),
      );
    }

    if (showEndMarker && routePoints.length >= 2) {
      final endPoint = routePoints.last;

      routeMarkers.add(
        Marker(
          point: LatLng(
            endPoint.latitude,
            endPoint.longitude,
          ),
          width: 46,
          height: 46,
          child: const _MapMarkerBubble(
            icon: Icons.outlined_flag_rounded,
            color: Color(0xFFD84315),
            tooltip: 'Último punto',
          ),
        ),
      );
    }

    return routeMarkers;
  }

  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: LatLng(
        currentLocation!.latitude,
        currentLocation!.longitude,
      ),
      width: 54,
      height: 54,
      child: const _MapMarkerBubble(
        icon: Icons.my_location_rounded,
        color: Color(0xFF1F8A4C),
        tooltip: 'Ubicación actual',
      ),
    );
  }

  List<Marker> _buildFuelStationMarkers(BuildContext context) {
    return fuelStations.map((station) {
      return Marker(
        point: LatLng(
          station.latitude,
          station.longitude,
        ),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            onFuelStationTap?.call(station);
          },
          child: const _MapMarkerBubble(
            icon: Icons.local_gas_station_rounded,
            color: Color(0xFF6D4C41),
            tooltip: 'Estación',
          ),
        ),
      );
    }).toList();
  }
}

class _MapMarkerBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;

  const _MapMarkerBubble({
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black26,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}     