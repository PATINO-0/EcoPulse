import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/models/trip_model.dart';
import 'package:ecopulse/data/models/trip_sort_option.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() {
    return _TripHistoryScreenState();
  }
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  TripSortOption _sortOption = TripSortOption.newest;

  late Future<List<TripModel>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    _tripsFuture = ref.read(tripRepositoryProvider).getUserTrips(
          sortOption: _sortOption,
        );
  }

  void _changeSortOption(TripSortOption? option) {
    if (option == null) {
      return;
    }

    setState(() {
      _sortOption = option;
      _loadTrips();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTrips();
    });

    await _tripsFuture;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(date.toLocal());
  }

  String _formatMoney(double? value) {
    if (value == null) {
      return 'Costo no disponible';
    }

    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de trayectos'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<TripSortOption>(
                value: _sortOption,
                decoration: const InputDecoration(
                  labelText: 'Ordenar por',
                ),
                items: TripSortOption.values.map((option) {
                  return DropdownMenuItem<TripSortOption>(
                    value: option,
                    child: Text(option.label),
                  );
                }).toList(),
                onChanged: _changeSortOption,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TripModel>>(
                future: _tripsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No fue posible cargar el historial. Detalle: ${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final trips = snapshot.data ?? [];

                  if (trips.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Aún no tienes trayectos finalizados. Inicia y finaliza un trayecto para verlo aquí.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: trips.map((trip) {
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              trip.ecoScore?.toStringAsFixed(0) ?? 'N/D',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(_formatDate(trip.startedAt)),
                          subtitle: Text(
                            '${trip.distanceKm.toStringAsFixed(2)} km • '
                            '${trip.estimatedFuelConsumedGallons.toStringAsFixed(4)} gal • '
                            '${_formatMoney(trip.estimatedCostCop)}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            context.push(AppRoutes.tripDetailPath(trip.id));
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}