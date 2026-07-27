/// Platform-agnostic interface for face enrollment.
/// Native implementation: face_enrollment_service_native.dart
/// Web stub implementation: face_enrollment_service_stub.dart
library;

import 'dart:typed_data';

/// Result of a face identification attempt
typedef FaceIdResult = ({
  String? memberId,
  double similarity,
  Map<String, double>? faceBox, // left,top,width,height keys
});

/// Abstract interface for face enrollment — works on all platforms.
abstract class FaceEnrollmentInterface {
  bool get isReady;

  Future<void> init();

  /// Returns a normalized embedding vector, or null if no face detected.
  /// [imageBytes] — raw JPEG/PNG bytes from camera
  Future<List<double>?> embedFaceFromBytes(Uint8List imageBytes);

  /// Identify best matching member from enrolled embeddings.
  Future<FaceIdResult> identifyFromBytes(
    Uint8List imageBytes,
    Map<String, List<double>> enrolledEmbeddings,
  );

  void dispose();
}
