import 'dart:async';

import 'package:ecopulse/data/models/sensor_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();

  ref.onDispose(service.dispose);

  return service;
});

class SensorService {
  final StreamController<SensorSampleModel> _controller =
      StreamController<SensorSampleModel>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  SensorSampleModel _latestSample = SensorSampleModel.empty();
  bool _isRunning = false;

  Stream<SensorSampleModel> get stream {
    return _controller.stream;
  }

  SensorSampleModel get latestSample {
    return _latestSample;
  }

  void start() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    // Se escucha el acelerómetro crudo, útil para orientación y vibración.
    _subscriptions.add(
      accelerometerEvents.listen(
        (event) {
          _emit(
            _latestSample.copyWith(
              accelerationX: event.x,
              accelerationY: event.y,
              accelerationZ: event.z,
              timestamp: DateTime.now(),
            ),
          );
        },
        onError: (error) {
          _addWarning('Acelerómetro no disponible o lectura fallida.');
        },
        cancelOnError: false,
      ),
    );

    // Se escucha aceleración sin gravedad, más útil para conducción.
    _subscriptions.add(
      userAccelerometerEvents.listen(
        (event) {
          _emit(
            _latestSample.copyWith(
              userAccelerationX: event.x,
              userAccelerationY: event.y,
              userAccelerationZ: event.z,
              timestamp: DateTime.now(),
            ),
          );
        },
        onError: (error) {
          _addWarning('Acelerómetro sin gravedad no disponible.');
        },
        cancelOnError: false,
      ),
    );

    // Se escucha giroscopio para detectar rotaciones bruscas.
    _subscriptions.add(
      gyroscopeEvents.listen(
        (event) {
          _emit(
            _latestSample.copyWith(
              gyroscopeX: event.x,
              gyroscopeY: event.y,
              gyroscopeZ: event.z,
              timestamp: DateTime.now(),
            ),
          );
        },
        onError: (error) {
          _addWarning('Giroscopio no disponible.');
        },
        cancelOnError: false,
      ),
    );

    // Se escucha magnetómetro si el dispositivo lo soporta.
    _subscriptions.add(
      magnetometerEvents.listen(
        (event) {
          _emit(
            _latestSample.copyWith(
              magnetometerX: event.x,
              magnetometerY: event.y,
              magnetometerZ: event.z,
              timestamp: DateTime.now(),
            ),
          );
        },
        onError: (error) {
          _addWarning('Magnetómetro no disponible.');
        },
        cancelOnError: false,
      ),
    );

    // Se escucha barómetro si el dispositivo lo soporta.
     // Se escucha barómetro si el dispositivo lo soporta.
    _subscriptions.add(
      barometerEventStream().listen(         
        (event) {
          _emit(
            _latestSample.copyWith(
              barometerPressure: event.pressure,
              timestamp: DateTime.now(),
            ),
          );
        },
        onError: (error) {
          _addWarning('Barómetro no disponible en este dispositivo.');
        },
        cancelOnError: false,
      ),
    );
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    _isRunning = false;
  }

  void _emit(SensorSampleModel sample) {
    _latestSample = sample;

    if (!_controller.isClosed) {
      _controller.add(sample);
    }
  }

  void _addWarning(String warning) {
    final warnings = [..._latestSample.warnings];

    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }

    _emit(
      _latestSample.copyWith(
        warnings: warnings,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}