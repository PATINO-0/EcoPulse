import 'dart:async';
import 'dart:math' as math;
import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─── PALETA COHERENTE ────────────────────────────────────────────────────────

class _EcoColors {
  static Color get bg => const Color(0xFF0A1628);
  static Color get bgGrad1 => const Color(0xFF0A1628);
  static Color get bgGrad2 => const Color(0xFF0D1F3C);
  static Color get bgGrad3 => const Color(0xFF081420);
  static Color get primary => const Color(0xFF5F96B3);
  static Color get accent => const Color(0xFF2EC4B6);
  static Color get textPrimary => Colors.white;
  static Color get textSecondary => const Color(0xFF86AFC4);
  static Color get textMuted => const Color(0xFF5E7382);
  static Color get cardGrad1 => const Color(0xFF162032).withOpacity(0.9);
  static Color get cardBorder => const Color(0xFF5F96B3).withOpacity(0.2);
  static Color get orb1 => const Color(0xFF2EC4B6).withOpacity(0.14);
  static Color get orb2 => const Color(0xFF5F96B3).withOpacity(0.12);
  static Color get orb3 => const Color(0xFF2EC4B6).withOpacity(0.08);
  static Color get dotColor => const Color(0xFFFFFFFF).withOpacity(0.025);
  static Color get roadColor => const Color(0xFF1A2E47);
  static Color get roadLine => const Color(0xFF5F96B3).withOpacity(0.5);
  static Color get logoGrad1 => const Color(0xFF0F1C2E);
  static Color get logoGrad2 => const Color(0xFF1A3A55);
}

// ─── SPLASH SCREEN ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── animaciones de entrada ────────────────────────────────────────────────
  late final AnimationController _enterController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // ── orbes de fondo ────────────────────────────────────────────────────────
  late final AnimationController _orbitController;

  // ── carro animado en ruta ─────────────────────────────────────────────────
  late final AnimationController _carController;
  late final Animation<double> _carPosition; // 0.0 → 1.0 a lo largo de la ruta
  late final Animation<double> _carBounce;

  // ── barra de carga ────────────────────────────────────────────────────────
  late final AnimationController _progressController;
  late final Animation<double> _progressValue;

  // ── pulso del logo ────────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── salida ────────────────────────────────────────────────────────────────
  late final AnimationController _exitController;
  late final Animation<double> _exitFade;

  // estado del label de carga
  int _loadingStep = 0;
  static const _loadingLabels = [
    'Iniciando EcoPulse...',
    'Validando sesión...',
    'Cargando configuración...',
    'Listo para conducir 🚗',
  ];

  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── entrada ──────────────────────────────────────────────────────────────
    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)));
    _logoFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));

    _titleFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 0.65, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 0.65, curve: Curves.easeOut)));

    _subtitleFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.5, 0.8, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _enterController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    // ── orbes ─────────────────────────────────────────────────────────────────
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

    // ── carro ─────────────────────────────────────────────────────────────────
    _carController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _carPosition = Tween<double>(begin: -0.12, end: 1.12).animate(
      CurvedAnimation(parent: _carController, curve: Curves.linear));
    _carBounce = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

    // ── pulso ─────────────────────────────────────────────────────────────────
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // ── progreso ──────────────────────────────────────────────────────────────
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    // ── salida ────────────────────────────────────────────────────────────────
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // ── step labels ───────────────────────────────────────────────────────────
    _progressController.addListener(() {
      final v = _progressValue.value;
      int step = 0;
      if (v >= 0.25) step = 1;
      if (v >= 0.6)  step = 2;
      if (v >= 0.92) step = 3;
      if (_loadingStep != step && mounted) setState(() => _loadingStep = step);
    });

    // ── arranque ──────────────────────────────────────────────────────────────
    _enterController.forward();
    _progressController.forward();
    _openInitialScreen();
  }

  // ── lógica original intacta ───────────────────────────────────────────────
  Future<void> _openInitialScreen() async {
    // mínimo 4 segundos en pantalla
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 4000)),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);

    if (!mounted || _navigationDone) return;
    _navigationDone = true;

    await _exitController.forward();
    if (!mounted) return;

    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      context.go(AppRoutes.login);
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _enterController.dispose();
    _orbitController.dispose();
    _carController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.2 : 28.0;

    return Scaffold(
      backgroundColor: _EcoColors.bg,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          children: [
            // ── fondo animado ────────────────────────────────────────────
            _AnimatedBackground(orbitController: _orbitController, size: size),

            // ── contenido principal ──────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ── logo con pulso ───────────────────────────────────
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: _LogoWidget(pulseScale: _pulseScale, pulseOpacity: _pulseOpacity),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── nombre app ───────────────────────────────────────
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _EcoColors.textPrimary,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── subtítulo ────────────────────────────────────────
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        AppConstants.appSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _EcoColors.textSecondary,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── card animación del carro ─────────────────────────
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _CarRouteCard(
                          carPosition: _carPosition,
                          carBounce: _carBounce,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── barra de progreso ────────────────────────────────
                    FadeTransition(
                      opacity: _cardFade,
                      child: _ProgressSection(
                        progressValue: _progressValue,
                        loadingLabel: _loadingLabels[_loadingStep],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // ── versión / firma ──────────────────────────────────
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        'v1.0 · Conducción eficiente',
                        style: TextStyle(fontSize: 11, color: _EcoColors.textMuted, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
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

// ─── LOGO CON PULSO ──────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  const _LogoWidget({required this.pulseScale, required this.pulseOpacity});
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseScale, pulseOpacity]),
      builder: (context, _) {
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // anillo de pulso exterior
              Transform.scale(
                scale: pulseScale.value * 1.4,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _EcoColors.accent.withOpacity(pulseOpacity.value * 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // anillo de pulso interior
              Transform.scale(
                scale: pulseScale.value * 1.15,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _EcoColors.accent.withOpacity(pulseOpacity.value * 0.08),
                  ),
                ),
              ),
              // logo principal
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_EcoColors.logoGrad1, _EcoColors.logoGrad2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _EcoColors.accent.withOpacity(0.4), width: 1.8),
                  boxShadow: [
                    BoxShadow(color: _EcoColors.accent.withOpacity(0.3), blurRadius: 30, spreadRadius: 4),
                    BoxShadow(color: const Color(0xFF000000).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Icon(Icons.eco_rounded, size: 48, color: _EcoColors.accent),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── CARD CON ANIMACIÓN DEL CARRO ────────────────────────────────────────────

class _CarRouteCard extends StatelessWidget {
  const _CarRouteCard({required this.carPosition, required this.carBounce});
  final Animation<double> carPosition;
  final Animation<double> carBounce;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_EcoColors.cardGrad1, const Color(0xFF0F1A2C).withOpacity(0.96)],
        ),
        border: Border.all(color: _EcoColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(color: _EcoColors.accent.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: Listenable.merge([carPosition, carBounce]),
          builder: (context, _) {
            return CustomPaint(
              painter: _CarRoutePainter(
                carPos: carPosition.value,
                bounce: carBounce.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── PAINTER: RUTA + CARRO ────────────────────────────────────────────────────

class _CarRoutePainter extends CustomPainter {
  const _CarRoutePainter({required this.carPos, required this.bounce});
  final double carPos;
  final double bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.62;
    final roadH = h * 0.32;

    // ── carretera ────────────────────────────────────────────────────────────
    final roadPaint = Paint()..color = _EcoColors.roadColor;
    final roadRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, midY - roadH / 2, w, roadH),
      const Radius.circular(6),
    );
    canvas.drawRRect(roadRect, roadPaint);

    // bordes de carretera (líneas blancas)
    final edgePaint = Paint()
      ..color = _EcoColors.primary.withOpacity(0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, midY - roadH / 2 + 2), Offset(w, midY - roadH / 2 + 2), edgePaint);
    canvas.drawLine(Offset(0, midY + roadH / 2 - 2), Offset(w, midY + roadH / 2 - 2), edgePaint);

    // línea central discontinua
    final dashPaint = Paint()
      ..color = _EcoColors.roadLine
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const dashLen = 18.0;
    const gapLen = 12.0;
    // offset para animar el movimiento de las líneas
    final dashOffset = (carPos * (dashLen + gapLen) * 6) % (dashLen + gapLen);
    double x = -dashOffset;
    while (x < w + dashLen) {
      canvas.drawLine(Offset(x, midY), Offset(x + dashLen, midY), dashPaint);
      x += dashLen + gapLen;
    }

    // ── árboles decorativos ───────────────────────────────────────────────────
    _drawTree(canvas, w * 0.12, midY - roadH / 2 - 14, 1.0);
    _drawTree(canvas, w * 0.38, midY - roadH / 2 - 10, 0.75);
    _drawTree(canvas, w * 0.65, midY - roadH / 2 - 16, 1.1);
    _drawTree(canvas, w * 0.88, midY - roadH / 2 - 12, 0.9);

    // ── carro ─────────────────────────────────────────────────────────────────
    final carX = carPos * w;
    final carY = midY - roadH / 2 - 2 + bounce * 0.8; // bounce suave

    _drawCar(canvas, carX, carY);
  }

  void _drawTree(Canvas canvas, double x, double y, double scale) {
    final trunkPaint = Paint()..color = const Color(0xFF3A2A1A).withOpacity(0.7);
    final leafPaint = Paint()..color = _EcoColors.accent.withOpacity(0.55);
    // tronco
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y + 7 * scale), width: 3 * scale, height: 8 * scale),
      const Radius.circular(2),
    );
    canvas.drawRRect(trunkRect, trunkPaint);
    // copa
    canvas.drawCircle(Offset(x, y), 7 * scale, leafPaint);
    canvas.drawCircle(Offset(x - 4 * scale, y + 3 * scale), 5 * scale, leafPaint);
    canvas.drawCircle(Offset(x + 4 * scale, y + 3 * scale), 5 * scale, leafPaint);
  }

  void _drawCar(Canvas canvas, double cx, double groundY) {
    // tamaño base del carro
    const carW = 52.0;
    const carH = 22.0;
    const bodyOffY = -carH;

    // ── sombra del carro ──────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 2), width: carW * 0.85, height: 5),
      shadowPaint,
    );

    // ── carrocería ────────────────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [_EcoColors.primary, _EcoColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(cx - carW / 2, groundY + bodyOffY, carW, carH));

    final bodyPath = Path();
    // base rectangular con esquinas redondeadas
    bodyPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - carW / 2, groundY + bodyOffY + carH * 0.35, carW, carH * 0.65),
      const Radius.circular(5),
    ));
    canvas.drawPath(bodyPath, bodyPaint);

    // cabina (techo)
    final roofPaint = Paint()
      ..shader = LinearGradient(
        colors: [_EcoColors.primary.withOpacity(0.9), _EcoColors.accent.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - carW * 0.32, groundY + bodyOffY, carW * 0.64, carH * 0.5));

    final roofPath = Path()
      ..moveTo(cx - carW * 0.28, groundY + bodyOffY + carH * 0.38)
      ..lineTo(cx - carW * 0.2, groundY + bodyOffY + carH * 0.04)
      ..quadraticBezierTo(cx, groundY + bodyOffY - carH * 0.02, cx + carW * 0.2, groundY + bodyOffY + carH * 0.04)
      ..lineTo(cx + carW * 0.28, groundY + bodyOffY + carH * 0.38)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // ventanas
    final windowPaint = Paint()..color = const Color(0xFF0A1628).withOpacity(0.7);
    // ventana trasera
    final rearWindow = Path()
      ..moveTo(cx - carW * 0.24, groundY + bodyOffY + carH * 0.37)
      ..lineTo(cx - carW * 0.16, groundY + bodyOffY + carH * 0.08)
      ..lineTo(cx - carW * 0.02, groundY + bodyOffY + carH * 0.07)
      ..lineTo(cx - carW * 0.02, groundY + bodyOffY + carH * 0.37)
      ..close();
    canvas.drawPath(rearWindow, windowPaint);
    // ventana delantera
    final frontWindow = Path()
      ..moveTo(cx + carW * 0.02, groundY + bodyOffY + carH * 0.07)
      ..lineTo(cx + carW * 0.18, groundY + bodyOffY + carH * 0.08)
      ..lineTo(cx + carW * 0.24, groundY + bodyOffY + carH * 0.37)
      ..lineTo(cx + carW * 0.02, groundY + bodyOffY + carH * 0.37)
      ..close();
    canvas.drawPath(frontWindow, windowPaint);

    // línea divisoria de ventanas
    final divPaint = Paint()..color = _EcoColors.accent.withOpacity(0.5)..strokeWidth = 1;
    canvas.drawLine(
      Offset(cx, groundY + bodyOffY + carH * 0.07),
      Offset(cx, groundY + bodyOffY + carH * 0.37),
      divPaint,
    );

    // ── ruedas ────────────────────────────────────────────────────────────────
    final wheelPaint = Paint()..color = const Color(0xFF0A0A0A);
    final rimPaint = Paint()..color = _EcoColors.primary.withOpacity(0.8);
    final hubPaint = Paint()..color = _EcoColors.accent;

    final wheels = [
      Offset(cx - carW * 0.28, groundY + 2.0),
      Offset(cx + carW * 0.28, groundY + 2.0),
    ];
    for (final w in wheels) {
      canvas.drawCircle(w, 6.5, wheelPaint);
      canvas.drawCircle(w, 4.5, rimPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(w, 2.0, hubPaint);
    }

    // ── faros delanteros (glow) ───────────────────────────────────────────────
    final headlightGlow = Paint()
      ..color = _EcoColors.accent.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx + carW * 0.44, groundY + bodyOffY + carH * 0.68), 5, headlightGlow);

    final headlightPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(Offset(cx + carW * 0.44, groundY + bodyOffY + carH * 0.68), 3, headlightPaint);

    // ── escape (partículas) ───────────────────────────────────────────────────
    final exhaustPaint = Paint()
      ..color = _EcoColors.accent.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final exhaustOffset = carPos * 60;
    for (int i = 0; i < 3; i++) {
      final px = cx - carW * 0.5 - 8.0 - i * 6.0 - (exhaustOffset * 0.3 % 6);
      final py = groundY + bodyOffY + carH * 0.75 - i * 1.5;
      canvas.drawCircle(Offset(px, py), 3.5 - i * 0.8, exhaustPaint);
    }
  }

  @override
  bool shouldRepaint(_CarRoutePainter old) =>
      old.carPos != carPos || old.bounce != bounce;
}

// ─── SECCIÓN DE PROGRESO ─────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progressValue, required this.loadingLabel});
  final Animation<double> progressValue;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressValue,
      builder: (context, _) {
        return Column(
          children: [
            // barra de progreso premium
            Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _EcoColors.primary.withOpacity(0.12),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressValue.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [_EcoColors.primary, _EcoColors.accent],
                    ),
                    boxShadow: [
                      BoxShadow(color: _EcoColors.accent.withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // label animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                loadingLabel,
                key: ValueKey(loadingLabel),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _EcoColors.textMuted, letterSpacing: 0.2),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── FONDO ANIMADO ────────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.orbitController, required this.size});
  final AnimationController orbitController;
  final Size size;

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
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_EcoColors.bgGrad1, _EcoColors.bgGrad2, _EcoColors.bgGrad3],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.05 + math.sin(a1) * size.height * 0.04,
              right: -size.width * 0.2 + math.cos(a1) * size.width * 0.03,
              child: Container(
                width: size.width * 0.9, height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_EcoColors.orb1, _EcoColors.orb1.withOpacity(0)]),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.5 + math.sin(a2) * size.height * 0.06,
              left: -size.width * 0.3 + math.cos(a2) * size.width * 0.04,
              child: Container(
                width: size.width * 0.85, height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_EcoColors.orb2, _EcoColors.orb2.withOpacity(0)]),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1 + math.cos(a3) * size.height * 0.04,
              right: size.width * 0.1 + math.sin(a3) * size.width * 0.05,
              child: Container(
                width: size.width * 0.5, height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_EcoColors.orb3, _EcoColors.orb3.withOpacity(0)]),
                ),
              ),
            ),
            CustomPaint(
              size: size,
              painter: _DotGridPainter(dotColor: _EcoColors.dotColor),
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