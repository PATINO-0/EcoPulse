import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/services/permissions/app_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() {
    return _PermissionsScreenState();
  }
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isLoading = false;
  String _message = 'Revisa los permisos necesarios para usar EcoPulse.';
  bool? _manualDark;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _requestPermissions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final status = await ref
          .read(appPermissionServiceProvider)
          .requestRequiredPermissions();

      if (!mounted) return;

      setState(() {
        _message = status.statusMessage;
      });
    } catch (exception) {
      if (!mounted) return;

      setState(() {
        _message = 'No fue posible solicitar permisos. Detalle: $exception';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    HapticFeedback.lightImpact();
    await ref.read(appPermissionServiceProvider).openDeviceSettings();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status =
          await ref.read(appPermissionServiceProvider).checkPermissions();

      if (!mounted) return;

      setState(() {
        _message = status.statusMessage;
      });
    } catch (exception) {
      if (!mounted) return;

      setState(() {
        _message = 'No fue posible verificar permisos. Detalle: $exception';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _statusAccent(MapColors colors) {
    final text = _message.toLowerCase();

    if (text.contains('conced') ||
        text.contains('activo') ||
        text.contains('habilitad') ||
        text.contains('correctamente')) {
      return colors.success;
    }

    if (text.contains('deneg') ||
        text.contains('rechaz') ||
        text.contains('configuración') ||
        text.contains('ajustes')) {
      return colors.warning;
    }

    if (text.contains('error') || text.contains('no fue posible')) {
      return colors.danger;
    }

    return colors.primary;
  }

  String _statusTitle() {
    final text = _message.toLowerCase();

    if (text.contains('conced') ||
        text.contains('activo') ||
        text.contains('habilitad') ||
        text.contains('correctamente')) {
      return 'Permisos listos';
    }

    if (text.contains('deneg') ||
        text.contains('rechaz') ||
        text.contains('configuración') ||
        text.contains('ajustes')) {
      return 'Acción pendiente';
    }

    if (text.contains('error') || text.contains('no fue posible')) {
      return 'Revisión requerida';
    }

    return 'Estado actual';
  }

  String _statusCaption() {
    final text = _message.toLowerCase();

    if (text.contains('conced') ||
        text.contains('activo') ||
        text.contains('habilitad') ||
        text.contains('correctamente')) {
      return 'Tu dispositivo ya está preparado para registrar trayectos.';
    }

    if (text.contains('deneg') ||
        text.contains('rechaz') ||
        text.contains('configuración') ||
        text.contains('ajustes')) {
      return 'Es posible que debas conceder acceso manualmente.';
    }

    if (text.contains('error') || text.contains('no fue posible')) {
      return 'Verifica el estado e inténtalo nuevamente.';
    }

    return 'EcoPulse necesita acceso para funcionar con precisión.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);
    final statusAccent = _statusAccent(colors);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isTablet = width >= 760;
            final isDesktop = width >= 1140;
            final horizontalPadding = isDesktop
                ? 30.0
                : isTablet
                    ? 24.0
                    : 18.0;

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
                    child: _PermissionsHeader(
                      colors: colors,
                      isDark: isDark,
                      isLoading: _isLoading,
                      onBack: () => Navigator.of(context).maybePop(),
                      onToggleTheme: _toggleTheme,
                      onRefresh: _checkPermissions,
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
                    child: _PermissionsHeroCard(
                      colors: colors,
                      isWide: isTablet,
                      statusAccent: statusAccent,
                      statusTitle: _statusTitle(),
                      statusCaption: _statusCaption(),
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
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _PermissionsInfoPanel(
                                  colors: colors,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 7,
                                child: _PermissionsControlPanel(
                                  colors: colors,
                                  message: _message,
                                  isLoading: _isLoading,
                                  statusAccent: statusAccent,
                                  statusTitle: _statusTitle(),
                                  onRequestPermissions: _requestPermissions,
                                  onOpenSettings: _openSettings,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _PermissionsInfoPanel(colors: colors),
                              const SizedBox(height: 16),
                              _PermissionsControlPanel(
                                colors: colors,
                                message: _message,
                                isLoading: _isLoading,
                                statusAccent: statusAccent,
                                statusTitle: _statusTitle(),
                                onRequestPermissions: _requestPermissions,
                                onOpenSettings: _openSettings,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PermissionsHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onRefresh;

  const _PermissionsHeader({
    required this.colors,
    required this.isDark,
    required this.isLoading,
    required this.onBack,
    required this.onToggleTheme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

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
                    _PermissionsCircleAction(
                      icon: Icons.arrow_back_rounded,
                      color: colors.primary,
                      bg: colors.chip,
                      border: colors.chipBorder,
                      onTap: onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Permisos',
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
                    'Controla el acceso que EcoPulse necesita para registrar recorridos, alertas y señales del dispositivo.',
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
                      child: _PermissionsHeaderActionButton(
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
                      child: _PermissionsHeaderActionButton(
                        colors: colors,
                        icon: isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        label: isLoading ? 'Revisando' : 'Verificar',
                        color: isLoading ? colors.warning : colors.accent,
                        onTap: onRefresh,
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
              _PermissionsCircleAction(
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
                      'Permisos',
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
                      'Controla el acceso que EcoPulse necesita para registrar recorridos, alertas y señales del dispositivo.',
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
              _PermissionsCircleAction(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: isDark ? colors.warning : colors.primary,
                bg: colors.chip,
                border: colors.chipBorder,
                onTap: onToggleTheme,
              ),
              const SizedBox(width: 8),
              _PermissionsCircleAction(
                icon: isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                color: isLoading ? colors.warning : colors.accent,
                bg: (isLoading ? colors.warning : colors.accent).withOpacity(
                  0.12,
                ),
                border: (isLoading ? colors.warning : colors.accent)
                    .withOpacity(0.24),
                onTap: onRefresh,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionsHeroCard extends StatelessWidget {
  final MapColors colors;
  final bool isWide;
  final Color statusAccent;
  final String statusTitle;
  final String statusCaption;

  const _PermissionsHeroCard({
    required this.colors,
    required this.isWide,
    required this.statusAccent,
    required this.statusTitle,
    required this.statusCaption,
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
                const _PermissionsHeroIcon(),
                const SizedBox(width: 18),
                Expanded(
                  child: _PermissionsHeroIdentity(
                    statusTitle: statusTitle,
                    statusCaption: statusCaption,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: _PermissionsHeroStatus(
                    statusAccent: statusAccent,
                    statusTitle: statusTitle,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _PermissionsHeroIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PermissionsHeroIdentity(
                        statusTitle: statusTitle,
                        statusCaption: statusCaption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PermissionsHeroStatus(
                  statusAccent: statusAccent,
                  statusTitle: statusTitle,
                ),
              ],
            ),
    );
  }
}

class _PermissionsHeroIcon extends StatelessWidget {
  const _PermissionsHeroIcon();

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
        Icons.verified_user_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _PermissionsHeroIdentity extends StatelessWidget {
  final String statusTitle;
  final String statusCaption;

  const _PermissionsHeroIdentity({
    required this.statusTitle,
    required this.statusCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso del dispositivo',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusTitle,
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
          statusCaption,
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

class _PermissionsHeroStatus extends StatelessWidget {
  final Color statusAccent;
  final String statusTitle;

  const _PermissionsHeroStatus({
    required this.statusAccent,
    required this.statusTitle,
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
          _PermissionsHeroMiniMetric(
            icon: Icons.location_on_rounded,
            label: 'Ubicación',
            value: 'Necesaria',
          ),
          const SizedBox(height: 10),
          _PermissionsHeroMiniMetric(
            icon: Icons.info_outline_rounded,
            label: 'Estado',
            value: statusTitle,
            accent: statusAccent,
          ),
        ],
      ),
    );
  }
}

class _PermissionsHeroMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _PermissionsHeroMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
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
        if (accent != null)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _PermissionsInfoPanel extends StatelessWidget {
  final MapColors colors;

  const _PermissionsInfoPanel({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permisos requeridos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EcoPulse necesita ciertos accesos para registrar recorridos y ofrecer alertas relevantes.',
            style: TextStyle(
              fontSize: 12.4,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _PermissionsRequirementTile(
            colors: colors,
            icon: Icons.my_location_rounded,
            label: 'Ubicación precisa o aproximada',
            description:
                'Necesaria para registrar el recorrido, velocidad, distancia y puntos del trayecto.',
            accent: colors.primary,
          ),
          const SizedBox(height: 12),
          _PermissionsRequirementTile(
            colors: colors,
            icon: Icons.gps_fixed_rounded,
            label: 'GPS activo',
            description:
                'Permite que el dispositivo entregue datos consistentes durante el viaje.',
            accent: colors.accent,
          ),
          const SizedBox(height: 12),
          _PermissionsRequirementTile(
            colors: colors,
            icon: Icons.notifications_active_rounded,
            label: 'Notificaciones',
            description:
                'Habilitan alertas futuras y recordatorios importantes dentro de la experiencia.',
            accent: colors.warning,
          ),
          const SizedBox(height: 12),
          _PermissionsRequirementTile(
            colors: colors,
            icon: Icons.sensors_rounded,
            label: 'Sensores disponibles',
            description:
                'EcoPulse puede usar señales del teléfono para enriquecer el análisis cuando existan.',
            accent: colors.success,
          ),
        ],
      ),
    );
  }
}

class _PermissionsRequirementTile extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String description;
  final Color accent;

  const _PermissionsRequirementTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.chipBorder),
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
                    label,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.8,
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

class _PermissionsControlPanel extends StatelessWidget {
  final MapColors colors;
  final String message;
  final bool isLoading;
  final Color statusAccent;
  final String statusTitle;
  final VoidCallback onRequestPermissions;
  final VoidCallback onOpenSettings;

  const _PermissionsControlPanel({
    required this.colors,
    required this.message,
    required this.isLoading,
    required this.statusAccent,
    required this.statusTitle,
    required this.onRequestPermissions,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: colors.primary.withOpacity(0.20)),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 22,
                  color: colors.primary,
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
                        'Control de acceso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Solicita permisos o abre la configuración del dispositivo para completarlos manualmente.',
                        style: TextStyle(
                          fontSize: 12.4,
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.chipBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado actual del permiso',
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este bloque refleja la última verificación realizada por el sistema.',
                  style: TextStyle(
                    fontSize: 11.6,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: statusAccent.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusAccent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: statusAccent.withOpacity(0.20),
                          ),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: statusAccent,
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
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 13.1,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acciones disponibles',
                  style: TextStyle(
                    fontSize: 11.4,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solicita permisos desde la app o abre ajustes del dispositivo cuando sea necesario.',
                  style: TextStyle(
                    fontSize: 12.2,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _PermissionsPrimaryButton(
                  colors: colors,
                  text: 'Solicitar permisos',
                  icon: Icons.verified_user_rounded,
                  isLoading: isLoading,
                  onPressed: onRequestPermissions,
                ),
                const SizedBox(height: 10),
                _PermissionsSecondaryButton(
                  colors: colors,
                  text: 'Abrir configuración del dispositivo',
                  icon: Icons.settings_rounded,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsPrimaryButton extends StatelessWidget {
  final MapColors colors;
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PermissionsPrimaryButton({
    required this.colors,
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        style: FilledButton.styleFrom(
          backgroundColor: colors.textPrimary.withOpacity(0.92),
          disabledBackgroundColor: colors.textPrimary.withOpacity(0.55),
          foregroundColor: colors.card,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: colors.textPrimary.withOpacity(0.08),
            ),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  color: colors.card,
                ),
              )
            : Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.card.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.card.withOpacity(0.10),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: colors.card,
                ),
              ),
        label: Text(
          isLoading ? 'Solicitando...' : text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.8,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _PermissionsSecondaryButton extends StatelessWidget {
  final MapColors colors;
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _PermissionsSecondaryButton({
    required this.colors,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.card.withOpacity(0.70),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border.withOpacity(0.92)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
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

class _PermissionsHeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PermissionsHeaderActionButton({
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

class _PermissionsCircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _PermissionsCircleAction({
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