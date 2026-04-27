import 'dart:async';

import 'package:ecopulse/data/models/driving_event_model.dart';
import 'package:ecopulse/data/models/eco_feedback_message_model.dart';
import 'package:ecopulse/data/models/fuel_estimation_result_model.dart';
import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:ecopulse/data/models/sensor_sample_model.dart';
import 'package:ecopulse/data/models/trip_point_sample_model.dart';
import 'package:ecopulse/data/models/trip_session_state_model.dart';
import 'package:ecopulse/data/models/user_settings_model.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/data/repositories/driving_event_repository.dart';
import 'package:ecopulse/data/repositories/fuel_price_repository.dart';
import 'package:ecopulse/data/repositories/trip_repository.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/services/fuel/fuel_estimation_service.dart';
import 'package:ecopulse/services/fuel/trip_monetary_calculation_service.dart';
import 'package:ecopulse/services/location/location_service.dart';
import 'package:ecopulse/services/permissions/app_permission_service.dart';
import 'package:ecopulse/services/sensors/sensor_service.dart';
import 'package:ecopulse/services/trip/driving_behavior_service.dart';
import 'package:ecopulse/services/trip/eco_score_service.dart';
import 'package:ecopulse/services/trip/speed_service.dart';
import 'package:ecopulse/services/trip/trip_detection_service.dart';
import 'package:ecopulse/services/voice/voice_alert_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripSessionServiceProvider =
    StateNotifierProvider<TripSessionService, TripSessionStateModel>((ref) {
  return TripSessionService(
    permissionService: ref.read(appPermissionServiceProvider),
    locationService: ref.read(locationServiceProvider),
    sensorService: ref.read(sensorServiceProvider),
    speedService: ref.read(speedServiceProvider),
    tripDetectionService: ref.read(tripDetectionServiceProvider),
    drivingBehaviorService: ref.read(drivingBehaviorServiceProvider),
    fuelEstimationService: ref.read(fuelEstimationServiceProvider),
    ecoScoreService: ref.read(ecoScoreServiceProvider),
    voiceAlertService: ref.read(voiceAlertServiceProvider),
    tripRepository: ref.read(tripRepositoryProvider),
    drivingEventRepository: ref.read(drivingEventRepositoryProvider),
    vehicleRepository: ref.read(vehicleRepositoryProvider),
    fuelPriceRepository: ref.read(fuelPriceRepositoryProvider),
    tripMonetaryCalculationService:
        ref.read(tripMonetaryCalculationServiceProvider),
  );
});

class TripSessionService extends StateNotifier<TripSessionStateModel> {
  final AppPermissionService permissionService;
  final LocationService locationService;
  final SensorService sensorService;
  final SpeedService speedService;
  final TripDetectionService tripDetectionService;
  final DrivingBehaviorService drivingBehaviorService;
  final FuelEstimationService fuelEstimationService;
  final EcoScoreService ecoScoreService;
  final VoiceAlertService voiceAlertService;
  final TripRepository tripRepository;
  final DrivingEventRepository drivingEventRepository;
  final VehicleRepository vehicleRepository;
  final FuelPriceRepository fuelPriceRepository;
  final TripMonetaryCalculationService tripMonetaryCalculationService;

  StreamSubscription<LocationSampleModel>? _locationSubscription;
  StreamSubscription<SensorSampleModel>? _sensorSubscription;
  Timer? _durationTimer;

  LocationSampleModel? _lastLocation;
  double? _lastAccelerationMps2;       // ← NUEVO
  UserVehicleModel? _selectedVehicle;

  TripSessionService({
    required this.permissionService,
    required this.locationService,
    required this.sensorService,
    required this.speedService,
    required this.tripDetectionService,
    required this.drivingBehaviorService,
    required this.fuelEstimationService,
    required this.ecoScoreService,
    required this.voiceAlertService,
    required this.tripRepository,
    required this.drivingEventRepository,
    required this.vehicleRepository,
    required this.fuelPriceRepository,
    required this.tripMonetaryCalculationService,
  }) : super(TripSessionStateModel.initial());

  void setVisualAlertsEnabled(bool value) {
    state = state.copyWith(
      visualAlertsEnabled: value,
    );
  }

  void setVoiceAlertsEnabled(bool value) {
    state = state.copyWith(
      voiceAlertsEnabled: value,
    );
  }

  void setRealtimeFeedbackEnabled(bool value) {
    state = state.copyWith(
      realtimeFeedbackEnabled: value,
    );
  }

  void applyUserSettings(UserSettingsModel settings) {
    state = state.copyWith(
      visualAlertsEnabled: settings.visualAlertsEnabled,
      voiceAlertsEnabled: settings.voiceAlertsEnabled,
      realtimeFeedbackEnabled: settings.realtimeFeedbackEnabled,
    );
  }

  Future<void> enableAutoDetection() async {
    final permissionStatus = await permissionService.requestRequiredPermissions();

    if (!permissionStatus.canTrackTrips) {
      state = state.copyWith(
        statusMessage: permissionStatus.statusMessage,
        warnings: permissionStatus.warnings,
      );
      return;
    }

    locationService.resetTrackingFilter();   // ← NUEVO
    sensorService.start();
    _listenSensors();
    _listenLocation();

    state = state.copyWith(
      isAutoDetectionEnabled: true,
      statusMessage:
          'Detección automática activada. EcoPulse iniciará el trayecto al detectar movimiento estable.',
      warnings: permissionStatus.warnings,
    );
  }

  Future<void> disableAutoDetection() async {
    if (!state.isTracking) {
      await _stopStreams();
    }

    tripDetectionService.resetAll();

    state = state.copyWith(
      isAutoDetectionEnabled: false,
      statusMessage: 'Detección automática desactivada.',
    );
  }

  Future<void> startManualTrip() async {
    final permissionStatus = await permissionService.requestRequiredPermissions();

    if (!permissionStatus.canTrackTrips) {
      state = state.copyWith(
        statusMessage: permissionStatus.statusMessage,
        warnings: permissionStatus.warnings,
      );
      return;
    }

    final startLocation = await locationService.getCurrentLocation();

    await _startTrip(
      startLocation: startLocation,
      autoStarted: false,
    );
  }

  Future<void> finishManualTrip() async {
    await _finishTrip(
      message: 'Trayecto finalizado manualmente.',
    );
  }

  Future<void> _startTrip({
    required LocationSampleModel startLocation,
    required bool autoStarted,
  }) async {
    if (state.isTracking) {
      return;
    }

    state = state.copyWith(
      isSaving: true,
      statusMessage: 'Iniciando trayecto...',
      clearEndedAt: true,
      clearFeedbackMessage: true,
    );

    try {
      _selectedVehicle = await vehicleRepository.getSelectedVehicle();

      final tripId = await tripRepository.createTrip(
        startLocation: startLocation,
        vehicleId: _selectedVehicle?.id,
      );

      sensorService.start();
      _listenSensors();
      locationService.seedLocation(startLocation);   // ← NUEVO
      _lastAccelerationMps2 = 0;                     // ← NUEVO
      _listenLocation();
      _startDurationTimer();

      _lastLocation = startLocation;
      drivingBehaviorService.resetCooldowns();

      state = state.copyWith(
        isTracking: true,
        isSaving: false,
        activeTripId: tripId,
        selectedVehicleId: _selectedVehicle?.id,
        startedAt: DateTime.now(),
        currentLocation: startLocation,
        routePoints: [startLocation],
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
        clearLastCompletedTripId: true,
        statusMessage: autoStarted
            ? 'Trayecto iniciado automáticamente.'
            : 'Trayecto iniciado manualmente.',
      );
    } catch (exception) {
      state = state.copyWith(
        isSaving: false,
        statusMessage: 'No fue posible iniciar el trayecto. Detalle: $exception',
      );
    }
  }

  Future<void> _finishTrip({
    required String message,
  }) async {
    final tripId = state.activeTripId;
    final currentLocation = state.currentLocation;

    if (!state.isTracking || tripId == null || currentLocation == null) {
      return;
    }

    state = state.copyWith(
      isSaving: true,
      statusMessage: 'Finalizando trayecto y calculando costo...',
    );

    try {
      final fuelType = _selectedVehicle?.fuelType ?? 'Gasolina corriente';

      final fuelPrice = await fuelPriceRepository.getLatestFuelPrice(
        fuelType: fuelType,
      );

      final estimatedFuelImpactGallons =
          await drivingEventRepository.getEstimatedFuelImpactGallons(
        tripId: tripId,
      );

      final monetaryResult = tripMonetaryCalculationService.calculate(
        estimatedGallons: state.estimatedFuelGallons,
        distanceKm: state.distanceKm,
        estimatedFuelImpactGallons: estimatedFuelImpactGallons,
        fuelPrice: fuelPrice,
      );

      await tripRepository.finishTrip(
        tripId: tripId,
        endLocation: currentLocation,
        distanceKm: state.distanceKm,
        durationSeconds: state.durationSeconds,
        idleTimeSeconds: state.idleTimeSeconds,
        aggressiveAccelerationEvents: state.aggressiveAccelerationEvents,
        hardBrakingEvents: state.hardBrakingEvents,
        irregularDrivingEvents: state.irregularDrivingEvents,
        estimatedFuelConsumedGallons: state.estimatedFuelGallons,
        estimatedFuelConsumedLiters: state.estimatedFuelLiters,
        estimatedKmPerGallon: state.estimatedKmPerGallon,
        estimatedLitersPer100Km: state.estimatedLitersPer100Km,
        ecoScore: state.ecoScore,
        estimationMethod: state.estimationMethod,
        fuelPricePerGallon: monetaryResult.fuelPricePerGallon,
        fuelPriceSource: monetaryResult.fuelPriceSource,
        fuelPriceIsOfficial: monetaryResult.fuelPriceIsOfficial,
        estimatedCostCop: monetaryResult.estimatedCostCop,
        costPerKmCop: monetaryResult.costPerKmCop,
        estimatedSavingsCop: monetaryResult.estimatedSavingsCop,
      );

      await _stopStreams();
      tripDetectionService.resetAll();
      drivingBehaviorService.resetCooldowns();

      state = state.copyWith(
        isTracking: false,
        isSaving: false,
        endedAt: DateTime.now(),
        lastCompletedTripId: tripId,
        statusMessage: message,
        warnings: [
          ...state.warnings,
          ...monetaryResult.warnings,
        ],
        clearTripId: true,
      );
    } catch (exception) {
      state = state.copyWith(
        isSaving: false,
        statusMessage:
            'No fue posible finalizar el trayecto. Detalle: $exception',
      );
    }
  }

  void _listenSensors() {
    _sensorSubscription ??= sensorService.stream.listen((sample) {
      state = state.copyWith(
        latestSensorSample: sample,
        warnings: sample.warnings,
      );
    });
  }

  void _listenLocation() {
    _locationSubscription ??= locationService.watchLocation().listen(
      (location) {
        unawaited(_handleLocation(location));
      },
      onError: (error) {
        state = state.copyWith(
          statusMessage:
              'Error leyendo ubicación. Verifica el GPS y los permisos.',
          warnings: [
            ...state.warnings,
            'Error de ubicación: $error',
          ],
        );
      },
    );
  }

  Future<void> _handleLocation(LocationSampleModel location) async {
    if (!location.hasAcceptableAccuracy) {
      state = state.copyWith(
        currentLocation: location,
        statusMessage: 'Esperando mejor precisión del GPS...',
      );
      return;
    }

    if (!state.isTracking && state.isAutoDetectionEnabled) {
      final shouldStart = tripDetectionService.shouldAutoStart(location);

      if (shouldStart) {
        await _startTrip(
          startLocation: location,
          autoStarted: true,
        );
      }

      state = state.copyWith(
        currentLocation: location,
      );

      return;
    }

    if (!state.isTracking) {
      state = state.copyWith(
        currentLocation: location,
      );
      return;
    }

    final activeTripId = state.activeTripId;

    if (activeTripId == null) {
      return;
    }

    final previousLocation = _lastLocation;

    double addedDistanceKm = 0;
    double accelerationMps2 = 0;

    if (previousLocation != null) {
      final isGpsJump = speedService.isGpsJump(
        previous: previousLocation,
        current: location,
      );

      // ── BLOQUE REEMPLAZADO ────────────────────────────────────────────────
      if (isGpsJump) {
        state = state.copyWith(
          currentLocation: location,
          statusMessage:
              'Lectura GPS irregular descartada. Esperando una señal más estable...',
          warnings: _addUniqueWarning(
            state.warnings,
            'Se descartó una lectura GPS irregular para evitar errores de velocidad o distancia.',
          ),
        );
        return;
      }

      addedDistanceKm = speedService.calculateDistanceKm(
        previous: previousLocation,
        current: location,
      );

      final rawAccelerationMps2 = speedService.calculateAccelerationMps2(
        previous: previousLocation,
        current: location,
      );

      accelerationMps2 = speedService.smoothAccelerationMps2(
        previousAccelerationMps2: _lastAccelerationMps2,
        currentAccelerationMps2: rawAccelerationMps2,
      );
      // ─────────────────────────────────────────────────────────────────────
    }

    final totalDistanceKm = state.distanceKm + addedDistanceKm;

    final estimation = fuelEstimationService.estimateIncrement(
      previousTotalGallons: state.estimatedFuelGallons,
      totalDistanceKm: totalDistanceKm,
      incrementalDistanceKm: addedDistanceKm,
      previousLocation: previousLocation,
      currentLocation: location,
      accelerationMps2: accelerationMps2,
      idleTimeSeconds: state.idleTimeSeconds,
      vehicle: _selectedVehicle,
    );

    _lastLocation = location;
    _lastAccelerationMps2 = accelerationMps2;   // ← NUEVO

    final point = TripPointSampleModel(
      location: location,
      sensor: state.latestSensorSample,
      calculatedAccelerationMps2: accelerationMps2,
    );

    try {
      await tripRepository.saveTripPoint(
        tripId: activeTripId,
        point: point,
      );

      final idleSeconds = tripDetectionService.currentIdleSeconds(location);

      final detectedEvents = drivingBehaviorService.detectEvents(
        tripId: activeTripId,
        currentLocation: location,
        sensorSample: state.latestSensorSample,   // ← NUEVO
        accelerationMps2: accelerationMps2,
        roadGradePercent: estimation.roadGradePercent,
        idleTimeSeconds: idleSeconds,
      );

      await _saveDetectedEvents(detectedEvents);

      final aggressiveAccelerationCount =
          state.aggressiveAccelerationEvents +
              detectedEvents.where((event) => event.isAggressiveAcceleration).length;

      final hardBrakingCount = state.hardBrakingEvents +
          detectedEvents.where((event) => event.isHardBraking).length;

      final irregularDrivingCount = state.irregularDrivingEvents +
          detectedEvents.where((event) => event.isIrregularDriving).length;

      final ecoScore = ecoScoreService.calculateScore(
        aggressiveAccelerationEvents: aggressiveAccelerationCount,
        hardBrakingEvents: hardBrakingCount,
        irregularDrivingEvents: irregularDrivingCount,
        idleTimeSeconds: idleSeconds,
        estimatedLitersPer100Km: estimation.estimatedLitersPer100Km,
      );

      final feedback = _buildFeedback(
        detectedEvents: detectedEvents,
        ecoScore: ecoScore,
      );

      if (feedback != null && state.realtimeFeedbackEnabled) {
        unawaited(
          voiceAlertService.speak(
            message: feedback.message,
            enabled: state.voiceAlertsEnabled,
          ),
        );
      }

      final updatedRoutePoints = [
        ...state.routePoints,
        location,
      ];

      state = state.copyWith(
        currentLocation: location,
        routePoints: updatedRoutePoints,
        distanceKm: totalDistanceKm,
        currentAccelerationMps2: accelerationMps2,
        roadGradePercent: estimation.roadGradePercent,
        estimatedFuelGallons: estimation.totalGallons,
        estimatedFuelLiters: estimation.totalLiters,
        estimatedKmPerGallon: estimation.estimatedKmPerGallon,
        estimatedLitersPer100Km: estimation.estimatedLitersPer100Km,
        estimationMethod: estimation.estimationMethod,
        savedPointsCount: state.savedPointsCount + 1,
        idleTimeSeconds: idleSeconds,
        aggressiveAccelerationEvents: aggressiveAccelerationCount,
        hardBrakingEvents: hardBrakingCount,
        irregularDrivingEvents: irregularDrivingCount,
        ecoScore: ecoScore,
        lastFeedbackMessage:
            state.visualAlertsEnabled && state.realtimeFeedbackEnabled
                ? feedback
                : null,
        statusMessage: feedback?.message ?? 'Registrando trayecto en tiempo real...',
        warnings: _mergeWarnings(estimation),
      );

      final shouldFinish = tripDetectionService.shouldAutoFinish(location);

      if (shouldFinish) {
        await _finishTrip(
          message:
              'Trayecto finalizado automáticamente por inactividad prolongada.',
        );
      }
    } catch (exception) {
      state = state.copyWith(
        statusMessage:
            'No fue posible guardar información del trayecto. Detalle: $exception',
      );
    }
  }

  Future<void> _saveDetectedEvents(List<DrivingEventModel> events) async {
    for (final event in events) {
      await drivingEventRepository.saveDrivingEvent(
        event: event,
      );
    }
  }

  EcoFeedbackMessageModel? _buildFeedback({
    required List<DrivingEventModel> detectedEvents,
    required double ecoScore,
  }) {
    if (detectedEvents.isNotEmpty) {
      final mainEvent = detectedEvents.first;

      return EcoFeedbackMessageModel(
        message: mainEvent.message,
        severity: mainEvent.severity,
        createdAt: DateTime.now(),
      );
    }

    if (state.savedPointsCount % 20 == 0 && state.isTracking) {
      return EcoFeedbackMessageModel(
        message: ecoScoreService.buildScoreMessage(ecoScore),
        severity: ecoScore >= 70 ? 'low' : 'medium',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  List<String> _mergeWarnings(FuelEstimationResultModel estimation) {
    final warnings = [...state.warnings];

    for (final warning in estimation.warnings) {
      if (!warnings.contains(warning)) {
        warnings.add(warning);
      }
    }

    return warnings;
  }

  // ← NUEVO
  List<String> _addUniqueWarning(
    List<String> currentWarnings,
    String warning,
  ) {
    final warnings = [...currentWarnings];

    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }

    return warnings;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isTracking || state.startedAt == null) {
        return;
      }

      final durationSeconds =
          DateTime.now().difference(state.startedAt!).inSeconds;

      state = state.copyWith(
        durationSeconds: durationSeconds,
      );
    });
  }

  Future<void> _stopStreams() async {
    await _locationSubscription?.cancel();
    await _sensorSubscription?.cancel();

    _locationSubscription = null;
    _sensorSubscription = null;

    _durationTimer?.cancel();
    _durationTimer = null;

    _lastLocation = null;                        // ← NUEVO
    _lastAccelerationMps2 = null;                // ← NUEVO
    locationService.resetTrackingFilter();       // ← NUEVO

    await sensorService.stop();
    await voiceAlertService.stop();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _locationSubscription?.cancel();
    _sensorSubscription?.cancel();
    sensorService.stop();
    voiceAlertService.stop();
    super.dispose();
  }
}