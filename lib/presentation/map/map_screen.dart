import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/repositories/fuel_station_repository.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:ecopulse/presentation/map/widgets/fuel_station_info_sheet.dart';
import 'package:ecopulse/presentation/map/widgets/map_legend_card.dart';
import 'package:ecopulse/services/trip/trip_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  late Future<List<FuelStationModel>> _stationsFuture;
  bool _showFuelStations = true;

  @override
  void initState() {
    super.initState();
    _stationsFuture =
        ref.read(fuelStationRepositoryProvider).getStationsForDefaultCity();
  }

  void _showStationInfo(FuelStationModel station) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) {
        return FuelStationInfoSheet(
          station: station,
        );
      },
    );
  }

  void _centerOnCurrentLocation() {
    final location = ref.read(tripSessionServiceProvider).currentLocation;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todavía no hay una ubicación GPS disponible.'),
        ),
      );
      return;
    }

    _mapController.move(
      LatLng(
        location.latitude,
        location.longitude,
      ),
      16,
    );
  }

  Future<void> _reloadStations() async {
    setState(() {
      _stationsFuture =
          ref.read(fuelStationRepositoryProvider).getStationsForDefaultCity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripSessionServiceProvider);
    final tripController = ref.read(tripSessionServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa en tiempo real'),
        actions: [
          IconButton(
            onPressed: _centerOnCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Centrar ubicación',
          ),
          IconButton(
            onPressed: _reloadStations,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar estaciones',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<FuelStationModel>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            final stations = snapshot.data ?? [];

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      EcoPulseMap(
                        mapController: _mapController,
                        currentLocation: tripState.currentLocation,
                        routePoints: tripState.routePoints,
                        fuelStations: stations,
                        showFuelStations: _showFuelStations,
                        onFuelStationTap: _showStationInfo,
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: _LiveMapStatusCard(
                          isTracking: tripState.isTracking,
                          speedKmh: tripState.currentSpeedKmh,
                          distanceKm: tripState.distanceKm,
                          points: tripState.routePoints.length,
                          statusMessage: tripState.statusMessage,
                        ),
                      ),
                    ],
                  ),
                ),
                const MapLegendCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFuelStations = !_showFuelStations;
                            });
                          },
                          icon: Icon(
                            _showFuelStations
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          label: Text(
                            _showFuelStations
                                ? 'Ocultar estaciones'
                                : 'Mostrar estaciones',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: tripState.isTracking
                            ? FilledButton.icon(
                                onPressed: tripState.isSaving
                                    ? null
                                    : tripController.finishManualTrip,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Finalizar'),
                              )
                            : FilledButton.icon(
                                onPressed: tripState.isSaving
                                    ? null
                                    : tripController.startManualTrip,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Iniciar'),
                              ),
                      ),
                    ],
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

class _LiveMapStatusCard extends StatelessWidget {
  final bool isTracking;
  final double speedKmh;
  final double distanceKm;
  final int points;
  final String statusMessage;

  const _LiveMapStatusCard({
    required this.isTracking,
    required this.speedKmh,
    required this.distanceKm,
    required this.points,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isTracking
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isTracking ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTracking ? 'Trayecto activo' : 'Trayecto inactivo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${speedKmh.toStringAsFixed(1)} km/h'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Distancia: ${distanceKm.toStringAsFixed(2)} km'),
                ),
                Text('Puntos: $points'),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                statusMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}