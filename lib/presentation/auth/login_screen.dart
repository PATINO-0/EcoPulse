import 'dart:math' as math;
import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── TEMA PROVIDER ────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── PALETA DE COLORES CONTEXTUAL ─────────────────────────────────────────────

class _EcoColors {
  final bool isDark;
  const _EcoColors(this.isDark);

  Color get bg => isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F5FA);
  Color get bgGrad1 => isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F5FA);
  Color get bgGrad2 => isDark ? const Color(0xFF0D1F3C) : const Color(0xFFE3EEF6);
  Color get bgGrad3 => isDark ? const Color(0xFF081420) : const Color(0xFFD8E9F3);

  Color get cardGrad1 => isDark
      ? const Color(0xFF162032).withOpacity(0.92)
      : Colors.white.withOpacity(0.95);
  Color get cardGrad2 => isDark
      ? const Color(0xFF0F1A2C).withOpacity(0.96)
      : const Color(0xFFF7FAFD).withOpacity(0.97);
  Color get cardBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);
  Color get cardShadow => isDark
      ? const Color(0xFF000000).withOpacity(0.3)
      : const Color(0xFF5F96B3).withOpacity(0.12);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary =>
      isDark ? const Color(0xFF86AFC4) : const Color(0xFF4A6375);
  Color get textMuted =>
      isDark ? const Color(0xFF5E7382) : const Color(0xFF7A95A6);

  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);

  Color get inputFill => isDark
      ? const Color(0xFF0A1628).withOpacity(0.6)
      : const Color(0xFFEEF4F9);
  Color get inputBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.15)
      : const Color(0xFF5F96B3).withOpacity(0.3);

  Color get logoGrad1 => const Color(0xFF0F1C2E);
  Color get logoGrad2 =>
      isDark ? const Color(0xFF1A2E47) : const Color(0xFF1A3A55);

  Color get chipBg => isDark
      ? const Color(0xFF162032).withOpacity(0.7)
      : const Color(0xFFE3EEF6).withOpacity(0.9);
  Color get chipBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.15)
      : const Color(0xFF5F96B3).withOpacity(0.35);

  Color get toggleBg =>
      isDark ? const Color(0xFF162032) : const Color(0xFFE3EEF6);
  Color get toggleBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.25)
      : const Color(0xFF5F96B3).withOpacity(0.4);

  Color get orb1 => isDark
      ? const Color(0xFF2EC4B6).withOpacity(0.13)
      : const Color(0xFF2EC4B6).withOpacity(0.10);
  Color get orb2 => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.11)
      : const Color(0xFF5F96B3).withOpacity(0.12);
  Color get orb3 => isDark
      ? const Color(0xFF2EC4B6).withOpacity(0.09)
      : const Color(0xFF2EC4B6).withOpacity(0.07);
  Color get dotColor => isDark
      ? const Color(0xFFFFFFFF).withOpacity(0.025)
      : const Color(0xFF5F96B3).withOpacity(0.08);
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool? _manualDark;

  bool _topBarVisible = true;
  double _scrollAccum = 0;
  double _lastProcessedOffset = 0;
  static const double _hideThreshold = 40.0;
  static const double _showThreshold = 20.0;

  late final AnimationController _enterController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
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

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _logoFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));
    _cardFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    ));
    _footerFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
    )..value = 1.0;
    _btnScale = _btnController;

    _topBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _topBarSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.0),
    ).animate(CurvedAnimation(
      parent: _topBarController,
      curve: Curves.easeInOutCubic,
    ));
    _topBarFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _topBarController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _scrollController.addListener(_onScroll);
    _enterController.forward();
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // Sin rebote: ignorar over-scroll en extremos
    if (offset < 0) return;
    if (_scrollController.position.maxScrollExtent > 0 &&
        offset > _scrollController.position.maxScrollExtent) return;

    final delta = offset - _lastProcessedOffset;
    _lastProcessedOffset = offset;

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
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _signIn() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (exception) {
      _showMessage(exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              backgroundColor: const Color(0xFFF3F6F8),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F96B3).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Color(0xFF5F96B3), size: 24),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Recuperar contraseña',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF13202B),
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe tu correo y te enviaremos instrucciones para recuperar tu cuenta.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5E7382),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: Color(0xFF13202B), fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle:
                            const TextStyle(color: Color(0xFF5E7382)),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF5F96B3), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFD8E2E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFD8E2E8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF5F96B3), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                    color: Color(0xFFD8E2E8)),
                              ),
                            ),
                            child: const Text('Cancelar',
                                style:
                                    TextStyle(color: Color(0xFF5E7382))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    setDialogState(() => isSending = true);
                                    try {
                                      await ref
                                          .read(authRepositoryProvider)
                                          .sendPasswordResetEmail(
                                            email: resetEmailController.text,
                                          );
                                      if (!mounted) return;
                                      Navigator.of(dialogContext).pop();
                                      _showMessage(
                                        'Correo de recuperación enviado. Revisa tu bandeja de entrada.',
                                      );
                                    } catch (exception) {
                                      if (!mounted) return;
                                      Navigator.of(dialogContext).pop();
                                      _showMessage(exception
                                          .toString()
                                          .replaceFirst('Exception: ', ''));
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5F96B3),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Enviar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    resetEmailController.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF0F1C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }
    if (!value.contains('@')) return 'Ingresa un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    if (value.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = _resolveIsDark(context);
    final colors = _EcoColors(isDark);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 350),
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: colors.bg,
        body: Stack(
          children: [
            _AnimatedBackground(
              orbitController: _orbitController,
              size: size,
              colors: colors,
            ),
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                // ← SIN rebote en extremos
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 64,
                  left: size.width > 600 ? size.width * 0.15 : 24,
                  right: size.width > 600 ? size.width * 0.15 : 24,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: _LogoHeader(colors: colors),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _GlassFormCard(
                          colors: colors,
                          isDark: isDark,
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          isLoading: _isLoading,
                          btnScale: _btnScale,
                          btnController: _btnController,
                          onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onSignIn: _signIn,
                          onForgotPassword: _showResetPasswordDialog,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _footerFade,
                      child: _Footer(colors: colors),
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

// ─── TOGGLE BOTÓN MODO ────────────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.isDark,
    required this.colors,
    required this.toggleController,
    required this.onToggle,
  });

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
        width: 78,
        height: 38,
        decoration: BoxDecoration(
          color: colors.toggleBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.toggleBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
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
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 16,
                    color: isDark ? colors.textMuted : const Color(0xFFF4A261),
                  ),
                ),
                AnimatedOpacity(
                  opacity: isDark ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.nightlight_round,
                    size: 16,
                    color: isDark ? colors.accent : colors.textMuted,
                  ),
                ),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2EC4B6), const Color(0xFF5F96B3)]
                        : [const Color(0xFFF4A261), const Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? colors.accent : const Color(0xFFF4A261))
                          .withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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

// ─── FONDO ANIMADO ────────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.orbitController,
    required this.size,
    required this.colors,
  });

  final AnimationController orbitController;
  final Size size;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbitController,
      builder: (context, _) {
        final t = orbitController.value;
        final angle1 = t * 2 * math.pi;
        final angle2 = t * 2 * math.pi + math.pi;
        final angle3 = t * 2 * math.pi * 0.6 + math.pi * 0.5;

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
              top: size.height * 0.08 + math.sin(angle1) * size.height * 0.04,
              right: -size.width * 0.2 + math.cos(angle1) * size.width * 0.03,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [colors.orb1, colors.orb1.withOpacity(0)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.5 + math.sin(angle2) * size.height * 0.06,
              left: -size.width * 0.3 + math.cos(angle2) * size.width * 0.04,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [colors.orb2, colors.orb2.withOpacity(0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1 + math.cos(angle3) * size.height * 0.04,
              right: size.width * 0.1 + math.sin(angle3) * size.width * 0.05,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [colors.orb3, colors.orb3.withOpacity(0)],
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: size,
              painter: _DotGridPainter(dotColor: colors.dotColor),
            ),
            Positioned(
              top: size.height * 0.38,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colors.accent.withOpacity(0.15),
                      colors.primary.withOpacity(0.2),
                      colors.accent.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
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
    final paint = Paint()
      ..color = dotColor
      ..strokeCap = StrokeCap.round;
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

// ─── LOGO + HEADER ────────────────────────────────────────────────────────────

class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.logoGrad1, colors.logoGrad2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: colors.accent.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A1628).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.eco_rounded, size: 40, color: colors.accent),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 350),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          child: Text(AppConstants.appName, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.accent.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 13, color: colors.accent),
              const SizedBox(width: 5),
              Text(
                'Conducción eficiente',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 350),
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            height: 1.6,
          ),
          child: const Text(
            'Inicia sesión para registrar tus trayectos\ny consultar tus métricas de conducción.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─── CARD GLASSMORPHISM ───────────────────────────────────────────────────────

class _GlassFormCard extends StatelessWidget {
  const _GlassFormCard({
    required this.colors,
    required this.isDark,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.btnScale,
    required this.btnController,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.validateEmail,
    required this.validatePassword,
  });

  final _EcoColors colors;
  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final Animation<double> btnScale;
  final AnimationController btnController;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.cardGrad1, colors.cardGrad2],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: colors.accent.withOpacity(0.05),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_outline_rounded,
                          size: 18, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          child: const Text('Bienvenido de vuelta'),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          style: TextStyle(
                              fontSize: 12.5, color: colors.textMuted),
                          child: const Text('Ingresa tus credenciales'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colors.primary.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _AdaptiveTextField(
                  colors: colors,
                  controller: emailController,
                  label: 'Correo electrónico',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: 14),
                _AdaptiveTextField(
                  colors: colors,
                  controller: passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: obscurePassword,
                  validator: validatePassword,
                  suffixIcon: _PasswordToggleIcon(
                    obscure: obscurePassword,
                    onToggle: onTogglePassword,
                    colors: colors,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TapFeedback(
                    onTap: onForgotPassword,
                    child: Text(
                      'Olvidé mi contraseña',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: btnScale,
                  child: _PremiumLoginButton(
                    colors: colors,
                    isLoading: isLoading,
                    onPressed: onSignIn,
                    btnController: btnController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PASSWORD TOGGLE ANIMADO ──────────────────────────────────────────────────

class _PasswordToggleIcon extends StatelessWidget {
  const _PasswordToggleIcon({
    required this.obscure,
    required this.onToggle,
    required this.colors,
  });

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
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          key: ValueKey(obscure),
          color: colors.textMuted,
          size: 19,
        ),
      ),
    );
  }
}

// ─── CAMPO ADAPTATIVO ─────────────────────────────────────────────────────────

class _AdaptiveTextField extends StatefulWidget {
  const _AdaptiveTextField({
    required this.colors,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: c.accent.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          validator: widget.validator,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: c.textMuted, fontSize: 14),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _focused
                    ? c.accent.withOpacity(0.15)
                    : c.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon,
                  size: 16, color: _focused ? c.accent : c.primary),
            ),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: c.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE76F51), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE76F51), width: 1.5),
            ),
            errorStyle:
                const TextStyle(color: Color(0xFFE76F51), fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }
}

// ─── TAP FEEDBACK ─────────────────────────────────────────────────────────────

class _TapFeedback extends StatefulWidget {
  const _TapFeedback({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<_TapFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── BOTÓN PREMIUM ────────────────────────────────────────────────────────────

class _PremiumLoginButton extends StatelessWidget {
  const _PremiumLoginButton({
    required this.colors,
    required this.isLoading,
    required this.onPressed,
    required this.btnController,
  });

  final _EcoColors colors;
  final bool isLoading;
  final VoidCallback onPressed;
  final AnimationController btnController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: isLoading ? null : (_) => btnController.reverse(),
      onTapUp: isLoading
          ? null
          : (_) {
              btnController.forward();
              HapticFeedback.mediumImpact();
              onPressed();
            },
      onTapCancel: () => btnController.forward(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.5),
                    colors.accent.withOpacity(0.5),
                  ],
                )
              : LinearGradient(
                  colors: [colors.primary, colors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: colors.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── FOOTER ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.colors});
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
                icon: Icons.route_rounded, label: 'Trayectos', colors: colors),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.local_gas_station_rounded,
                label: 'Consumo',
                colors: colors),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.eco_rounded, label: 'Eco score', colors: colors),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 350),
              style: TextStyle(color: colors.textMuted, fontSize: 14),
              child: const Text('¿No tienes cuenta?'),
            ),
            _TapFeedback(
              onTap: () => context.go(AppRoutes.register),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Crear cuenta',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final _EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}