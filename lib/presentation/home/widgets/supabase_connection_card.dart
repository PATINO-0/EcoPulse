import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';

class SupabaseConnectionCard extends StatelessWidget {
  const SupabaseConnectionCard({super.key});

  Future<List<dynamic>> _loadFuelPrices() async {
    try {
      final response = await SupabaseService.client
          .from('fuel_prices')
          .select(
            'city, department, fuel_type, price_per_gallon, source, is_official',
          )
          .limit(1);

      return response;
    } catch (_) {
      throw const _FriendlyNetworkException();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _SColors(isDark);

    return FutureBuilder<List<dynamic>>(
      future: _loadFuelPrices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _Card(
            c: c,
            child: Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Verificando conexión con EcoPulse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estamos validando el acceso a Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _Card(
            c: c,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.danger.withOpacity(0.22)),
                  ),
                  child: Icon(Icons.wifi_off_rounded, color: c.danger, size: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  'No se pudo conectar a Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revisa tu conexión a internet e inténtalo nuevamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return _Card(
            c: c,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.warning.withOpacity(0.22)),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: c.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Sin datos cargados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Supabase respondió correctamente, pero aún no hay precios de combustible registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final row = rows.first as Map<String, dynamic>;
        final isOfficial = row['is_official'] == true;

        return _Card(
          c: c,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.success.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.success.withOpacity(0.22)),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: c.success,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Conexión verificada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'EcoPulse puede consultar información disponible desde Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  _DataChip(
                    label: row['city']?.toString() ?? '—',
                    icon: Icons.location_city_rounded,
                    c: c,
                  ),
                  _DataChip(
                    label: '${row['fuel_type']} · ${row['price_per_gallon']} COP',
                    icon: Icons.local_gas_station_rounded,
                    c: c,
                  ),
                  _DataChip(
                    label: isOfficial ? 'Fuente oficial' : 'Dato de ejemplo',
                    icon: isOfficial
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    c: c,
                    color: isOfficial ? c.success : c.warning,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendlyNetworkException implements Exception {
  const _FriendlyNetworkException();
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.child});

  final _SColors c;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.label,
    required this.icon,
    required this.c,
    this.color,
  });

  final String label;
  final IconData icon;
  final _SColors c;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: col.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: col),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: col,
            ),
          ),
        ],
      ),
    );
  }
}

class _SColors {
  final bool isDark;
  const _SColors(this.isDark);

  Color get cardBg => isDark ? const Color(0xFF132033) : Colors.white;
  Color get border => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);
  Color get shadow => isDark
      ? Colors.black.withOpacity(0.26)
      : const Color(0xFF5F96B3).withOpacity(0.10);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary =>
      isDark ? const Color(0xFF9BB1C2) : const Color(0xFF5D7383);

  Color get primary => const Color(0xFF5F96B3);
  Color get success => const Color(0xFF57B65F);
  Color get warning => const Color(0xFFF4A261);
  Color get danger => const Color(0xFFE76F51);
}