import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';

class SupabaseConnectionCard extends StatelessWidget {
  const SupabaseConnectionCard({super.key});

  Future<List<dynamic>> _loadFuelPrices() async {
    // Consulta mínima para validar conexión, RLS y lectura de datos públicos.
    final response = await SupabaseService.client
        .from('fuel_prices')
        .select('city, department, fuel_type, price_per_gallon, source, is_official')
        .limit(1);

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _loadFuelPrices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('Verificando conexión con Supabase...'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No se pudo verificar Supabase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisa el archivo .env, las tablas SQL, las políticas RLS y la conexión a internet.\n\nDetalle técnico: ${snapshot.error}',
                  ),
                ],
              ),
            ),
          );
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Supabase respondió correctamente, pero no hay precios de combustible cargados. Ejecuta supabase/seed.sql.',
              ),
            ),
          );
        }

        final firstRow = rows.first as Map<String, dynamic>;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conexión con Supabase verificada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ciudad: ${firstRow['city']}',
                ),
                Text(
                  'Departamento: ${firstRow['department']}',
                ),
                Text(
                  'Combustible: ${firstRow['fuel_type']}',
                ),
                Text(
                  'Precio cargado: ${firstRow['price_per_gallon']} COP',
                ),
                const SizedBox(height: 8),
                Text(
                  firstRow['is_official'] == true
                      ? 'Fuente marcada como oficial: ${firstRow['source']}'
                      : 'Dato de ejemplo, no oficial: ${firstRow['source']}',
                  style: TextStyle(
                    color: firstRow['is_official'] == true
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}