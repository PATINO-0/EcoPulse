import 'dart:async';

import 'package:ecopulse/data/models/maintenance_record_model.dart';
import 'package:ecopulse/data/repositories/maintenance_repository.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/services/maintenance/maintenance_recommendation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isGenerating = false;
  bool? _manualDark;
  String? _lastCompletedId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture =
        ref.read(maintenanceRepositoryProvider).getMaintenanceRecords();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(_loadRecords);
    await _recordsFuture;
  }

  Future<void> _createRecommendations() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

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
        SnackBar(
          content: const Text('Recomendaciones de mantenimiento creadas.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (exception) {
      _showError(exception);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _markAsCompleted(MaintenanceRecordModel record) async {
    try {
      HapticFeedback.mediumImpact();

      await ref.read(maintenanceRepositoryProvider).markAsCompleted(
            record: record,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastCompletedId = record.id;
        _loadRecords();
      });

      _showCompletionCelebration(record);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _lastCompletedId = null;
        });
      });
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

  void _showCompletionCelebration(MaintenanceRecordModel record) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return _MaintenanceSuccessOverlay(
          title: 'Mantenimiento completado',
          subtitle: record.maintenanceType,
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );

    Timer(const Duration(milliseconds: 1150), () {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  void _showError(Object exception) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $exception'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No registrada';
    }

    return DateFormat('dd/MM/yyyy', 'es_CO').format(value.toLocal());
  }

  Color _statusColor(MapColors colors, MaintenanceRecordModel record) {
    if (record.isOverdue) {
      return colors.danger;
    }

    if (record.status == 'completed') {
      return colors.success;
    }

    return colors.warning;
  }

  String _statusLabel(MaintenanceRecordModel record) {
    if (record.status == 'completed') {
      return 'Completado';
    }

    if (record.isOverdue) {
      return 'Vencido';
    }

    return 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: colors.primary,
          child: FutureBuilder<List<MaintenanceRecordModel>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _MaintenanceLoadingView(colors: colors);
              }

              if (snapshot.hasError) {
                return _MaintenanceStatusView(
                  colors: colors,
                  icon: Icons.car_repair_rounded,
                  accent: colors.danger,
                  title: 'No fue posible cargar el mantenimiento',
                  message: 'Detalle: ${snapshot.error}',
                  actionLabel: 'Reintentar',
                  onPressed: _refresh,
                );
              }

              final records = snapshot.data ?? [];
              final pendingRecords = records
                  .where((record) => record.status != 'completed')
                  .toList();
              final completedRecords = records
                  .where((record) => record.status == 'completed')
                  .toList();

              final width = MediaQuery.of(context).size.width;
              final isTablet = width >= 760;
              final isDesktop = width >= 1140;
              final horizontalPadding = isDesktop
                  ? 30.0
                  : isTablet
                      ? 24.0
                      : 18.0;

              if (records.isEmpty) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          14,
                          horizontalPadding,
                          14,
                        ),
                        child: _MaintenanceHeader(
                          colors: colors,
                          isDark: isDark,
                          isGenerating: _isGenerating,
                          onBack: () => Navigator.of(context).maybePop(),
                          onToggleTheme: _toggleTheme,
                          onGenerate: _createRecommendations,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          14,
                        ),
                        child: _MaintenanceHeroCard(
                          colors: colors,
                          pendingCount: 0,
                          completedCount: 0,
                          overdueCount: 0,
                          isWide: isTablet,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          22,
                        ),
                        child: _MaintenanceEmptyState(
                          colors: colors,
                          isGenerating: _isGenerating,
                          onGenerate: _createRecommendations,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final overdueCount =
                  pendingRecords.where((record) => record.isOverdue).length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        14,
                      ),
                      child: _MaintenanceHeader(
                        colors: colors,
                        isDark: isDark,
                        isGenerating: _isGenerating,
                        onBack: () => Navigator.of(context).maybePop(),
                        onToggleTheme: _toggleTheme,
                        onGenerate: _createRecommendations,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        14,
                      ),
                      child: _MaintenanceHeroCard(
                        colors: colors,
                        pendingCount: pendingRecords.length,
                        completedCount: completedRecords.length,
                        overdueCount: overdueCount,
                        isWide: isTablet,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        14,
                      ),
                      child: _MaintenanceNoticeCard(colors: colors),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        12,
                      ),
                      child: _MaintenanceSectionHeader(
                        colors: colors,
                        title: 'Pendientes',
                        subtitle:
                            'Organiza primero los mantenimientos activos y próximos.',
                        accent: colors.warning,
                        icon: Icons.schedule_rounded,
                        count: pendingRecords.length,
                      ),
                    ),
                  ),
                  if (pendingRecords.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          16,
                        ),
                        child: _EmptySectionCard(
                          colors: colors,
                          title: 'Nada pendiente',
                          message:
                              'Todos los mantenimientos registrados ya fueron completados.',
                          accent: colors.success,
                          icon: Icons.verified_rounded,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        18,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = pendingRecords[index];
                            return _MaintenanceCard(
                              colors: colors,
                              record: record,
                              statusColor: _statusColor(colors, record),
                              statusLabel: _statusLabel(record),
                              lastCompletedId: _lastCompletedId,
                              formatDate: _formatDate,
                              onComplete: () => _markAsCompleted(record),
                              onDelete: () => _deleteRecord(record),
                            );
                          },
                          childCount: pendingRecords.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        12,
                      ),
                      child: _MaintenanceSectionHeader(
                        colors: colors,
                        title: 'Completados',
                        subtitle:
                            'Consulta el historial de tareas ya realizadas por tu vehículo.',
                        accent: colors.success,
                        icon: Icons.check_circle_rounded,
                        count: completedRecords.length,
                      ),
                    ),
                  ),
                  if (completedRecords.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          18,
                        ),
                        child: _EmptySectionCard(
                          colors: colors,
                          title: 'Sin completados todavía',
                          message:
                              'Cuando marques un mantenimiento como completado aparecerá aquí.',
                          accent: colors.primary,
                          icon: Icons.history_toggle_off_rounded,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = completedRecords[index];
                            return _CompletedMaintenanceCard(
                              colors: colors,
                              record: record,
                              formatDate: _formatDate,
                              onDelete: () => _deleteRecord(record),
                            );
                          },
                          childCount: completedRecords.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenanceHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isGenerating;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onGenerate;

  const _MaintenanceHeader({
    required this.colors,
    required this.isDark,
    required this.isGenerating,
    required this.onBack,
    required this.onToggleTheme,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 560;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _CircleAction(
                  icon: Icons.arrow_back_rounded,
                  color: colors.primary,
                  bg: colors.chip,
                  border: colors.chipBorder,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mantenimiento',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mantén tu vehículo organizado con recordatorios preventivos y un historial más claro.',
                style: TextStyle(
                  fontSize: 12.2,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeaderActionButton(
                    colors: colors,
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark ? 'Modo claro' : 'Modo oscuro',
                    color: isDark ? colors.warning : colors.primary,
                    onTap: onToggleTheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderActionButton(
                    colors: colors,
                    icon: isGenerating
                        ? Icons.hourglass_top_rounded
                        : Icons.auto_awesome_rounded,
                    label: isGenerating ? 'Creando' : 'Recomendar',
                    color: isGenerating ? colors.warning : colors.accent,
                    onTap: onGenerate,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleAction(
            icon: Icons.arrow_back_rounded,
            color: colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantenimiento',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Mantén tu vehículo organizado con recordatorios preventivos y un historial más claro.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: isDark ? colors.warning : colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: isGenerating
                ? Icons.hourglass_top_rounded
                : Icons.auto_awesome_rounded,
            color: isGenerating ? colors.warning : colors.accent,
            bg: (isGenerating ? colors.warning : colors.accent).withOpacity(0.12),
            border:
                (isGenerating ? colors.warning : colors.accent).withOpacity(0.24),
            onTap: onGenerate,
          ),
        ],
      ),
    );
  }
}

class _MaintenanceHeroCard extends StatelessWidget {
  final MapColors colors;
  final int pendingCount;
  final int completedCount;
  final int overdueCount;
  final bool isWide;

  const _MaintenanceHeroCard({
    required this.colors,
    required this.pendingCount,
    required this.completedCount,
    required this.overdueCount,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                const _HeroMaintenanceIcon(),
                const SizedBox(width: 18),
                Expanded(
                  child: _HeroMaintenanceText(
                    pendingCount: pendingCount,
                    overdueCount: overdueCount,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: _HeroMaintenanceMetrics(
                    completedCount: completedCount,
                    overdueCount: overdueCount,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _HeroMaintenanceIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeroMaintenanceText(
                        pendingCount: pendingCount,
                        overdueCount: overdueCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HeroMaintenanceMetrics(
                  completedCount: completedCount,
                  overdueCount: overdueCount,
                ),
              ],
            ),
    );
  }
}

class _HeroMaintenanceIcon extends StatelessWidget {
  const _HeroMaintenanceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.car_repair_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _HeroMaintenanceText extends StatelessWidget {
  final int pendingCount;
  final int overdueCount;

  const _HeroMaintenanceText({
    required this.pendingCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final headline = overdueCount > 0
        ? 'Hay mantenimientos que requieren atención'
        : 'Tu plan preventivo está bajo control';

    final body = pendingCount == 0
        ? 'No tienes tareas activas por ahora.'
        : 'Revisa tus tareas activas y mantén el vehículo al día con acciones preventivas.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de mantenimiento',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.8,
            height: 1.4,
            color: Colors.white.withOpacity(0.86),
          ),
        ),
      ],
    );
  }
}

class _HeroMaintenanceMetrics extends StatelessWidget {
  final int completedCount;
  final int overdueCount;

  const _HeroMaintenanceMetrics({
    required this.completedCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _HeroMiniMetric(
            icon: Icons.check_circle_rounded,
            label: 'Completados',
            value: '$completedCount',
          ),
          const SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.warning_amber_rounded,
            label: 'Vencidos',
            value: '$overdueCount',
          ),
        ],
      ),
    );
  }
}

class _HeroMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.6,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaintenanceNoticeCard extends StatelessWidget {
  final MapColors colors;

  const _MaintenanceNoticeCard({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.warning.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.warning.withOpacity(0.16),
              ),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 18,
              color: colors.warning,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantenimiento preventivo',
                  style: TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estas recomendaciones son preventivas y no reemplazan una revisión mecánica profesional.',
                  style: TextStyle(
                    fontSize: 11.9,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSectionHeader extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final int count;

  const _MaintenanceSectionHeader({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.8,
                    height: 1.42,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.18)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MapColors colors;
  final MaintenanceRecordModel record;
  final Color statusColor;
  final String statusLabel;
  final String? lastCompletedId;
  final String Function(DateTime?) formatDate;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _MaintenanceCard({
    required this.colors,
    required this.record,
    required this.statusColor,
    required this.statusLabel,
    required this.lastCompletedId,
    required this.formatDate,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final justCompleted = lastCompletedId == record.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: justCompleted
              ? colors.success.withOpacity(0.08)
              : colors.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: justCompleted
                ? colors.success.withOpacity(0.24)
                : colors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: justCompleted
                  ? colors.success.withOpacity(0.12)
                  : colors.shadow.withOpacity(0.16),
              blurRadius: justCompleted ? 18 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: statusColor.withOpacity(0.20)),
              ),
              child: Icon(
                record.isOverdue
                    ? Icons.warning_rounded
                    : Icons.build_rounded,
                size: 22,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.maintenanceType,
                            style: TextStyle(
                              fontSize: 14.6,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11.2,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      colors: colors,
                      label: 'Último',
                      value: formatDate(record.lastDoneAt),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      colors: colors,
                      label: 'Próximo',
                      value: formatDate(record.nextDueAt),
                    ),
                    if ((record.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.notes!.trim(),
                        style: TextStyle(
                          fontSize: 11.9,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onComplete,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.textPrimary.withOpacity(0.92),
                              foregroundColor: colors.card,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Marcar completado',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ];
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.chip,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.chipBorder),
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedMaintenanceCard extends StatelessWidget {
  final MapColors colors;
  final MaintenanceRecordModel record;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDelete;

  const _CompletedMaintenanceCard({
    required this.colors,
    required this.record,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.14),
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
                color: colors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colors.success.withOpacity(0.20)),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 22,
                color: colors.success,
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
                      record.maintenanceType,
                      style: TextStyle(
                        fontSize: 14.6,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      colors: colors,
                      label: 'Último registro',
                      value: formatDate(record.lastDoneAt),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      colors: colors,
                      label: 'Próxima referencia',
                      value: formatDate(record.nextDueAt),
                    ),
                    if ((record.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.notes!.trim(),
                        style: TextStyle(
                          fontSize: 11.9,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
                ];
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.chip,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.chipBorder),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final MapColors colors;
  final String label;
  final String value;

  const _InfoLine({
    required this.colors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11.9,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.9,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String message;
  final Color accent;
  final IconData icon;

  const _EmptySectionCard({
    required this.colors,
    required this.title,
    required this.message,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11.9,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceEmptyState extends StatelessWidget {
  final MapColors colors;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _MaintenanceEmptyState({
    required this.colors,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.primary.withOpacity(0.20)),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aún no tienes mantenimientos registrados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea recomendaciones iniciales para empezar a organizar tareas preventivas de tu vehículo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.6,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              style: FilledButton.styleFrom(
                backgroundColor: colors.textPrimary.withOpacity(0.92),
                foregroundColor: colors.card,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: isGenerating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: colors.card,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isGenerating
                    ? 'Creando recomendaciones...'
                    : 'Crear recomendaciones iniciales',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceLoadingView extends StatelessWidget {
  final MapColors colors;

  const _MaintenanceLoadingView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando mantenimiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos preparando tus registros y recomendaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaintenanceStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _MaintenanceStatusView({
    required this.colors,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.22)),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.8,
                  height: 1.55,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class _MaintenanceSuccessOverlay extends StatefulWidget {
  final String title;
  final String subtitle;

  const _MaintenanceSuccessOverlay({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_MaintenanceSuccessOverlay> createState() =>
      _MaintenanceSuccessOverlayState();
}

class _MaintenanceSuccessOverlayState extends State<_MaintenanceSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _spark(Color color, double size) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final colors = MapColors(isDark);

    return Material(
      color: colors.background.withOpacity(0.28),
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card.withOpacity(0.98),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.success.withOpacity(0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(top: 8, left: 6, child: _spark(colors.warning, 8)),
                        Positioned(top: 6, right: 10, child: _spark(colors.primary, 10)),
                        Positioned(bottom: 12, left: 10, child: _spark(colors.accent, 7)),
                        Positioned(bottom: 8, right: 6, child: _spark(colors.success, 9)),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: colors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.success.withOpacity(0.22),
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 34,
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}