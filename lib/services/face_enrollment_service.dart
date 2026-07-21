import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'embedding_matcher.dart';

/// Module C — Face Enrollment Service
///
/// Real on-device face recognition pipeline:
///   1. [google_mlkit_face_detection] — detect face, get bounding box
///   2. [image] package — crop + resize to 160×160 (FaceNet input size)
///   3. [tflite_flutter] running facenet.tflite — produces 512-dim embedding
///   4. L2-normalise embedding (EmbeddingMatcher.l2Normalize)
///
/// The bundled model [facenet.tflite] is produced by convert_facenet.py
/// from facenet_keras.h5 with float16 quantisation.
///
/// IMPORTANT: Raw photos are never persisted — only the 512-dim embedding
/// is stored, satisfying the data-minimisation requirement (§7).
class FaceEnrollmentService {
  static const String _modelAsset = 'assets/ml/facenet.tflite';
  static const int _inputSize = 160; // FaceNet expects 160×160 RGB
  static const int _embeddingDim = 512;

  late Interpreter _interpreter;
  late FaceDetector _detector;
  final EmbeddingMatcher matcher;

  bool _isReady = false;

  /// Whether the TFLite interpreter has been loaded and is ready to use.
  bool get isReady => _isReady;

  FaceEnrollmentService({double threshold = 0.55})
      : matcher = EmbeddingMatcher(threshold: threshold);

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Load facenet.tflite from assets and initialise ML Kit face detector.
  /// Call this once at app startup (e.g., in ProviderScope / main.dart init).
  Future<void> init() async {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
      ),
    );
    _interpreter = await Interpreter.fromAsset(_modelAsset);
    _isReady = true;
  }

  // ── Enrolment ──────────────────────────────────────────────────────────────

  /// Generate a 512-dim face embedding from a captured [InputImage].
  ///
  /// Returns null if no face is detected — the caller MUST show an explicit
  /// error state ("No face detected — retry in better lighting"), never fail silently.
  ///
  /// Called during member enrolment ([MemberEnrolmentScreen]).
  Future<List<double>?> embedFace(InputImage image) async {
    assert(_isReady, 'FaceEnrollmentService not initialised — call init() first');

    final faces = await _detector.processImage(image);
    if (faces.isEmpty) return null;

    // Use the largest face (closest to camera) if multiple detected
    final face = faces.reduce(
      (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
    );

    return _runFaceNet(image, face.boundingBox);
  }

  // ── Live identification ────────────────────────────────────────────────────

  /// Detect + identify a face from a live camera frame.
  ///
  /// Returns the best-matching enrolled member ID and confidence score.
  /// If no face detected: memberId = null, similarity = -1.0.
  /// If face detected but no match above threshold: memberId = null, similarity = score.
  ///
  /// Called every camera frame during attendance marking ([GramSabhaLogScreen]).
  Future<({String? memberId, double similarity, Rect? faceBox})> identifyFace(
    InputImage image,
    Map<String, List<double>> enrolledEmbeddings,
  ) async {
    assert(_isReady, 'FaceEnrollmentService not initialised — call init() first');

    final faces = await _detector.processImage(image);
    if (faces.isEmpty) {
      return (memberId: null, similarity: -1.0, faceBox: null);
    }

    final face = faces.reduce(
      (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
    );

    final embedding = await _runFaceNet(image, face.boundingBox);
    if (embedding == null) {
      return (memberId: null, similarity: -1.0, faceBox: face.boundingBox);
    }

    final match = matcher.bestMatch(embedding, enrolledEmbeddings);
    return (
      memberId: match.memberId,
      similarity: match.similarity,
      faceBox: face.boundingBox,
    );
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _interpreter.close();
    _detector.close();
    _isReady = false;
  }

  // ── Private: FaceNet inference pipeline ───────────────────────────────────

  Future<List<double>?> _runFaceNet(InputImage image, Rect boundingBox) async {
    // Step 1: Get raw pixel bytes from InputImage
    final rawBytes = image.bytes;
    final metadata = image.metadata;
    if (rawBytes == null || metadata == null) return null;

    // Step 2: Decode raw bytes into an img.Image for cropping
    final fullImage = img.decodeImage(Uint8List.fromList(rawBytes));
    if (fullImage == null) return null;

    // Step 3: Crop to face bounding box (clamped to image bounds)
    final x = boundingBox.left.round().clamp(0, fullImage.width - 1);
    final y = boundingBox.top.round().clamp(0, fullImage.height - 1);
    final w = boundingBox.width.round().clamp(1, fullImage.width - x);
    final h = boundingBox.height.round().clamp(1, fullImage.height - y);

    final cropped = img.copyCrop(fullImage, x: x, y: y, width: w, height: h);

    // Step 4: Resize to 160×160 (FaceNet input size)
    final resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Step 5: Normalize pixel values to [-1, 1] and build [1, 160, 160, 3] input tensor
    final inputBuffer = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    // Step 6: Run FaceNet TFLite inference
    final outputBuffer = List.filled(_embeddingDim, 0.0).reshape([1, _embeddingDim]);
    _interpreter.run(inputBuffer, outputBuffer);

    // Step 7: L2-normalise the output embedding
    final raw = List<double>.from(outputBuffer[0] as List);
    return matcher.l2Normalize(raw);
  }
}
