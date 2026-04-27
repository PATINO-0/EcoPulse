import 'package:ecopulse/services/trip/eco_score_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EcoScoreService', () {
    test('should return 100 when there are no inefficient events', () {
      final service = EcoScoreService();

      final score = service.calculateScore(
        aggressiveAccelerationEvents: 0,
        hardBrakingEvents: 0,
        irregularDrivingEvents: 0,
        idleTimeSeconds: 0,
        estimatedLitersPer100Km: 6,
      );

      expect(score, 100);
    });

    test('should decrease score when driving events are present', () {
      final service = EcoScoreService();

      final score = service.calculateScore(
        aggressiveAccelerationEvents: 3,
        hardBrakingEvents: 2,
        irregularDrivingEvents: 1,
        idleTimeSeconds: 240,
        estimatedLitersPer100Km: 10,
      );

      expect(score, lessThan(100));
      expect(score, greaterThanOrEqualTo(0));
    });

    test('should never return a negative score', () {
      final service = EcoScoreService();

      final score = service.calculateScore(
        aggressiveAccelerationEvents: 100,
        hardBrakingEvents: 100,
        irregularDrivingEvents: 100,
        idleTimeSeconds: 10000,
        estimatedLitersPer100Km: 30,
      );

      expect(score, 0);
    });
  });
}