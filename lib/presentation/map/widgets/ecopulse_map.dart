import 'dart:ui' as ui;

import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EcoPulseMap extends StatefulWidget {
  final LocationSampleModel? currentLocation;
  final List<LocationSampleModel> routePoints;
  final List<FuelStationModel> fuelStations;
  final bool showFuelStations;
  final bool showEndMarker;
  final void Function(FuelStationModel station)? onFuelStationTap;
  final MapController? mapController;
  final bool isDark;

  const EcoPulseMap({
    super.key,
    required this.currentLocation,
    required this.routePoints,
    required this.fuelStations,
    this.showFuelStations = true,
    this.showEndMarker = true,
    this.onFuelStationTap,
    this.mapController,
    this.isDark = false,
  });

  @override
  State<EcoPulseMap> createState() => _EcoPulseMapState();
}

class _EcoPulseMapState extends State<EcoPulseMap> {
  FuelStationModel? _selectedStation;

  LatLng get _initialCenter {
    if (widget.currentLocation != null) {
      return LatLng(
        widget.currentLocation!.latitude,
        widget.currentLocation!.longitude,
      );
    }

    return const LatLng(
      AppConstants.pastoLatitude,
      AppConstants.pastoLongitude,
    );
  }

  List<LatLng> get _polylinePoints {
    return widget.routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  String get _tileUrl {
    if (widget.isDark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
    }

    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MapColors(widget.isDark);

    final markers = <Marker>[
      ..._buildRouteMarkers(colors),
      if (widget.showFuelStations) ..._buildFuelMarkers(colors),
      if (widget.currentLocation != null) _buildLocationMarker(colors),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: AppConstants.defaultMapZoom,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              subdomains: widget.isDark ? const ['a', 'b', 'c'] : const [],
              userAgentPackageName: 'com.ecopulse.app',
            ),
            if (_polylinePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    strokeWidth: 5.5,
                    color: colors.accent,
                    borderStrokeWidth: 1.5,
                    borderColor: colors.accent.withOpacity(0.30),
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withOpacity(0.88),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 9.5,
                color: colors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildLocationMarker(MapColors colors) {
    return Marker(
      point: LatLng(
        widget.currentLocation!.latitude,
        widget.currentLocation!.longitude,
      ),
      width: 56,
      height: 56,
      child: _AnimatedLocationMarker(colors: colors),
    );
  }

  List<Marker> _buildRouteMarkers(MapColors colors) {
    final result = <Marker>[];

    if (widget.routePoints.isNotEmpty) {
      final start = widget.routePoints.first;

      result.add(
        Marker(
          point: LatLng(start.latitude, start.longitude),
          width: 48,
          height: 56,
          child: _PinMarker(
            icon: Icons.flag_rounded,
            color: colors.primary,
            label: 'Inicio',
          ),
        ),
      );
    }

    if (widget.showEndMarker && widget.routePoints.length >= 2) {
      final end = widget.routePoints.last;

      result.add(
        Marker(
          point: LatLng(end.latitude, end.longitude),
          width: 48,
          height: 56,
          child: _PinMarker(
            icon: Icons.sports_score_rounded,
            color: colors.danger,
            label: 'Último punto',
          ),
        ),
      );
    }

    return result;
  }

  List<Marker> _buildFuelMarkers(MapColors colors) {
    return widget.fuelStations.map((station) {
      final isSelected = _selectedStation?.id == station.id;

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: isSelected ? 58 : 48,
        height: isSelected ? 58 : 48,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedStation = station);
            widget.onFuelStationTap?.call(station);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: isSelected ? 54 : 44,
            height: isSelected ? 54 : 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.warning
                  : colors.warning.withOpacity(0.88),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.warning.withOpacity(isSelected ? 0.45 : 0.25),
                  blurRadius: isSelected ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.local_gas_station_rounded,
              color: Colors.white,
              size: isSelected ? 26 : 22,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _AnimatedLocationMarker extends StatefulWidget {
  const _AnimatedLocationMarker({required this.colors});

  final MapColors colors;

  @override
  State<_AnimatedLocationMarker> createState() =>
      _AnimatedLocationMarkerState();
}

class _AnimatedLocationMarkerState extends State<_AnimatedLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final scale = 1.0 + _ctrl.value * 0.7;
        final opacity = 1.0 - _ctrl.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.colors.accent.withOpacity(opacity * 0.22),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.colors.accent,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: widget.colors.accent.withOpacity(0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: _PinTailPainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}