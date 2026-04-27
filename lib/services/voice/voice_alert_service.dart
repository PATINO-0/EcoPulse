import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final voiceAlertServiceProvider = Provider<VoiceAlertService>((ref) {
  final service = VoiceAlertService();

  ref.onDispose(service.dispose);

  return service;
});

class VoiceAlertService {
  final FlutterTts _tts = FlutterTts();
  final Map<String, DateTime> _lastSpokenMessages = {};

  bool _initialized = false;

  static const Duration messageCooldown = Duration(seconds: 25);

  Future<void> speak({
    required String message,
    required bool enabled,
  }) async {
    if (!enabled) {
      return;
    }

    if (!_canSpeak(message)) {
      return;
    }

    try {
      await _initializeIfNeeded();

      _lastSpokenMessages[message] = DateTime.now();

      await _tts.speak(message);
    } catch (_) {
      // Algunos entornos como Flutter Web pueden no soportar todas las funciones de TTS.
    }
  }

  bool _canSpeak(String message) {
    final lastTime = _lastSpokenMessages[message];

    if (lastTime == null) {
      return true;
    }

    return DateTime.now().difference(lastTime) >= messageCooldown;
  }

  Future<void> _initializeIfNeeded() async {
    if (_initialized) {
      return;
    }

    // Se configura voz en español de Colombia si el sistema la soporta.
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _initialized = true;
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}