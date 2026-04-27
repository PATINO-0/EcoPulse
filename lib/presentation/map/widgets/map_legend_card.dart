import 'package:flutter/material.dart';

class MapLegendCard extends StatelessWidget {
  const MapLegendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          children: const [
            _LegendItem(
              color: Color(0xFF1F8A4C),
              label: 'Ubicación / ruta',
              icon: Icons.my_location_rounded,
            ),
            _LegendItem(
              color: Color(0xFF1565C0),
              label: 'Inicio',
              icon: Icons.flag_rounded,
            ),
            _LegendItem(
              color: Color(0xFFD84315),
              label: 'Último punto',
              icon: Icons.outlined_flag_rounded,
            ),
            _LegendItem(
              color: Color(0xFF6D4C41),
              label: 'Estación',
              icon: Icons.local_gas_station_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}