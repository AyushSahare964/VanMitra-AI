import 'dart:math' as math;

/// Module C — Embedding Matcher (pure Dart)
///
/// Computes cosine similarity between a query face embedding and a map of
/// enrolled embeddings to find the best-matching registered member.
///
/// FaceNet embeddings are L2-normalised, so cosine similarity reduces to a
/// simple dot product — no sqrt/division needed after normalisation.
///
/// Used by [FaceEnrollmentService.identifyFace()] during live attendance.
class EmbeddingMatcher {
  /// Cosine similarity threshold above which a face is considered a match.
  ///
  /// Default: 0.55 (per Module C spec §3.1).
  /// Calibrate against real enrolment photos before shipping:
  /// - Raise to reduce false accepts (tighter security)
  /// - Lower to reduce false rejects (more forgiving in poor lighting)
  final double threshold;

  const EmbeddingMatcher({this.threshold = 0.55});

  /// Find the best-matching enrolled member for a query embedding.
  ///
  /// [query]              — 128-dim embedding from the live camera frame
  /// [enrolledEmbeddings] — Map<memberId, List<double>> loaded from Hive/Firestore
  ///
  /// Returns:
  ///   (memberId: String, similarity: double) if best match ≥ threshold
  ///   (memberId: null,   similarity: double) if no match — triggers manual-add fallback
  ({String? memberId, double similarity}) bestMatch(
    List<double> query,
    Map<String, List<double>> enrolledEmbeddings,
  ) {
    if (enrolledEmbeddings.isEmpty) {
      return (memberId: null, similarity: -1.0);
    }

    String? bestId;
    double bestSim = -1.0;

    for (final entry in enrolledEmbeddings.entries) {
      final sim = _dot(query, entry.value);
      if (sim > bestSim) {
        bestSim = sim;
        bestId = entry.key;
      }
    }

    if (bestSim >= threshold) {
      return (memberId: bestId, similarity: bestSim);
    }
    return (memberId: null, similarity: bestSim);
  }

  /// L2-normalise a raw embedding vector.
  ///
  /// FaceNet's TFLite output should already be L2-normalised, but call this
  /// as a safety measure to guarantee unit-length vectors before comparison.
  List<double> l2Normalize(List<double> embedding) {
    final norm = _norm(embedding);
    if (norm == 0.0) return embedding;
    return embedding.map((v) => v / norm).toList();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Dot product — equivalent to cosine similarity for L2-normalised vectors
  double _dot(List<double> a, List<double> b) {
    assert(
      a.length == b.length,
      'Embedding length mismatch: ${a.length} vs ${b.length}',
    );
    double sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  double _norm(List<double> v) {
    double sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    return sumSq > 0 ? math.sqrt(sumSq) : 0.0;
  }
}
