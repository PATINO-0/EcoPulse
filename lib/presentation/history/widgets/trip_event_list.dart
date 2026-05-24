import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripEventList extends StatelessWidget {
  final List<DrivingEventModel> events;
  final MapColors colors;
  final bool showEventTime;

  const TripEventList({
    super.key,
    required this.events,
    required this.colors,
    this.showEventTime = false,
  });

  String _formatDateOnly(DateTime value) {
    return DateFormat('dd MMM yyyy', 'es_CO').format(value.toLocal());
  }

  String _formatDateTimeIfTrusted(DateTime value) {
    if (!showEventTime) {
      return _formatDateOnly(value);
    }

    return DateFormat('dd MMM yyyy, HH:mm', 'es_CO').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'No se registraron eventos de conducción ineficiente en este trayecto.',
          style: TextStyle(
            fontSize: 12.3,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final severityColor = _colorForSeverity(event.severity);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card.withOpacity(0.98),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: severityColor.withOpacity(0.20)),
                ),
                child: Icon(
                  _iconForEvent(event),
                  color: severityColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventTypeLabel,
                        style: TextStyle(
                          fontSize: 14.8,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.message,
                        style: TextStyle(
                          fontSize: 12.2,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _EventChip(
                            label: 'Severidad: ${event.severityLabel}',
                            color: severityColor,
                          ),
                          _EventChip(
                            label:
                                'Velocidad: ${event.speedKmh?.toStringAsFixed(1) ?? 'N/D'} km/h',
                            color: colors.primary,
                          ),
                          _EventChip(
                            label: _formatDateTimeIfTrusted(event.detectedAt),
                            color: colors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      return colors.danger;
    }

    if (severity == 'medium') {
      return colors.warning;
    }

    return colors.success;
  }
}

class _EventChip extends StatelessWidget {
  final String label;
  final Color color;

  const _EventChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.1,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}