import 'package:ecopulse/data/models/fuel_station_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FuelStationInfoSheet extends StatelessWidget {
  final FuelStationModel station;

  const FuelStationInfoSheet({
    super.key,
    required this.station,
  });

  String _formatPrice(double? value) {
    if (value == null) {
      return 'No disponible';
    }

    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );

    return '${formatter.format(value)} COP/galón';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final sourceLabel = station.isOfficial
        ? 'Fuente marcada como oficial'
        : 'Dato de ejemplo o pendiente por verificar';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.local_gas_station_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    station.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Dirección: ${station.address ?? 'No disponible'}'),
            const SizedBox(height: 6),
            Text('Ciudad: ${station.city}, ${station.department}'),
            const SizedBox(height: 6),
            Text('Combustibles: ${station.fuelTypesText}'),
            const Divider(height: 28),
            const Text(
              'Precios registrados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Corriente: ${_formatPrice(station.priceRegular)}'),
            Text('Extra: ${_formatPrice(station.priceExtra)}'),
            Text('Diésel: ${_formatPrice(station.priceDiesel)}'),
            const Divider(height: 28),
            Text(sourceLabel),
            const SizedBox(height: 6),
            Text('Fuente: ${station.source}'),
            const SizedBox(height: 6),
            Text('Actualizado: ${_formatDate(station.updatedAt)}'),
            const SizedBox(height: 14),
            const Text(
              'Antes de usar esta información en producción, reemplaza los datos demo por información verificada desde una fuente oficial o administrativa.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}