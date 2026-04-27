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
        ? 'Ubicación marcada como oficial'
        : 'Ubicación cargada por fuente externa o IA';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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
                'Precios de referencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Gasolina corriente: ${_formatPrice(station.priceRegular)}'),
              Text('Diésel / ACPM: ${_formatPrice(station.priceDiesel)}'),
              if (station.priceExtra != null)
                Text('Extra: ${_formatPrice(station.priceExtra)}'),
              const Divider(height: 28),
              Text(sourceLabel),
              const SizedBox(height: 6),
              Text('Fuente ubicación: ${station.locationSource ?? station.source}'),
              const SizedBox(height: 6),
              Text('Fuente precio: ${station.priceSource ?? 'No disponible'}'),
              const SizedBox(height: 6),
              Text('Precio actualizado: ${_formatDate(station.priceUpdatedAt)}'),
              const SizedBox(height: 14),
              const Text(
                'La ubicación de la estación se carga una sola vez. Los precios se actualizan diariamente y se usan como referencia para los cálculos monetarios de EcoPulse.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}