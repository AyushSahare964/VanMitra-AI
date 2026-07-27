import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Module C — On-Device STT Service
///
/// Wraps the [speech_to_text] package which uses the device's built-in speech
/// recognition engine (Google Speech Recognition on Android).
///
/// Supported locales:
///   - hi_IN (Hindi) — works offline if language pack installed
///   - mr_IN (Marathi) — works offline if language pack installed
///   - Gondi / Warli — NO device STT support; caller shows text-input fallback
///
/// The service never crashes on unavailable locale — it calls [onError] so the
/// UI can gracefully show a text-input field instead.
class OnDeviceSttService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Whether the device supports a given locale.
  ///
  /// Use this before showing the mic button to decide whether to show
  /// the STT UI or fall back directly to a text-input field.
  static bool supportsLocale(String locale) =>
      locale == 'hi_IN' || locale == 'mr_IN';

  /// Check if a specific locale is actually available on this device.
  /// Returns false for Gondi/Warli (no device STT support).
  Future<bool> checkLocaleAvailable(String locale) async {
    if (!supportsLocale(locale)) return false;
    if (!_isInitialized) {
      _isInitialized = await _stt.initialize(onError: _handleError);
    }
    if (!_isInitialized) return false;
    final locales = await _stt.locales();
    return locales.any((l) => l.localeId.startsWith(locale.replaceAll('_', '-')));
  }

  /// Start listening for speech input.
  ///
  /// [locale]          — 'hi_IN' or 'mr_IN'
  /// [onPartialResult] — called with each intermediate word group (for live preview)
  /// [onFinalResult]   — called once with the complete final transcript
  /// [onError]         — called if STT fails (locale not installed, permission denied, etc.)
  ///                     Caller should show a text-input field when this fires.
  Future<void> startListening({
    required String locale,
    required void Function(String) onPartialResult,
    required void Function(String) onFinalResult,
    required void Function(String) onError,
  }) async {
    if (!_isInitialized) {
      _isInitialized = await _stt.initialize(
        onError: (err) => onError(err.errorMsg),
      );
    }
    if (!_isInitialized) {
      onError('Speech recognition not available on this device');
      return;
    }

    _isListening = true;
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _isListening = false;
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
    );
  }

  /// Stop listening early (user tapped stop button).
  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
  }

  /// Cancel listening without producing a result.
  Future<void> cancelListening() async {
    await _stt.cancel();
    _isListening = false;
  }

  void _handleError(SpeechRecognitionError error) {
    _isListening = false;
  }

  void dispose() => _stt.cancel();
}
