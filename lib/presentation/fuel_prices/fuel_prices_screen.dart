import 'package:ecopulse/data/models/fuel_price_model.dart';
import 'package:ecopulse/data/repositories/fuel_price_repository.dart';
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
    _loadPrices();
  }

  void _loadPrices() {
    _pricesFuture =
        ref.read(fuelPriceRepositoryProvider).getFuelPricesForDefaultCity();
  }

  Future<void> _refresh() async {
    setState(_loadPrices);
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
                    Text(
                      'No fue posible cargar los precios. Detalle: ${snapshot.error}',
                    ),
                  ],
                );
              }

              final prices = snapshot.data ?? [];

              if (prices.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(22),
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No hay precios registrados para Pasto, Nariño. Carga precios en Supabase desde una fuente oficial o administrativa verificada.',
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
                        'EcoPulse muestra los precios guardados en Supabase. Si el dato no está marcado como oficial, úsalo solo como referencia de prueba.',
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
                        title: Text(price.fuelType),
                        subtitle: Text(
                          '${price.city}, ${price.department}\n'
                          'Vigente desde: ${_formatDate(price.validFrom)}\n'
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