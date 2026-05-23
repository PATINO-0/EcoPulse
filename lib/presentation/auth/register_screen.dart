import 'dart:math' as math;
import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── PALETA ───────────────────────────────────────────────────────────────────

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
  Color get inputFill => isDark ? const Color(0xFF0A1628).withOpacity(0.6) : const Color(0xFFEEF4F9);
  Color get inputBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.15) : const Color(0xFF5F96B3).withOpacity(0.3);
  Color get logoGrad1 => const Color(0xFF0F1C2E);
  Color get logoGrad2 => isDark ? const Color(0xFF1A2E47) : const Color(0xFF1A3A55);
  Color get toggleBg => isDark ? const Color(0xFF162032) : const Color(0xFFE3EEF6);
  Color get toggleBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.25) : const Color(0xFF5F96B3).withOpacity(0.4);
  Color get orb1 => isDark ? const Color(0xFF2EC4B6).withOpacity(0.13) : const Color(0xFF2EC4B6).withOpacity(0.10);
  Color get orb2 => isDark ? const Color(0xFF5F96B3).withOpacity(0.11) : const Color(0xFF5F96B3).withOpacity(0.12);
  Color get orb3 => isDark ? const Color(0xFF2EC4B6).withOpacity(0.09) : const Color(0xFF2EC4B6).withOpacity(0.07);
  Color get dotColor => isDark ? const Color(0xFFFFFFFF).withOpacity(0.025) : const Color(0xFF5F96B3).withOpacity(0.08);
  Color get policyBg => isDark ? const Color(0xFF0A1628).withOpacity(0.55) : const Color(0xFFE8F4F8).withOpacity(0.9);
  Color get policyBorder => isDark ? const Color(0xFF5F96B3).withOpacity(0.18) : const Color(0xFF5F96B3).withOpacity(0.28);
}

// ─── REGISTER SCREEN ─────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedPolicy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool? _manualDark;

  bool _topBarVisible = true;
  double _scrollAccum = 0;
  double _lastOffset = 0;
  static const double _hideThreshold = 40.0;
  static const double _showThreshold = 20.0;

  late final AnimationController _enterController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _footerFade;
  late final AnimationController _orbitController;
  late final AnimationController _toggleController;
  late final AnimationController _btnController;
  late final Animation<double> _btnScale;
  late final AnimationController _topBarController;
  late final Animation<Offset> _topBarSlide;
  late final Animation<double> _topBarFade;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _headerFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _cardFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.25, 0.7, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterController, curve: const Interval(0.25, 0.7, curve: Curves.easeOut)));
    _footerFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.55, 1.0, curve: Curves.easeOut));

    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _toggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _btnController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.93, upperBound: 1.0)..value = 1.0;
    _btnScale = _btnController;

    _topBarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _topBarSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.0))
        .animate(CurvedAnimation(parent: _topBarController, curve: Curves.easeInOutCubic));
    _topBarFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _topBarController, curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic)));

    _scrollController.addListener(_onScroll);
    _enterController.forward();

    // listeners para step indicator — registrar una sola vez
    _fullNameController.addListener(_updateStep);
    _emailController.addListener(_updateStep);
    _passwordController.addListener(_updateStep);
    _confirmPasswordController.addListener(_updateStep);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset < 0) return;
    if (_scrollController.position.maxScrollExtent > 0 && offset > _scrollController.position.maxScrollExtent) return;
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _enterController.dispose();
    _orbitController.dispose();
    _toggleController.dispose();
    _btnController.dispose();
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

  void _updateStep() {
    int step = 0;
    if (_fullNameController.text.isNotEmpty && _emailController.text.isNotEmpty) step = 1;
    if (step == 1 && _passwordController.text.length >= 6 && _confirmPasswordController.text == _passwordController.text) step = 2;
    if (step == 2 && _acceptedPolicy) step = 3;
    if (_currentStep != step) setState(() => _currentStep = step);
  }

  // ── Lógica original intacta ───────────────────────────────────────────────

  Future<void> _register() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (!_acceptedPolicy) {
      _showMessage('Debes aceptar la política de tratamiento de datos para crear tu cuenta.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            fullName: _fullNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            acceptedPolicy: _acceptedPolicy,
          );
      if (!mounted) return;
      final session = ref.read(authRepositoryProvider).currentSession;
      if (session == null) {
        _showMessage('Cuenta creada. Revisa tu correo si Supabase solicita confirmación.');
        context.go(AppRoutes.login);
        return;
      }
      context.go(AppRoutes.home);
    } catch (exception) {
      _showMessage(exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF0F1C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo electrónico.';
    if (!value.contains('@')) return 'Ingresa un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña.';
    if (value.length < 6) return 'La contraseña debe tener mínimo 6 caracteres.';
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = _resolveIsDark(context);
    final colors = _EcoColors(isDark);
    final canRegister = _acceptedPolicy && !_isLoading;
    // padding lateral responsivo
    final hPad = size.width > 600 ? size.width * 0.15 : 20.0;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 350),
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: colors.bg,
        // resizeToAvoidBottomInset evita overflow con teclado
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _AnimatedBackground(orbitController: _orbitController, size: size, colors: colors),
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(top: 60, left: hPad, right: hPad, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _RegisterHeader(colors: colors),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _headerFade,
                      child: _StepProgressBar(currentStep: _currentStep, colors: colors),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _RegisterFormCard(
                          colors: colors,
                          formKey: _formKey,
                          fullNameController: _fullNameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscurePassword: _obscurePassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          onToggleConfirmPassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          validateRequired: _validateRequired,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          validatePasswordConfirmation: _validatePasswordConfirmation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _cardFade,
                      child: _PolicyCard(
                        colors: colors,
                        acceptedPolicy: _acceptedPolicy,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _acceptedPolicy = v ?? false);
                          _updateStep();
                        },
                        onReadPolicy: () => context.push(AppRoutes.privacyPolicy),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _footerFade,
                      child: ScaleTransition(
                        scale: _btnScale,
                        child: _RegisterButton(
                          colors: colors,
                          isLoading: _isLoading,
                          canRegister: canRegister,
                          onPressed: canRegister ? _register : null,
                          btnController: _btnController,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _footerFade,
                      child: _LoginLink(colors: colors),
                    ),
                  ],
                ),
              ),
            ),
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
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.bgGrad1, colors.bgGrad2, colors.bgGrad3],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.08 + math.sin(a1) * size.height * 0.04,
              right: -size.width * 0.2 + math.cos(a1) * size.width * 0.03,
              child: Container(
                width: size.width * 0.9, height: size.width * 0.9,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [colors.orb1, colors.orb1.withOpacity(0)])),
              ),
            ),
            Positioned(
              top: size.height * 0.5 + math.sin(a2) * size.height * 0.06,
              left: -size.width * 0.3 + math.cos(a2) * size.width * 0.04,
              child: Container(
                width: size.width * 0.85, height: size.width * 0.85,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [colors.orb2, colors.orb2.withOpacity(0)])),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1 + math.cos(a3) * size.height * 0.04,
              right: size.width * 0.1 + math.sin(a3) * size.width * 0.05,
              child: Container(
                width: size.width * 0.5, height: size.width * 0.5,
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

// ─── TOGGLE TEMA ──────────────────────────────────────────────────────────────

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
                  child: Icon(Icons.wb_sunny_rounded, size: 16,
                      color: isDark ? colors.textMuted : const Color(0xFFF4A261)),
                ),
                AnimatedOpacity(
                  opacity: isDark ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.nightlight_round, size: 16,
                      color: isDark ? colors.accent : colors.textMuted),
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

// ─── HEADER ───────────────────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: colors.accent.withOpacity(0.22), blurRadius: 40, spreadRadius: 8)],
              ),
            ),
            Container(
              width: 78, height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.logoGrad1, colors.logoGrad2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: colors.accent.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF0A1628).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Icon(Icons.person_add_alt_1_rounded, size: 36, color: colors.accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Crea tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.5, height: 1.1),
        ),
        const SizedBox(height: 10),
        // FIT CHIP — evita overflow en pantallas pequeñas
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.accent.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, size: 13, color: colors.accent),
                const SizedBox(width: 5),
                Text(
                  'EcoPulse · Conducción eficiente',
                  style: TextStyle(fontSize: 12.5, color: colors.accent, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Guarda tus trayectos, vehículos, métricas\ny recomendaciones personalizadas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.55),
        ),
      ],
    );
  }
}

// ─── BARRA DE PROGRESO ────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.currentStep, required this.colors});
  final int currentStep;
  final _EcoColors colors;
  static const _labels = ['Datos', 'Contraseña', 'Política'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done ? colors.accent : active ? colors.primary.withOpacity(0.6) : colors.primary.withOpacity(0.18),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
                    color: done ? colors.accent : active ? colors.primary : colors.textMuted,
                  ),
                  child: Text(_labels[i], textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── CARD FORMULARIO ─────────────────────────────────────────────────────────

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({
    required this.colors,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.validateRequired,
    required this.validateEmail,
    required this.validatePassword,
    required this.validatePasswordConfirmation,
  });

  final _EcoColors colors;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final FormFieldValidator<String> validateRequired;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validatePasswordConfirmation;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [colors.cardGrad1, colors.cardGrad2]),
        boxShadow: [
          BoxShadow(color: colors.cardShadow, blurRadius: 40, offset: const Offset(0, 16)),
          BoxShadow(color: colors.accent.withOpacity(0.05), blurRadius: 60, spreadRadius: -10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(icon: Icons.person_outline_rounded, label: 'Datos personales', colors: colors),
                const SizedBox(height: 14),
                _AdaptiveTextField(
                  colors: colors, controller: fullNameController,
                  label: 'Nombre completo', icon: Icons.badge_outlined,
                  keyboardType: TextInputType.name, validator: validateRequired,
                ),
                const SizedBox(height: 12),
                _AdaptiveTextField(
                  colors: colors, controller: emailController,
                  label: 'Correo electrónico', icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress, validator: validateEmail,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, colors.primary.withOpacity(0.2), Colors.transparent]),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel(icon: Icons.lock_outline_rounded, label: 'Seguridad', colors: colors),
                const SizedBox(height: 14),
                _AdaptiveTextField(
                  colors: colors, controller: passwordController,
                  label: 'Contraseña', icon: Icons.lock_outline_rounded,
                  obscureText: obscurePassword, validator: validatePassword,
                  suffixIcon: _PasswordToggleIcon(obscure: obscurePassword, onToggle: onTogglePassword, colors: colors),
                ),
                const SizedBox(height: 12),
                _AdaptiveTextField(
                  colors: colors, controller: confirmPasswordController,
                  label: 'Confirmar contraseña', icon: Icons.lock_reset_rounded,
                  obscureText: obscureConfirmPassword, validator: validatePasswordConfirmation,
                  suffixIcon: _PasswordToggleIcon(obscure: obscureConfirmPassword, onToggle: onToggleConfirmPassword, colors: colors),
                ),
                const SizedBox(height: 10),
                // FIX: Expanded en el texto del hint para evitar overflow
                _PasswordHint(colors: colors),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label, required this.colors});
  final IconData icon;
  final String label;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: colors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: colors.primary),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.2),
          ),
        ),
      ],
    );
  }
}

// ─── PASSWORD HINT — FIX OVERFLOW ────────────────────────────────────────────

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 13, color: colors.primary.withOpacity(0.7)),
          ),
          const SizedBox(width: 7),
          // Expanded evita el overflow horizontal
          Expanded(
            child: Text(
              'Mínimo 6 caracteres. Las contraseñas deben coincidir.',
              style: TextStyle(fontSize: 11.5, color: colors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── POLICY CARD ─────────────────────────────────────────────────────────────

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.colors, required this.acceptedPolicy, required this.onChanged, required this.onReadPolicy});
  final _EcoColors colors;
  final bool acceptedPolicy;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onReadPolicy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: acceptedPolicy ? colors.accent.withOpacity(0.4) : colors.policyBorder,
          width: acceptedPolicy ? 1.5 : 1.0,
        ),
        color: acceptedPolicy ? colors.accent.withOpacity(0.07) : colors.policyBg,
        boxShadow: acceptedPolicy ? [BoxShadow(color: colors.accent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6))] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onChanged(!acceptedPolicy),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: acceptedPolicy ? colors.accent : Colors.transparent,
                      border: Border.all(
                        color: acceptedPolicy ? colors.accent : colors.primary.withOpacity(0.4),
                        width: 1.8,
                      ),
                      boxShadow: acceptedPolicy
                          ? [BoxShadow(color: colors.accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: acceptedPolicy ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded evita overflow en texto de política
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acepto la política de tratamiento de datos personales.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.45),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EcoPulse procesará ubicación, velocidad, sensores, trayectos, datos del vehículo y métricas de conducción.',
                        style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // FittedBox evita overflow del botón "Leer política"
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onReadPolicy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_rounded, size: 13, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Leer política completa',
                        style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: colors.primary),
                    ],
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

// ─── BOTÓN REGISTRO — FIX OVERFLOW TEXTO LARGO ───────────────────────────────

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.colors, required this.isLoading, required this.canRegister, required this.onPressed, required this.btnController});
  final _EcoColors colors;
  final bool isLoading;
  final bool canRegister;
  final VoidCallback? onPressed;
  final AnimationController btnController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (canRegister && !isLoading) ? (_) => btnController.reverse() : null,
      onTapUp: (canRegister && !isLoading)
          ? (_) {
              btnController.forward();
              HapticFeedback.mediumImpact();
              onPressed?.call();
            }
          : null,
      onTapCancel: () => btnController.forward(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: !canRegister || isLoading
              ? LinearGradient(colors: [colors.primary.withOpacity(0.4), colors.accent.withOpacity(0.4)])
              : LinearGradient(colors: [colors.primary, colors.accent], begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: (canRegister && !isLoading)
              ? [BoxShadow(color: colors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canRegister ? Icons.person_add_alt_1_rounded : Icons.lock_outline_rounded,
                      color: Colors.white, size: 19,
                    ),
                    const SizedBox(width: 8),
                    // Flexible evita overflow cuando el texto es largo
                    Flexible(
                      child: Text(
                        canRegister ? 'Crear cuenta' : 'Acepta la política primero',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700, letterSpacing: 0.1,
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

// ─── LOGIN LINK ───────────────────────────────────────────────────────────────

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tienes cuenta?', style: TextStyle(color: colors.textMuted, fontSize: 14)),
        _TapFeedback(
          onTap: () => context.go(AppRoutes.login),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('Iniciar sesión',
                style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

// ─── PASSWORD TOGGLE ─────────────────────────────────────────────────────────

class _PasswordToggleIcon extends StatelessWidget {
  const _PasswordToggleIcon({required this.obscure, required this.onToggle, required this.colors});
  final bool obscure;
  final VoidCallback onToggle;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggle();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
        child: Icon(
          obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          key: ValueKey(obscure), color: colors.textMuted, size: 19,
        ),
      ),
    );
  }
}

// ─── ADAPTIVE TEXT FIELD ─────────────────────────────────────────────────────

class _AdaptiveTextField extends StatefulWidget {
  const _AdaptiveTextField({
    required this.colors, required this.controller, required this.label, required this.icon,
    this.keyboardType, this.obscureText = false, this.validator, this.suffixIcon,
  });
  final _EcoColors colors;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  State<_AdaptiveTextField> createState() => _AdaptiveTextFieldState();
}

class _AdaptiveTextFieldState extends State<_AdaptiveTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _focused ? [BoxShadow(color: c.accent.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          validator: widget.validator,
          style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: c.textMuted, fontSize: 13.5),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.all(10),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _focused ? c.accent.withOpacity(0.15) : c.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon, size: 15, color: _focused ? c.accent : c.primary),
            ),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: c.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.inputBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.accent, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE76F51), width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE76F51), width: 1.5)),
            errorStyle: const TextStyle(color: Color(0xFFE76F51), fontSize: 11.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ),
    );
  }
}

// ─── TAP FEEDBACK ────────────────────────────────────────────────────────────

class _TapFeedback extends StatefulWidget {
  const _TapFeedback({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<_TapFeedback> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.95, upperBound: 1.0)..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); HapticFeedback.selectionClick(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}