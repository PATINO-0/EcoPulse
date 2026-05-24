import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _CardColors(isDark);
    final accent = _accentFor(widget.icon, c);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.982 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: c.cardBg,
            border: Border.all(
              color: _pressed ? accent.withOpacity(0.32) : c.border,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: (_pressed ? accent : c.shadow)
                    .withOpacity(_pressed ? 0.18 : 0.10),
                blurRadius: _pressed ? 22 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final isGrid = box.maxWidth < 260;

              if (isGrid) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconBox(accent: accent, icon: widget.icon, size: 44),
                        const Spacer(),
                        _Arrow(accent: accent, pressed: _pressed, c: c),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.8,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  _IconBox(accent: accent, icon: widget.icon, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Arrow(accent: accent, pressed: _pressed, c: c),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _accentFor(IconData icon, _CardColors c) {
    const tealIcons = [
      Icons.route_rounded,
      Icons.smart_toy_rounded,
      Icons.directions_car_rounded,
    ];
    const orangeIcons = [
      Icons.map_rounded,
      Icons.local_gas_station_rounded,
      Icons.settings_rounded,
    ];
    const greenIcons = [
      Icons.payments_rounded,
      Icons.privacy_tip_rounded,
    ];
    const redIcons = [
      Icons.build_circle_rounded,
    ];

    if (tealIcons.contains(icon)) return c.accent;
    if (orangeIcons.contains(icon)) return c.warning;
    if (greenIcons.contains(icon)) return c.success;
    if (redIcons.contains(icon)) return c.danger;
    return c.primary;
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.accent,
    required this.icon,
    required this.size,
  });

  final Color accent;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Icon(icon, color: accent, size: size * 0.46),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.accent,
    required this.pressed,
    required this.c,
  });

  final Color accent;
  final bool pressed;
  final _CardColors c;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: pressed ? accent.withOpacity(0.14) : c.arrowBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: pressed ? accent.withOpacity(0.26) : c.arrowBorder,
        ),
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 17,
        color: pressed ? accent : c.textMuted,
      ),
    );
  }
}

class _CardColors {
  final bool isDark;
  const _CardColors(this.isDark);

  Color get cardBg => isDark ? const Color(0xFF132033) : Colors.white;
  Color get border => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);
  Color get shadow => isDark ? Colors.black : const Color(0xFF5F96B3);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF13202B);
  Color get textSecondary =>
      isDark ? const Color(0xFF9BB1C2) : const Color(0xFF5D7383);
  Color get textMuted =>
      isDark ? const Color(0xFF6E8799) : const Color(0xFF8FA5B3);
  Color get arrowBg => isDark
      ? const Color(0xFF0F1A2C).withOpacity(0.82)
      : const Color(0xFFEAF2F8);
  Color get arrowBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);
  Color get warning => const Color(0xFFF4A261);
  Color get success => const Color(0xFF57B65F);
  Color get danger => const Color(0xFFE76F51);
}