/// Web stub for FaceEnrollmentService
///
/// On web, dart:ffi and tflite_flutter are unavailable.
/// This stub provides the same API surface with graceful degradation
/// so the app compiles and runs on Chrome for UI testing.
library;

import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'embedding_matcher.dart';

class FaceEnrollmentService {
  static const int _embeddingDim = 512;
  final EmbeddingMatcher matcher;
  bool _isReady = false;

  bool get isReady => _isReady;

  FaceEnrollmentService({double threshold = 0.55})
      : matcher = EmbeddingMatcher(threshold: threshold);

  Future<void> init() async {
    // No-op on web — TFLite is mobile-only
    _isReady = true;
  }

  Future<List<double>?> embedFace(InputImage image) async {
    // Web stub: return null (caller shows "feature unavailable")
    return null;
  }

  Future<({String? memberId, double similarity, Rect? faceBox})>
      identifyFace(
    InputImage image,
    Map<String, List<double>> enrolledEmbeddings,
  ) async {
    return (memberId: null, similarity: -1.0, faceBox: null);
  }

  void dispose() {
    _isReady = false;
  }
}
