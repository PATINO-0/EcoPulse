import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/data/repositories/fuel_price_repository.dart';
import 'package:ecopulse/services/fuel/fuel_market_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FuelPricesScreen extends ConsumerStatefulWidget {
  const FuelPricesScreen({super.key});

  @override
  ConsumerState<FuelPricesScreen> createState() {
    return _FuelPricesScreenState();
  }
}

class _FuelPricesScreenState extends ConsumerState<FuelPricesScreen> {
  late Future<List<FuelPriceModel>> _pricesFuture;

  @override
  void initState() {
    super.initState();
    _pricesFuture = _loadPrices();
  }

  Future<List<FuelPriceModel>> _loadPrices({
    bool forcePrices = false,
  }) async {
    await ref.read(fuelMarketSyncServiceProvider).syncDailyMarketDataIfNeeded(
          forcePrices: forcePrices,
          forceStations: false,
        );

    return ref.read(fuelPriceRepositoryProvider).getFuelPricesForDefaultCity();
  }

  Future<void> _refresh() async {
    setState(() {
      _pricesFuture = _loadPrices(forcePrices: true);
    });

    await _pricesFuture;
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd/MM/yyyy', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Precios de combustible'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<FuelPriceModel>>(
            future: _pricesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No fue posible sincronizar los precios. Detalle: ${snapshot.error}',
                        ),
                      ),
                    ),
                  ],
                );
              }

              final prices = snapshot.data ?? [];

              if (prices.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: const [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No hay precios registrados para Pasto, Nariño. Verifica la API key, la conexión a internet y la tabla fuel_prices en Supabase.',
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'EcoPulse sincroniza una vez al día los precios de gasolina corriente y diésel/ACPM. Estos valores se usan para calcular el costo monetario estimado de cada trayecto.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...prices.map((price) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          price.isOfficial
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          color: price.isOfficial ? Colors.green : Colors.orange,
                        ),
                        title: Text(price.displayFuelType),
                        subtitle: Text(
                          '${price.city}, ${price.department}\n'
                          'Vigente desde: ${_formatDate(price.validFrom)}\n'
                          'Sincronizado: ${_formatDate(price.syncDate ?? price.updatedAt)}\n'
                          'Fuente: ${price.source}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${_formatMoney(price.pricePerGallon)}\nCOP/galón',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}