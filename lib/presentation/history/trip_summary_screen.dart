import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_point_model.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:ecopulse/presentation/history/widgets/trip_metric_card.dart';
import 'package:ecopulse/presentation/history/widgets/trip_route_map_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TripSummaryScreen extends ConsumerWidget {
  final String tripId;

  const TripSummaryScreen({
    super.key,
    required this.tripId,
  });

  Future<_TripSummaryData> _loadData(WidgetRef ref) async {
    final repository = ref.read(tripRepositoryProvider);

    final trip = await repository.getTripById(
      tripId: tripId,
    );

    final points = await repository.getTripPoints(
      tripId: tripId,
    );

    return _TripSummaryData(
      trip: trip,
      points: points,
    );
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
        title: const Text('Resumen del trayecto'),
      ),
      body: SafeArea(
        child: FutureBuilder<_TripSummaryData>(
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
                  'No fue posible cargar el resumen. Detalle: ${snapshot.error}',
                ),
              );
            }

            final data = snapshot.data!;
            final trip = data.trip;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'En este trayecto recorriste ${trip.distanceKm.toStringAsFixed(2)} km. '
                      'Tu consumo estimado fue de ${trip.estimatedFuelConsumedGallons.toStringAsFixed(4)} galones '
                      'y el costo estimado fue de ${_formatMoney(trip.estimatedCostCop)}.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                        title: 'Galones',
                        value:
                            trip.estimatedFuelConsumedGallons.toStringAsFixed(4),
                        icon: Icons.local_gas_station_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TripMetricCard(
                        title: 'Litros',
                        value:
                            trip.estimatedFuelConsumedLiters.toStringAsFixed(3),
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
                        title: 'COP/km',
                        value: _formatMoney(trip.costPerKmCop),
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TripMetricCard(
                        title: 'Eco score',
                        value: trip.ecoScore?.toStringAsFixed(0) ?? 'N/D',
                        icon: Icons.energy_savings_leaf_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TripMetricCard(
                        title: 'Ahorro posible',
                        value: _formatMoney(trip.estimatedSavingsCop),
                        icon: Icons.savings_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Eventos detectados:\n'
                      '• Aceleraciones bruscas: ${trip.aggressiveAccelerationEvents}\n'
                      '• Frenadas fuertes: ${trip.hardBrakingEvents}\n'
                      '• Eventos irregulares: ${trip.irregularDrivingEvents}\n'
                      '• Total: ${trip.totalEvents}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Precio usado por galón: ${_formatMoney(trip.fuelPricePerGallon)}\n'
                      'Fuente: ${trip.fuelPriceSource ?? 'No disponible'}\n'
                      'Marcado como oficial: ${trip.fuelPriceIsOfficial ? 'Sí' : 'No'}\n'
                      'Método de estimación: ${trip.estimationMethod}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TripRouteMapCard(
                  points: data.points,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nota técnica: el consumo es una estimación aproximada basada en GPS, sensores, datos del vehículo y reglas físico-matemáticas. No reemplaza datos OBD-II ni mediciones directas de la ECU.',
                  style: TextStyle(
                    color: Colors.black54,
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

class _TripSummaryData {
  final TripModel trip;
  final List<TripPointModel> points;

  const _TripSummaryData({
    required this.trip,
    required this.points,
  });
}