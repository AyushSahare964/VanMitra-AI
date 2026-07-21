import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Module C — Audio Capture Service
///
/// Wraps the [record] package to manage microphone recording for:
/// 1. Resolution recording (fed to [OnDeviceSttService.transcribe()])
/// 2. Consent audio (mandatory gate on [MemberEnrolmentScreen])
///
/// Audio files are stored as M4A in the app's temp directory.
/// The caller is responsible for deleting files after use via [deleteRecording].
class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Request microphone permission. Returns true if granted.
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording to a uniquely named temp file.
  ///
  /// Throws if microphone permission is denied.
  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/vanmitra_audio_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // 16 kHz — optimal for speech recognition
        bitRate: 64000,
        numChannels: 1,    // mono
      ),
      path: _currentPath!,
    );
    _isRecording = true;
  }

  /// Stop recording and return the local file path.
  ///
  /// Returns null if no recording was in progress.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    _currentPath = null;
    return path;
  }

  /// Cancel an in-progress recording without saving.
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
      _currentPath = null;
    }
  }

  /// Delete a recording file from disk after it has been processed.
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Amplitude stream for waveform visualisation in [ConsentRecorderWidget]
  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  void dispose() => _recorder.dispose();
}
