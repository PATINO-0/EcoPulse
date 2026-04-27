import 'package:ecopulse/data/models/eco_feedback_message_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/sensor_sample_model.dart';

class TripSessionStateModel {
  final bool isTracking;
  final bool isAutoDetectionEnabled;
  final bool isSaving;
  final bool visualAlertsEnabled;
  final bool voiceAlertsEnabled;
  final bool realtimeFeedbackEnabled;
  final String? activeTripId;
  final String? lastCompletedTripId;
  final String? selectedVehicleId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final LocationSampleModel? currentLocation;
  final SensorSampleModel latestSensorSample;
  final List<LocationSampleModel> routePoints;
  final double distanceKm;
  final int durationSeconds;
  final int idleTimeSeconds;
  final int savedPointsCount;
  final double currentAccelerationMps2;
  final double roadGradePercent;
  final double estimatedFuelGallons;
  final double estimatedFuelLiters;
  final double estimatedKmPerGallon;
  final double estimatedLitersPer100Km;
  final int aggressiveAccelerationEvents;
  final int hardBrakingEvents;
  final int irregularDrivingEvents;
  final double ecoScore;
  final EcoFeedbackMessageModel? lastFeedbackMessage;
  final String estimationMethod;
  final String statusMessage;
  final List<String> warnings;

  const TripSessionStateModel({
    required this.isTracking,
    required this.isAutoDetectionEnabled,
    required this.isSaving,
    required this.visualAlertsEnabled,
    required this.voiceAlertsEnabled,
    required this.realtimeFeedbackEnabled,
    required this.latestSensorSample,
    required this.routePoints,
    required this.distanceKm,
    required this.durationSeconds,
    required this.idleTimeSeconds,
    required this.savedPointsCount,
    required this.currentAccelerationMps2,
    required this.roadGradePercent,
    required this.estimatedFuelGallons,
    required this.estimatedFuelLiters,
    required this.estimatedKmPerGallon,
    required this.estimatedLitersPer100Km,
    required this.aggressiveAccelerationEvents,
    required this.hardBrakingEvents,
    required this.irregularDrivingEvents,
    required this.ecoScore,
    required this.estimationMethod,
    required this.statusMessage,
    required this.warnings,
    this.activeTripId,
    this.lastCompletedTripId,
    this.selectedVehicleId,
    this.startedAt,
    this.endedAt,
    this.currentLocation,
    this.lastFeedbackMessage,
  });

  factory TripSessionStateModel.initial() {
    return TripSessionStateModel(
      isTracking: false,
      isAutoDetectionEnabled: false,
      isSaving: false,
      visualAlertsEnabled: true,
      voiceAlertsEnabled: true,
      realtimeFeedbackEnabled: true,
      latestSensorSample: SensorSampleModel.empty(),
      routePoints: const [],
      distanceKm: 0,
      durationSeconds: 0,
      idleTimeSeconds: 0,
      savedPointsCount: 0,
      currentAccelerationMps2: 0,
      roadGradePercent: 0,
      estimatedFuelGallons: 0,
      estimatedFuelLiters: 0,
      estimatedKmPerGallon: 0,
      estimatedLitersPer100Km: 0,
      aggressiveAccelerationEvents: 0,
      hardBrakingEvents: 0,
      irregularDrivingEvents: 0,
      ecoScore: 100,
      estimationMethod: 'physical_rules_fallback',
      statusMessage: 'Trayecto inactivo.',
      warnings: const [],
    );
  }

  double get currentSpeedKmh {
    return currentLocation?.speedKmh ?? 0;
  }

  bool get hasRoute {
    return routePoints.length >= 2;
  }

  int get totalDrivingEvents {
    return aggressiveAccelerationEvents +
        hardBrakingEvents +
        irregularDrivingEvents;
  }

  TripSessionStateModel copyWith({
    bool? isTracking,
    bool? isAutoDetectionEnabled,
    bool? isSaving,
    bool? visualAlertsEnabled,
    bool? voiceAlertsEnabled,
    bool? realtimeFeedbackEnabled,
    String? activeTripId,
    String? lastCompletedTripId,
    String? selectedVehicleId,
    DateTime? startedAt,
    DateTime? endedAt,
    LocationSampleModel? currentLocation,
    SensorSampleModel? latestSensorSample,
    List<LocationSampleModel>? routePoints,
    double? distanceKm,
    int? durationSeconds,
    int? idleTimeSeconds,
    int? savedPointsCount,
    double? currentAccelerationMps2,
    double? roadGradePercent,
    double? estimatedFuelGallons,
    double? estimatedFuelLiters,
    double? estimatedKmPerGallon,
    double? estimatedLitersPer100Km,
    int? aggressiveAccelerationEvents,
    int? hardBrakingEvents,
    int? irregularDrivingEvents,
    double? ecoScore,
    EcoFeedbackMessageModel? lastFeedbackMessage,
    String? estimationMethod,
    String? statusMessage,
    List<String>? warnings,
    bool clearTripId = false,
    bool clearLastCompletedTripId = false,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
    bool clearRoutePoints = false,
    bool clearFeedbackMessage = false,
  }) {
    return TripSessionStateModel(
      isTracking: isTracking ?? this.isTracking,
      isAutoDetectionEnabled:
          isAutoDetectionEnabled ?? this.isAutoDetectionEnabled,
      isSaving: isSaving ?? this.isSaving,
      visualAlertsEnabled: visualAlertsEnabled ?? this.visualAlertsEnabled,
      voiceAlertsEnabled: voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      realtimeFeedbackEnabled:
          realtimeFeedbackEnabled ?? this.realtimeFeedbackEnabled,
      activeTripId: clearTripId ? null : activeTripId ?? this.activeTripId,
      lastCompletedTripId: clearLastCompletedTripId
          ? null
          : lastCompletedTripId ?? this.lastCompletedTripId,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      currentLocation: currentLocation ?? this.currentLocation,
      latestSensorSample: latestSensorSample ?? this.latestSensorSample,
      routePoints: clearRoutePoints ? const [] : routePoints ?? this.routePoints,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      idleTimeSeconds: idleTimeSeconds ?? this.idleTimeSeconds,
      savedPointsCount: savedPointsCount ?? this.savedPointsCount,
      currentAccelerationMps2:
          currentAccelerationMps2 ?? this.currentAccelerationMps2,
      roadGradePercent: roadGradePercent ?? this.roadGradePercent,
      estimatedFuelGallons:
          estimatedFuelGallons ?? this.estimatedFuelGallons,
      estimatedFuelLiters: estimatedFuelLiters ?? this.estimatedFuelLiters,
      estimatedKmPerGallon:
          estimatedKmPerGallon ?? this.estimatedKmPerGallon,
      estimatedLitersPer100Km:
          estimatedLitersPer100Km ?? this.estimatedLitersPer100Km,
      aggressiveAccelerationEvents:
          aggressiveAccelerationEvents ?? this.aggressiveAccelerationEvents,
      hardBrakingEvents: hardBrakingEvents ?? this.hardBrakingEvents,
      irregularDrivingEvents:
          irregularDrivingEvents ?? this.irregularDrivingEvents,
      ecoScore: ecoScore ?? this.ecoScore,
      lastFeedbackMessage: clearFeedbackMessage
          ? null
          : lastFeedbackMessage ?? this.lastFeedbackMessage,
      estimationMethod: estimationMethod ?? this.estimationMethod,
      statusMessage: statusMessage ?? this.statusMessage,
      warnings: warnings ?? this.warnings,
    );
  }
}