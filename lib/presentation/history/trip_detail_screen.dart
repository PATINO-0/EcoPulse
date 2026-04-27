import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/data/repositories/driving_event_repository.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:ecopulse/presentation/history/widgets/trip_event_list.dart';
import 'package:ecopulse/presentation/history/widgets/trip_metric_card.dart';
import 'package:ecopulse/presentation/history/widgets/trip_route_map_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  Future<_TripDetailData> _loadData(WidgetRef ref) async {
    final tripRepository = ref.read(tripRepositoryProvider);
    final eventRepository = ref.read(drivingEventRepositoryProvider);

    final trip = await tripRepository.getTripById(
      tripId: tripId,
    );

    final points = await tripRepository.getTripPoints(
      tripId: tripId,
    );

    final events = await eventRepository.getEventsByTripId(
      tripId: tripId,
    );

    return _TripDetailData(
      trip: trip,
      points: points,
      events: events,
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(value.toLocal());
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatMoney(double? value) {
    if (value == null) {
      return 'No disponible';
    }

    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del trayecto'),
      ),
      body: SafeArea(
        child: FutureBuilder<_TripDetailData>(
          future: _loadData(ref),
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
                  'No fue posible cargar el detalle. Detalle: ${snapshot.error}',
                ),
              );
            }

            final data = snapshot.data!;
            final trip = data.trip;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Trayecto del ${_formatDate(trip.startedAt)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Finalizado: ${_formatDate(trip.endedAt)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TripMetricCard(
                        title: 'Distancia',
                        value: '${trip.distanceKm.toStringAsFixed(2)} km',
                        icon: Icons.route_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TripMetricCard(
                        title: 'Duración',
                        value: _formatDuration(trip.durationSeconds),
                        icon: Icons.timer_rounded,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TripMetricCard(
                        title: 'Consumo',
                        value:
                            '${trip.estimatedFuelConsumedGallons.toStringAsFixed(4)} gal',
                        icon: Icons.local_gas_station_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TripMetricCard(
                        title: 'Litros',
                        value:
                            '${trip.estimatedFuelConsumedLiters.toStringAsFixed(3)} L',
                        icon: Icons.opacity_rounded,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TripMetricCard(
                        title: 'Costo',
                        value: _formatMoney(trip.estimatedCostCop),
                        icon: Icons.payments_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TripMetricCard(
                        title: 'Score',
                        value: trip.ecoScore?.toStringAsFixed(0) ?? 'N/D',
                        icon: Icons.energy_savings_leaf_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Rendimiento estimado:\n'
                      '• ${trip.estimatedKmPerGallon?.toStringAsFixed(2) ?? 'N/D'} km/galón\n'
                      '• ${trip.estimatedLitersPer100Km?.toStringAsFixed(2) ?? 'N/D'} L/100 km\n\n'
                      'Costo:\n'
                      '• Precio por galón: ${_formatMoney(trip.fuelPricePerGallon)}\n'
                      '• Costo por km: ${_formatMoney(trip.costPerKmCop)}\n'
                      '• Ahorro posible por eventos evitables: ${_formatMoney(trip.estimatedSavingsCop)}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Fuente del precio:\n'
                      '${trip.fuelPriceSource ?? 'No disponible'}\n\n'
                      'Dato marcado como oficial: ${trip.fuelPriceIsOfficial ? 'Sí' : 'No'}\n'
                      'Método: ${trip.estimationMethod}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ruta del trayecto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TripRouteMapCard(
                  points: data.points,
                ),
                const SizedBox(height: 18),
                Text(
                  'Eventos de conducción',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TripEventList(
                  events: data.events,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripDetailData {
  final TripModel trip;
  final List<TripPointModel> points;
  final List<DrivingEventModel> events;

  const _TripDetailData({
    required this.trip,
    required this.points,
    required this.events,
  });
}