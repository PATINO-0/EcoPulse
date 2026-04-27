class MaintenanceRecordModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String maintenanceType;
  final DateTime? lastDoneAt;
  final DateTime? nextDueAt;
  final String? notes;
  final String status;
  final DateTime createdAt;

  const MaintenanceRecordModel({
    required this.id,
    required this.userId,
    required this.maintenanceType,
    required this.status,
    required this.createdAt,
    this.vehicleId,
    this.lastDoneAt,
    this.nextDueAt,
    this.notes,
  });

  factory MaintenanceRecordModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecordModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      vehicleId: map['vehicle_id'] as String?,
      maintenanceType: map['maintenance_type'] as String,
      lastDoneAt: map['last_done_at'] == null
          ? null
          : DateTime.tryParse(map['last_done_at'].toString()),
      nextDueAt: map['next_due_at'] == null
          ? null
          : DateTime.tryParse(map['next_due_at'].toString()),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  bool get isOverdue {
    if (nextDueAt == null) {
      return false;
    }

    final today = DateTime.now();

    return nextDueAt!.isBefore(
      DateTime(today.year, today.month, today.day),
    );
  }

  String get statusLabel {
    if (isOverdue && status != 'completed') {
      return 'Vencido';
    }

    switch (status) {
      case 'completed':
        return 'Completado';
      case 'pending':
        return 'Pendiente';
      case 'overdue':
        return 'Vencido';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}