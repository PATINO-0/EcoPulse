import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:ecopulse/data/repositories/fuel_station_repository.dart';
import 'package:ecopulse/presentation/map/widgets/ecopulse_map.dart';
import 'package:ecopulse/presentation/map/widgets/fuel_station_info_sheet.dart';
import 'package:ecopulse/presentation/map/widgets/map_legend_card.dart';
import 'package:ecopulse/services/fuel/fuel_market_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuelStationsMapScreen extends ConsumerStatefulWidget {
  const FuelStationsMapScreen({super.key});

  @override
  ConsumerState<FuelStationsMapScreen> createState() {
    return _FuelStationsMapScreenState();
  }
}

class _FuelStationsMapScreenState extends ConsumerState<FuelStationsMapScreen> {
  late Future<List<FuelStationModel>> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _loadStations();
  }

  Future<List<FuelStationModel>> _loadStations({
    bool forcePrices = false,
    bool forceStations = false,
  }) async {
    await ref.read(fuelMarketSyncServiceProvider).syncDailyMarketDataIfNeeded(
          forcePrices: forcePrices,
          forceStations: forceStations,
        );

    return ref.read(fuelStationRepositoryProvider).getStationsForDefaultCity();
  }

  Future<void> _reloadStations() async {
    setState(() {
      _stationsFuture = _loadStations(
        forcePrices: true,
        forceStations: false,
      );
    });

    await _stationsFuture;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones de gasolina'),
        actions: [
          IconButton(
            onPressed: _reloadStations,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar precios',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<FuelStationModel>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'No fue posible cargar las estaciones. Detalle: ${snapshot.error}',
                ),
              );
            }

            final stations = snapshot.data ?? [];

            if (stations.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                  'No hay estaciones registradas para Pasto, Nariño. Verifica la API key, la conexión a internet y la tabla fuel_stations en Supabase.',
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: EcoPulseMap(
                    currentLocation: null,
                    routePoints: const [],
                    fuelStations: stations,
                    showFuelStations: true,
                    showEndMarker: false,
                    onFuelStationTap: _showStationInfo,
                  ),
                ),
                const MapLegendCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Mostrando ${stations.length} estaciones para ${AppConstants.appName}. Las ubicaciones se cargan una sola vez y los precios se actualizan diariamente.',
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