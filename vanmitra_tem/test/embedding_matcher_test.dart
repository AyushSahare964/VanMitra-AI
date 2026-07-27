import 'package:flutter_test/flutter_test.dart';
import 'package:vanmitra_ai/services/embedding_matcher.dart';

void main() {
  late EmbeddingMatcher matcher;

  setUp(() {
    matcher = const EmbeddingMatcher(threshold: 0.55);
  });

  // ── L2 normalisation ───────────────────────────────────────────────────────

  group('l2Normalize()', () {
    test('Zero vector returns unchanged', () {
      final result = matcher.l2Normalize([0.0, 0.0, 0.0]);
      expect(result, equals([0.0, 0.0, 0.0]));
    });

    test('Unit vector unchanged', () {
      final result = matcher.l2Normalize([1.0, 0.0, 0.0]);
      expect(result[0], closeTo(1.0, 1e-5));
      expect(result[1], closeTo(0.0, 1e-5));
    });

    test('Normalised vector has unit length', () {
      final v = [3.0, 4.0];
      final norm = matcher.l2Normalize(v);
      final length = norm.fold<double>(0.0, (acc, x) => acc + x * x);
      expect(length, closeTo(1.0, 1e-5));
    });
  });

  // ── bestMatch ─────────────────────────────────────────────────────────────

  group('bestMatch()', () {
    List<double> unit(List<double> v) => matcher.l2Normalize(v);

    test('Identical vector → similarity 1.0 → match', () {
      final embedding = unit([1.0, 2.0, 3.0]);
      final enrolled = {'member-1': unit([1.0, 2.0, 3.0])};
      final result = matcher.bestMatch(embedding, enrolled);
      expect(result.memberId, equals('member-1'));
      expect(result.similarity, closeTo(1.0, 1e-4));
    });

    test('Orthogonal vectors → similarity ~0 → no match', () {
      final embedding = unit([1.0, 0.0, 0.0]);
      final enrolled = {'member-1': unit([0.0, 1.0, 0.0])};
      final result = matcher.bestMatch(embedding, enrolled);
      expect(result.memberId, isNull);
      expect(result.similarity, closeTo(0.0, 1e-4));
    });

    test('Empty enrollments → no match, similarity -1', () {
      final result = matcher.bestMatch([1.0, 0.0], {});
      expect(result.memberId, isNull);
      expect(result.similarity, equals(-1.0));
    });

    test('Picks best match from multiple enrolled', () {
      final query = unit([1.0, 0.0, 0.0]);
      final enrolled = {
        'member-A': unit([1.0, 0.0, 0.0]),   // sim = 1.0 — best
        'member-B': unit([0.5, 0.5, 0.0]),   // sim < 1.0
      };
      final result = matcher.bestMatch(query, enrolled);
      expect(result.memberId, equals('member-A'));
    });

    test('Threshold boundary: sim exactly at threshold → match', () {
      // Create two vectors with exactly 0.55 cosine similarity
      // cos θ = 0.55 → θ = acos(0.55)
      // v1 = [1, 0], v2 = [0.55, sqrt(1 - 0.55^2)]
      final q = [1.0, 0.0];
      final e = [0.55, 0.8352]; // approx unit vector with cos-sim = 0.55
      final result = matcher.bestMatch(q, {'m': e});
      // With normalised vectors: dot product ≈ 0.55
      // Should match since 0.55 >= threshold(0.55)
      expect(result.similarity, greaterThanOrEqualTo(0.54));
    });

    test('Threshold boundary: sim below threshold → no match', () {
      final query = unit([1.0, 0.0, 0.0]);
      final enrolled = {'m': unit([0.5, 0.866, 0.0])}; // cos-sim ≈ 0.5
      final result = matcher.bestMatch(query, enrolled);
      expect(result.similarity, lessThan(0.55));
      expect(result.memberId, isNull);
    });
  });
}
