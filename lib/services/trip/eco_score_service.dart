import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final ecoScoreServiceProvider = Provider<EcoScoreService>((ref) {
  return EcoScoreService();
});

class EcoScoreService {
  double calculateScore({
    required int aggressiveAccelerationEvents,
    required int hardBrakingEvents,
    required int irregularDrivingEvents,
    required int idleTimeSeconds,
    required double estimatedLitersPer100Km,
  }) {
    var score = 100.0;

    score -= aggressiveAccelerationEvents * 4;
    score -= hardBrakingEvents * 3.5;
    score -= irregularDrivingEvents * 2.5;

    if (idleTimeSeconds > 180) {
      score -= min(15, idleTimeSeconds / 60);
    }

    if (estimatedLitersPer100Km > 12) {
      score -= 8;
    } else if (estimatedLitersPer100Km > 9) {
      score -= 4;
    }

    return score.clamp(0, 100);
  }

  String buildScoreMessage(double score) {
    if (score >= 85) {
      return 'Excelente conducción eficiente. Mantén una velocidad constante.';
    }

    if (score >= 70) {
      return 'Buen desempeño. Puedes mejorar evitando aceleraciones y frenadas fuertes.';
    }

    if (score >= 50) {
      return 'Conducción mejorable. Revisa tus aceleraciones, frenadas y tiempos detenido.';
    }

    return 'Conducción ineficiente detectada. Maneja con suavidad para reducir consumo.';
  }
}