import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripEventList extends StatelessWidget {
  final List<DrivingEventModel> events;

  const TripEventList({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No se registraron eventos de conducción ineficiente en este trayecto.',
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        return Card(
          child: ListTile(
            leading: Icon(
              _iconForEvent(event),
              color: _colorForSeverity(event.severity),
            ),
            title: Text(event.eventTypeLabel),
            subtitle: Text(
              '${event.message}\n'
              'Severidad: ${event.severityLabel} • '
              'Velocidad: ${event.speedKmh?.toStringAsFixed(1) ?? 'N/D'} km/h • '
              '${DateFormat('HH:mm', 'es_CO').format(event.detectedAt.toLocal())}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForEvent(DrivingEventModel event) {
    if (event.isAggressiveAcceleration) {
      return Icons.trending_up_rounded;
    }

    if (event.isHardBraking) {
      return Icons.warning_rounded;
    }

    return Icons.eco_rounded;
  }

  Color _colorForSeverity(String severity) {
    if (severity == 'high') {
      return Colors.red;
    }

    if (severity == 'medium') {
      return Colors.orange;
    }

    return Colors.green;
  }
}