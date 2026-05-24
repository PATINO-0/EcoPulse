import 'package:flutter/material.dart';

class MapColors {
  final bool isDark;
  const MapColors(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF0A1628) : const Color(0xFFF2F7FB);

  Color get background2 =>
      isDark ? const Color(0xFF0D1F3C) : const Color(0xFFE5EEF5);

  Color get card => isDark ? const Color(0xFF132033) : Colors.white;

  Color get cardAlt =>
      isDark ? const Color(0xFF0F1A2C) : const Color(0xFFF7FAFD);

  Color get border => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);

  Color get shadow => isDark
      ? Colors.black.withOpacity(0.28)
      : const Color(0xFF5F96B3).withOpacity(0.10);

  Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF13202B);

  Color get textSecondary => isDark
      ? const Color(0xFF9BB1C2)
      : const Color(0xFF5D7383);

  Color get textMuted => isDark
      ? const Color(0xFF6E8799)
      : const Color(0xFF8FA5B3);

  Color get primary => const Color(0xFF5F96B3);
  Color get accent => const Color(0xFF2EC4B6);
  Color get warning => const Color(0xFFF4A261);
  Color get success => const Color(0xFF57B65F);
  Color get danger => const Color(0xFFE76F51);

  Color get heroTop =>
      isDark ? const Color(0xFF12243C) : const Color(0xFF17314E);

  Color get heroBottom =>
      isDark ? const Color(0xFF0E1B2D) : const Color(0xFF0F2339);

  Color get chip => isDark
      ? const Color(0xFF0F1A2C).withOpacity(0.85)
      : const Color(0xFFEAF2F8).withOpacity(0.96);

  Color get chipBorder => isDark
      ? const Color(0xFF5F96B3).withOpacity(0.18)
      : const Color(0xFF5F96B3).withOpacity(0.22);
}