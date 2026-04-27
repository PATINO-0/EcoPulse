import 'package:ecopulse/data/models/maintenance_record_model.dart';
import 'package:ecopulse/data/repositories/maintenance_repository.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/services/maintenance/maintenance_recommendation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() {
    return _MaintenanceScreenState();
  }
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  late Future<List<MaintenanceRecordModel>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture =
        ref.read(maintenanceRepositoryProvider).getMaintenanceRecords();
  }

  Future<void> _refresh() async {
    setState(_loadRecords);
    await _recordsFuture;
  }

  Future<void> _createRecommendations() async {
    try {
      final selectedVehicle =
          await ref.read(vehicleRepositoryProvider).getSelectedVehicle();

      final recommendations = ref
          .read(maintenanceRecommendationServiceProvider)
          .buildDefaultRecommendations(
            vehicle: selectedVehicle,
          );

      await ref.read(maintenanceRepositoryProvider).createRecommendedRecords(
            vehicleId: selectedVehicle?.id,
            recommendations: recommendations,
          );

      setState(_loadRecords);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recomendaciones de mantenimiento creadas.'),
        ),
      );
    } catch (exception) {
      _showError(exception);
    }
  }

  Future<void> _markAsCompleted(MaintenanceRecordModel record) async {
    try {
      await ref.read(maintenanceRepositoryProvider).markAsCompleted(
            record: record,
          );

      setState(_loadRecords);
    } catch (exception) {
      _showError(exception);
    }
  }

  Future<void> _deleteRecord(MaintenanceRecordModel record) async {
    try {
      await ref.read(maintenanceRepositoryProvider).deleteRecord(
            recordId: record.id,
          );

      setState(_loadRecords);
    } catch (exception) {
      _showError(exception);
    }
  }

  void _showError(Object exception) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $exception'),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No registrada';
    }

    return DateFormat('dd/MM/yyyy', 'es_CO').format(value.toLocal());
  }

  Color _statusColor(MaintenanceRecordModel record) {
    if (record.isOverdue) {
      return Colors.red;
    }

    if (record.status == 'completed') {
      return Colors.green;
    }

    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        actions: [
          IconButton(
            onPressed: _createRecommendations,
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Crear recomendaciones',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<MaintenanceRecordModel>>(
            future: _recordsFuture,
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
                      'No fue posible cargar mantenimiento. Detalle: ${snapshot.error}',
                    ),
                  ],
                );
              }

              final records = snapshot.data ?? [];

              if (records.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Aún no tienes mantenimientos registrados. Presiona el ícono de estrellas para crear recomendaciones iniciales.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _createRecommendations,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Crear recomendaciones iniciales'),
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
                        'Estas recomendaciones son preventivas y no reemplazan una revisión mecánica profesional.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...records.map((record) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          record.isOverdue
                              ? Icons.warning_rounded
                              : Icons.build_rounded,
                          color: _statusColor(record),
                        ),
                        title: Text(record.maintenanceType),
                        subtitle: Text(
                          'Último: ${_formatDate(record.lastDoneAt)}\n'
                          'Próximo: ${_formatDate(record.nextDueAt)}\n'
                          '${record.notes ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'complete') {
                              _markAsCompleted(record);
                            }

                            if (value == 'delete') {
                              _deleteRecord(record);
                            }
                          },
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(
                                value: 'complete',
                                child: Text('Marcar completado'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ];
                          },
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