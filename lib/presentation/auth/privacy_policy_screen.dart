import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─── PALETA (coherente con Login y Register) ──────────────────────────────────

class _EcoColors {
  final bool isDark;
  const _EcoColors(this.isDark);

  Color get bg => isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F5FA);
  Color get bgGrad1 => isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F5FA);
  Color get bgGrad2 => isDark ? const Color(0xFF0D1F3C) : const Color(0xFFE3EEF6);
  Color get bgGrad3 => isDark ? const Color(0xFF081420) : const Color(0xFFD8E9F3);
  Color get cardGrad1 => isDark ? const Color(0xFF162032).withOpacity(0.92) : Colors.white.withOpacity(0.95);
  Color get cardGrad2 => isDark ? const Color(0xFF0F1A2C).withOpacity(0.96) : const Color(0xFFF7FAFD).withOpacity(0.97);
  Color get cardBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.18) : const Color(0xFF5F96B3).withOpacity(0.22);
  Color get cardShadow => isDark ? const Color(0xFF000000).withOpacity(0.3) : const Color(0xFF5F96B3).withOpacity(0.12);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary => isDark ? const Color(0xFF86AFC4) : const Color(0xFF4A6375);
  Color get textMuted => isDark ? const Color(0xFF5E7382) : const Color(0xFF7A95A6);
  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);
  Color get logoGrad1 => const Color(0xFF0F1C2E);
  Color get logoGrad2 => isDark ? const Color(0xFF1A2E47) : const Color(0xFF1A3A55);
  Color get toggleBg => isDark ? const Color(0xFF162032) : const Color(0xFFE3EEF6);
  Color get toggleBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.25) : const Color(0xFF5F96B3).withOpacity(0.4);
  Color get orb1 => isDark ? const Color(0xFF2EC4B6).withOpacity(0.13) : const Color(0xFF2EC4B6).withOpacity(0.10);
  Color get orb2 => isDark ? const Color(0xFF5F96B3).withOpacity(0.11) : const Color(0xFF5F96B3).withOpacity(0.12);
  Color get orb3 => isDark ? const Color(0xFF2EC4B6).withOpacity(0.09) : const Color(0xFF2EC4B6).withOpacity(0.07);
  Color get dotColor => isDark ? const Color(0xFFFFFFFF).withOpacity(0.025) : const Color(0xFF5F96B3).withOpacity(0.08);
  Color get sectionIconBg => isDark ? const Color(0xFF162032) : const Color(0xFFE3EEF6);
  Color get bulletBg => isDark ? const Color(0xFF0F1A2C).withOpacity(0.8) : const Color(0xFFEDF4F8).withOpacity(0.9);
  Color get bulletBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.14) : const Color(0xFF5F96B3).withOpacity(0.22);
  Color get divider => isDark ? const Color(0xFF5F96B3).withOpacity(0.12) : const Color(0xFF5F96B3).withOpacity(0.15);
  Color get warningBg => isDark ? const Color(0xFFF4A261).withOpacity(0.08) : const Color(0xFFFFF3E8);
  Color get warningBorder => const Color(0xFFF4A261).withOpacity(0.3);
}

// ─── PRIVACY POLICY SCREEN ───────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool? _manualDark;

  bool _topBarVisible = true;
  double _scrollAccum = 0;
  double _lastOffset = 0;
  static const double _hideThreshold = 40.0;
  static const double _showThreshold = 20.0;

  late final AnimationController _enterController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  late final AnimationController _orbitController;
  late final AnimationController _toggleController;
  late final AnimationController _topBarController;
  late final Animation<Offset> _topBarSlide;
  late final Animation<double> _topBarFade;

  // progreso de lectura
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _headerFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)));
    _contentFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 0.85, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 0.85, curve: Curves.easeOut)));

    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _toggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _topBarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _topBarSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.0))
        .animate(CurvedAnimation(parent: _topBarController, curve: Curves.easeInOutCubic));
    _topBarFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _topBarController, curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic)));

    _scrollController.addListener(_onScroll);
    _enterController.forward();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset < 0) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent > 0) {
      final progress = (offset / maxExtent).clamp(0.0, 1.0);
      if ((progress - _readProgress).abs() > 0.01) {
        setState(() => _readProgress = progress);
      }
    }
    if (maxExtent > 0 && offset > maxExtent) return;

    final delta = offset - _lastOffset;
    _lastOffset = offset;
    if (delta > 0) {
      _scrollAccum = (_scrollAccum + delta).clamp(0, _hideThreshold * 2);
      if (_scrollAccum >= _hideThreshold && _topBarVisible) {
        setState(() => _topBarVisible = false);
        _topBarController.forward();
        _scrollAccum = 0;
      }
    } else if (delta < 0) {
      _scrollAccum = (_scrollAccum + delta).clamp(-_showThreshold * 2, 0);
      if (_scrollAccum <= -_showThreshold && !_topBarVisible) {
        setState(() => _topBarVisible = true);
        _topBarController.reverse();
        _scrollAccum = 0;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _enterController.dispose();
    _orbitController.dispose();
    _toggleController.dispose();
    _topBarController.dispose();
    super.dispose();
  }

  bool _resolveIsDark(BuildContext context) {
    if (_manualDark != null) return _manualDark!;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    final isDark = _resolveIsDark(context);
    isDark ? _toggleController.reverse() : _toggleController.forward();
    setState(() => _manualDark = !isDark);
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = _resolveIsDark(context);
    final colors = _EcoColors(isDark);
    final hPad = size.width > 600 ? size.width * 0.15 : 20.0;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 350),
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: colors.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _AnimatedBackground(orbitController: _orbitController, size: size, colors: colors),

            SafeArea(
              child: Column(
                children: [
                  // ── barra superior fija ──────────────────────────────
                  _TopBar(colors: colors, onBack: _handleBack, readProgress: _readProgress),

                  // ── barra de progreso de lectura ─────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    child: LinearProgressIndicator(
                      value: _readProgress,
                      backgroundColor: colors.primary.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      minHeight: 3,
                    ),
                  ),

                  // ── contenido scrollable ─────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(top: 20, left: hPad, right: hPad, bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // header
                          FadeTransition(
                            opacity: _headerFade,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: _PolicyHeader(colors: colors),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // contenido
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: _PolicyContent(colors: colors),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // botón entendido
                          FadeTransition(
                            opacity: _contentFade,
                            child: _EntendidoButton(colors: colors, onPressed: _handleBack),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // toggle tema scroll-aware
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: SlideTransition(
                  position: _topBarSlide,
                  child: FadeTransition(
                    opacity: _topBarFade,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, right: 20),
                      child: _ThemeToggleButton(
                        isDark: isDark,
                        colors: colors,
                        toggleController: _toggleController,
                        onToggle: _toggleTheme,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TOP BAR ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colors, required this.onBack, required this.readProgress});
  final _EcoColors colors;
  final VoidCallback onBack;
  final double readProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 80, bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colors.cardGrad1,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: colors.cardBorder, width: 1.1),
                boxShadow: [BoxShadow(color: colors.cardShadow.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: colors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Política de datos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.2),
                ),
                Text(
                  '${(readProgress * 100).toInt()}% leído',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER POLÍTICA ──────────────────────────────────────────────────────────

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.2), blurRadius: 36, spreadRadius: 6)],
              ),
            ),
            Container(
              width: 74, height: 74,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.logoGrad1, colors.logoGrad2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.primary.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF0A1628).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 7))],
              ),
              child: Icon(Icons.shield_outlined, size: 34, color: colors.accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Política de tratamiento\nde datos personales',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.4, height: 1.2),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.accent.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 12, color: colors.accent),
                const SizedBox(width: 5),
                Text('EcoPulse · Versión 1.0',
                    style: TextStyle(fontSize: 12, color: colors.accent, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Lee con atención antes de crear tu cuenta.\nTu privacidad y control de datos son nuestra prioridad.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.55),
        ),
      ],
    );
  }
}

// ─── CONTENIDO POLÍTICA ───────────────────────────────────────────────────────

class _PolicyContent extends StatelessWidget {
  const _PolicyContent({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro card
        _IntroCard(colors: colors),
        const SizedBox(height: 14),

        // Sección 1
        _PolicySection(
          colors: colors,
          icon: Icons.location_on_outlined,
          title: 'Datos que se podrán procesar',
          bullets: const [
            'Ubicación aproximada y precisa durante el trayecto.',
            'Velocidad, distancia, altitud, rumbo y precisión GPS.',
            'Lecturas de acelerómetro, giroscopio, magnetómetro y barómetro si están disponibles.',
            'Datos del vehículo: marca, modelo, año, combustible, peso y rendimiento estimado.',
            'Historial de viajes, eventos de conducción y estimaciones de consumo.',
            'Métricas de conducción, costos estimados y recomendaciones generadas.',
          ],
        ),
        const SizedBox(height: 14),

        // Sección 2
        _PolicySection(
          colors: colors,
          icon: Icons.track_changes_rounded,
          title: 'Finalidad del tratamiento',
          body: 'Los datos se usarán para registrar trayectos, estimar consumo de combustible, detectar aceleraciones bruscas, frenadas fuertes, ralentí prolongado y otros eventos que puedan afectar el rendimiento del vehículo.',
        ),
        const SizedBox(height: 14),

        // Sección 3 — advertencia
        _PolicySection(
          colors: colors,
          icon: Icons.info_outline_rounded,
          title: 'Limitaciones técnicas',
          body: 'EcoPulse no reemplaza mediciones oficiales del computador del vehículo ni datos OBD-II. El consumo calculado es una estimación basada en sensores móviles, GPS, datos del vehículo y modelos físico-matemáticos aproximados.',
          isWarning: true,
        ),
        const SizedBox(height: 14),

        // Sección 4
        _PolicySection(
          colors: colors,
          icon: Icons.manage_accounts_outlined,
          title: 'Control del usuario',
          body: 'El usuario podrá cerrar sesión, editar su perfil, cambiar su vehículo seleccionado y modificar preferencias de alertas en fases posteriores de la aplicación.',
        ),
        const SizedBox(height: 14),

        // Sección 5
        _PolicySection(
          colors: colors,
          icon: Icons.check_circle_outline_rounded,
          title: 'Aceptación',
          body: 'Para crear una cuenta en EcoPulse es obligatorio aceptar esta política. La aceptación se guardará en Supabase con el identificador del usuario, fecha de aceptación y versión de la política.',
        ),
      ],
    );
  }
}

// ─── INTRO CARD ───────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [colors.cardGrad1, colors.cardGrad2],
        ),
        border: Border.all(color: colors.cardBorder, width: 1.1),
        boxShadow: [BoxShadow(color: colors.cardShadow, blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: colors.accent.withOpacity(0.13), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.eco_rounded, size: 18, color: colors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'EcoPulse es una aplicación diseñada para estimar el consumo de combustible y mejorar los hábitos de conducción usando datos del teléfono móvil y datos del vehículo registrados por el usuario.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECCIÓN POLÍTICA ─────────────────────────────────────────────────────────

class _PolicySection extends StatefulWidget {
  const _PolicySection({
    required this.colors,
    required this.icon,
    required this.title,
    this.body,
    this.bullets,
    this.isWarning = false,
  });
  final _EcoColors colors;
  final IconData icon;
  final String title;
  final String? body;
  final List<String>? bullets;
  final bool isWarning;

  @override
  State<_PolicySection> createState() => _PolicySectionState();
}

class _PolicySectionState extends State<_PolicySection> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1.0);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final borderColor = widget.isWarning ? c.warningBorder : c.cardBorder;
    final bgColor = widget.isWarning ? c.warningBg : c.cardGrad1;
    final iconBgColor = widget.isWarning ? const Color(0xFFF4A261).withOpacity(0.15) : c.primary.withOpacity(0.12);
    final iconColor = widget.isWarning ? const Color(0xFFF4A261) : c.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.1),
        color: bgColor,
        boxShadow: [BoxShadow(color: c.cardShadow.withOpacity(0.7), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // header de sección — siempre visible, tappable
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                      child: Icon(widget.icon, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary, letterSpacing: -0.1),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // contenido colapsable
            SizeTransition(
              sizeFactor: _fadeAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, c.divider, Colors.transparent]))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: widget.bullets != null
                          ? _BulletList(bullets: widget.bullets!, colors: c)
                          : Text(widget.body ?? '', style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.65)),
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

// ─── BULLET LIST ─────────────────────────────────────────────────────────────

class _BulletList extends StatelessWidget {
  const _BulletList({required this.bullets, required this.colors});
  final List<String> bullets;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bullets.asMap().entries.map((e) {
        final isLast = e.key == bullets.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.bulletBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: colors.bulletBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colors.accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.value, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.55)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── BOTÓN ENTENDIDO ─────────────────────────────────────────────────────────

class _EntendidoButton extends StatefulWidget {
  const _EntendidoButton({required this.colors, required this.onPressed});
  final _EcoColors colors;
  final VoidCallback onPressed;

  @override
  State<_EntendidoButton> createState() => _EntendidoButtonState();
}

class _EntendidoButtonState extends State<_EntendidoButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.94, upperBound: 1.0)..value = 1.0;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); HapticFeedback.mediumImpact(); widget.onPressed(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [widget.colors.primary, widget.colors.accent],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            boxShadow: [BoxShadow(color: widget.colors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 20),
              SizedBox(width: 9),
              Text('Entendido', style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TOGGLE TEMA ─────────────────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark, required this.colors, required this.toggleController, required this.onToggle});
  final bool isDark;
  final _EcoColors colors;
  final AnimationController toggleController;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: 78, height: 38,
        decoration: BoxDecoration(
          color: colors.toggleBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.toggleBorder, width: 1.2),
          boxShadow: [BoxShadow(color: colors.accent.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedOpacity(
                  opacity: isDark ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.wb_sunny_rounded, size: 16, color: isDark ? colors.textMuted : const Color(0xFFF4A261)),
                ),
                AnimatedOpacity(
                  opacity: isDark ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.nightlight_round, size: 16, color: isDark ? colors.accent : colors.textMuted),
                ),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30, height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2EC4B6), const Color(0xFF5F96B3)]
                        : [const Color(0xFFF4A261), const Color(0xFFFFCC80)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(
                    color: (isDark ? colors.accent : const Color(0xFFF4A261)).withOpacity(0.35),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FONDO ANIMADO ────────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.orbitController, required this.size, required this.colors});
  final AnimationController orbitController;
  final Size size;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbitController,
      builder: (context, _) {
        final t = orbitController.value;
        final a1 = t * 2 * math.pi;
        final a2 = t * 2 * math.pi + math.pi;
        final a3 = t * 2 * math.pi * 0.6 + math.pi * 0.5;
        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: size.width, height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [colors.bgGrad1, colors.bgGrad2, colors.bgGrad3],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.06 + math.sin(a1) * size.height * 0.03,
              right: -size.width * 0.2 + math.cos(a1) * size.width * 0.03,
              child: Container(
                width: size.width * 0.85, height: size.width * 0.85,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [colors.orb1, colors.orb1.withOpacity(0)])),
              ),
            ),
            Positioned(
              top: size.height * 0.5 + math.sin(a2) * size.height * 0.05,
              left: -size.width * 0.3 + math.cos(a2) * size.width * 0.04,
              child: Container(
                width: size.width * 0.8, height: size.width * 0.8,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [colors.orb2, colors.orb2.withOpacity(0)])),
              ),
            ),
            Positioned(
              bottom: size.height * 0.08 + math.cos(a3) * size.height * 0.04,
              right: size.width * 0.05 + math.sin(a3) * size.width * 0.04,
              child: Container(
                width: size.width * 0.45, height: size.width * 0.45,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [colors.orb3, colors.orb3.withOpacity(0)])),
              ),
            ),
            CustomPaint(size: size, painter: _DotGridPainter(dotColor: colors.dotColor)),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.dotColor});
  final Color dotColor;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor..strokeCap = StrokeCap.round;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}