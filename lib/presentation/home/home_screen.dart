import 'dart:math' as math;

import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/presentation/home/widgets/home_action_card.dart';
import 'package:ecopulse/presentation/home/widgets/supabase_connection_card.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class EcoColors {
  final bool isDark;
  const EcoColors(this.isDark);

  Color get background => isDark ? const Color(0xFF0A1628) : const Color(0xFFF2F7FB);
  Color get background2 => isDark ? const Color(0xFF0D1F3C) : const Color(0xFFE5EEF5);
  Color get background3 => isDark ? const Color(0xFF08131F) : const Color(0xFFDCEBF4);

  Color get card => isDark ? const Color(0xFF132033) : Colors.white;
  Color get cardAlt => isDark ? const Color(0xFF0F1A2C) : const Color(0xFFF7FAFD);

  Color get border => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get shadow => isDark
      ? Colors.black.withOpacity(0.28)
      : const Color(0xFF5F96B3).withOpacity(0.10);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary => isDark ? const Color(0xFF9BB1C2) : const Color(0xFF5D7383);
  Color get textMuted => isDark ? const Color(0xFF6E8799) : const Color(0xFF8FA5B3);

  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);
  Color get warning => const Color(0xFFF4A261);
  Color get success => const Color(0xFF57B65F);
  Color get danger => const Color(0xFFE76F51);

  Color get heroTop => isDark ? const Color(0xFF12243C) : const Color(0xFF17314E);
  Color get heroBottom => isDark ? const Color(0xFF0E1B2D) : const Color(0xFF0F2339);

  Color get chip => isDark
      ? const Color(0xFF0F1A2C).withOpacity(0.85)
      : const Color(0xFFEAF2F8).withOpacity(0.96);

  Color get chipBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get orb1 => isDark
      ? const Color(0xFF2EC4B6).withOpacity(0.10)
      : const Color(0xFF2EC4B6).withOpacity(0.07);

  Color get orb2 => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.09)
      : const Color(0xFF5F96B3).withOpacity(0.08);

  Color get orb3 => isDark
      ? const Color(0xFFF4A261).withOpacity(0.07)
      : const Color(0xFFF4A261).withOpacity(0.05);

  Color get dots => isDark
      ? Colors.white.withOpacity(0.022)
      : const Color(0xFF5F96B3).withOpacity(0.07);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool? _manualDark;
  late final AnimationController _bgController;

  String _displayName = 'Conductor';
  bool _loadingProfileName = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _loadProfileName();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthRepository().signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _loadProfileName() async {
    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _displayName = 'Conductor';
        _loadingProfileName = false;
      });
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      final profile = response as Map<String, dynamic>?;

      final profileName = [
        
        profile?['full_name']
        
      ]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .cast<String?>()
          .firstWhere(
            (e) => e != null && e.isNotEmpty,
            orElse: () => null,
          );

      if (!mounted) return;

      setState(() {
        _displayName = profileName ?? 'Conductor';
        _loadingProfileName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = 'Conductor';
        _loadingProfileName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = EcoColors(isDark);
    final size = MediaQuery.of(context).size;

    final hPad = size.width >= 1100
        ? size.width * 0.11
        : size.width >= 700
            ? 28.0
            : 20.0;

    final displayName = _loadingProfileName ? 'Cargando...' : _displayName;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 250),
      data: isDark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            _EcoBg(controller: _bgController, colors: colors),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadProfileName,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
                  children: [
                    _Header(
                      colors: colors,
                      displayName: displayName,
                      isDark: isDark,
                      onToggle: _toggleTheme,
                      onSignOut: () => _signOut(context),
                      onProfile: () => context.push(AppRoutes.profile),
                      onSettings: () => context.push(AppRoutes.settings),
                      onPermissions: () => context.push(AppRoutes.permissions),
                      onPrivacy: () => context.push(AppRoutes.privacyPolicy),
                    ),
                    const SizedBox(height: 20),
                    _WelcomeHero(
                      colors: colors,
                      firstName: displayName,
                      onLiveTrip: () => context.push(AppRoutes.liveTrip),
                      onMap: () => context.push(AppRoutes.map),
                      onAssistant: () => context.push(AppRoutes.aiAssistant),
                    ),
                    const SizedBox(height: 20),
                    const SupabaseConnectionCard(),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      colors: colors,
                      title: 'Movilidad',
                      subtitle: 'Acceso rápido a tus trayectos y navegación.',
                      icon: Icons.route_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ActionGroup(
                      items: [
                        _Item(
                          title: 'Trayecto en vivo',
                          description: 'Inicia un trayecto o activa detección automática.',
                          icon: Icons.route_rounded,
                          onTap: () => context.push(AppRoutes.liveTrip),
                        ),
                        _Item(
                          title: 'Mapa en tiempo real',
                          description:
                              'Visualiza tu ruta, ubicación actual y estaciones cercanas.',
                          icon: Icons.map_rounded,
                          onTap: () => context.push(AppRoutes.map),
                        ),
                        _Item(
                          title: 'Historial de trayectos',
                          description:
                              'Consulta viajes finalizados, costos, consumo y rutas.',
                          icon: Icons.history_rounded,
                          onTap: () => context.push(AppRoutes.tripHistory),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      colors: colors,
                      title: 'Combustible',
                      subtitle: 'Consulta estaciones y precios disponibles.',
                      icon: Icons.local_gas_station_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ActionGroup(
                      items: [
                        _Item(
                          title: 'Estaciones de gasolina',
                          description: 'Consulta estaciones registradas en Pasto, Nariño.',
                          icon: Icons.local_gas_station_rounded,
                          onTap: () => context.push(AppRoutes.fuelStationsMap),
                        ),
                        _Item(
                          title: 'Precios de combustible',
                          description: 'Consulta precios registrados para Pasto, Nariño.',
                          icon: Icons.payments_rounded,
                          onTap: () => context.push(AppRoutes.fuelPrices),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      colors: colors,
                      title: 'Vehículo',
                      subtitle: 'Gestiona tu vehículo y mantenimiento.',
                      icon: Icons.directions_car_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ActionGroup(
                      items: [
                        _Item(
                          title: 'Vehículo',
                          description:
                              'Selecciona un vehículo del catálogo o regístralo manualmente.',
                          icon: Icons.directions_car_rounded,
                          onTap: () => context.push(AppRoutes.vehicleSelection),
                        ),
                        _Item(
                          title: 'Mantenimiento preventivo',
                          description: 'Gestiona revisiones recomendadas para tu vehículo.',
                          icon: Icons.build_circle_rounded,
                          onTap: () => context.push(AppRoutes.maintenance),
                        ),
                        _Item(
                          title: 'Asistente IA',
                          description:
                              'Recibe consejos de conducción, consumo y mantenimiento.',
                          icon: Icons.smart_toy_rounded,
                          onTap: () => context.push(AppRoutes.aiAssistant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Footer(
                      colors: colors,
                      onSignOut: () => _signOut(context),
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

class _Item {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _Item({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class _EcoBg extends StatelessWidget {
  const _EcoBg({required this.controller, required this.colors});

  final AnimationController controller;
  final EcoColors colors;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.background,
                    colors.background2,
                    colors.background3,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.06 + math.sin(t) * size.height * 0.04,
              right: -size.width * 0.20 + math.cos(t) * size.width * 0.03,
              child: _Orb(size: size.width * 0.82, color: colors.orb1),
            ),
            Positioned(
              top: size.height * 0.44 + math.sin(t + math.pi) * size.height * 0.04,
              left: -size.width * 0.22 + math.cos(t + math.pi) * size.width * 0.03,
              child: _Orb(size: size.width * 0.68, color: colors.orb2),
            ),
            Positioned(
              bottom: size.height * 0.08 + math.cos(t * 0.6) * size.height * 0.03,
              right: size.width * 0.06 + math.sin(t * 0.6) * size.width * 0.04,
              child: _Orb(size: size.width * 0.46, color: colors.orb3),
            ),
            CustomPaint(
              size: size,
              painter: _DotGrid(colors.dots),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _DotGrid extends CustomPainter {
  const _DotGrid(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const s = 26.0;
    for (double x = s; x < size.width; x += s) {
      for (double y = s; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGrid old) => old.color != color;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.colors,
    required this.displayName,
    required this.isDark,
    required this.onToggle,
    required this.onSignOut,
    required this.onProfile,
    required this.onSettings,
    required this.onPermissions,
    required this.onPrivacy,
  });

  final EcoColors colors;
  final String displayName;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onSignOut;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onPermissions;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<_HeaderMenuAction>(
          tooltip: 'Abrir menú',
          color: colors.card,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          offset: const Offset(0, 60),
          onSelected: (value) {
            HapticFeedback.lightImpact();
            switch (value) {
              case _HeaderMenuAction.profile:
                onProfile();
                break;
              case _HeaderMenuAction.settings:
                onSettings();
                break;
              case _HeaderMenuAction.permissions:
                onPermissions();
                break;
              case _HeaderMenuAction.privacy:
                onPrivacy();
                break;
            }
          },
          itemBuilder: (context) => [
            _buildMenuItem(
              value: _HeaderMenuAction.profile,
              icon: Icons.person_rounded,
              title: 'Mi perfil',
              subtitle: 'Datos personales y cuenta',
            ),
            _buildMenuItem(
              value: _HeaderMenuAction.settings,
              icon: Icons.settings_rounded,
              title: 'Configuración',
              subtitle: 'Preferencias y ajustes',
            ),
            _buildMenuItem(
              value: _HeaderMenuAction.permissions,
              icon: Icons.verified_user_rounded,
              title: 'Permisos',
              subtitle: 'GPS, sensores y notificaciones',
            ),
            _buildMenuItem(
              value: _HeaderMenuAction.privacy,
              icon: Icons.privacy_tip_rounded,
              title: 'Política de datos',
              subtitle: 'Información legal y privacidad',
            ),
          ],
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                colors: [colors.heroTop, colors.heroBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: colors.primary.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.eco_rounded, color: colors.accent, size: 25),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hola, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderBtn(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? colors.warning : colors.primary,
          bg: colors.card,
          border: colors.border,
          shadow: colors.shadow,
          onTap: onToggle,
          tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
        ),
        const SizedBox(width: 8),
        _HeaderBtn(
          icon: Icons.logout_rounded,
          color: colors.danger,
          bg: colors.danger.withOpacity(0.10),
          border: colors.danger.withOpacity(0.22),
          shadow: Colors.transparent,
          onTap: onSignOut,
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  PopupMenuItem<_HeaderMenuAction> _buildMenuItem({
    required _HeaderMenuAction value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return PopupMenuItem<_HeaderMenuAction>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.chipBorder),
            ),
            child: Icon(icon, size: 19, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
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

enum _HeaderMenuAction {
  profile,
  settings,
  permissions,
  privacy,
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.shadow,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final Color shadow;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.colors,
    required this.firstName,
    required this.onLiveTrip,
    required this.onMap,
    required this.onAssistant,
  });

  final EcoColors colors;
  final String firstName;
  final VoidCallback onLiveTrip;
  final VoidCallback onMap;
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.accent.withOpacity(0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.waving_hand_rounded, size: 14, color: colors.warning),
                const SizedBox(width: 7),
                Text(
                  'Hola, $firstName',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu panel de\nconducción.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Gestiona trayectos, combustible, mantenimiento y asistencia inteligente desde un solo lugar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBtn(
                label: 'Iniciar trayecto',
                icon: Icons.route_rounded,
                color: colors.accent,
                filled: true,
                onTap: onLiveTrip,
              ),
              _HeroBtn(
                label: 'Ver mapa',
                icon: Icons.map_rounded,
                color: colors.primary,
                onTap: onMap,
              ),
              _HeroBtn(
                label: 'Asistente IA',
                icon: Icons.smart_toy_rounded,
                color: colors.warning,
                onTap: onAssistant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: filled ? color : color.withOpacity(0.26)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final EcoColors colors;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.chip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.chipBorder),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return _grid(3);
        }
        if (constraints.maxWidth >= 620) {
          return _grid(2);
        }
        return Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              HomeActionCard(
                title: items[i].title,
                description: items[i].description,
                icon: items[i].icon,
                onTap: items[i].onTap,
              ),
              if (i < items.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _grid(int cols) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: cols == 3 ? 1.28 : 1.52,
      ),
      itemBuilder: (context, index) => HomeActionCard(
        title: items[index].title,
        description: items[index].description,
        icon: items[index].icon,
        onTap: items[index].onTap,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.colors,
    required this.onSignOut,
  });

  final EcoColors colors;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Sesión actual',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Puedes cerrar sesión desde aquí cuando termines de usar la aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _FooterAction(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              color: colors.danger,
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}