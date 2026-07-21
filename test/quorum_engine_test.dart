import 'package:flutter_test/flutter_test.dart';
import 'package:vanmitra_ai/services/quorum_engine.dart';

void main() {
  group('QuorumEngine.evaluate()', () {
    AttendanceEntry makeEntry({
      required String id,
      required bool isWoman,
      String method = 'face_match',
    }) =>
        AttendanceEntry(
          memberId: id,
          memberName: 'Test $id',
          isWoman: isWoman,
          captureMethod: method,
          checkedInAt: DateTime.now(),
        );

    test('Compliant: 3/4 attend, 1/3 women → Q_valid = true', () {
      final attendees = [
        makeEntry(id: '1', isWoman: true),  // W=1
        makeEntry(id: '2', isWoman: false),
        makeEntry(id: '3', isWoman: false),
      ];
      final result = QuorumEngine.evaluate(attendees, 4); // R=4
      expect(result.a, 3);
      expect(result.r, 4);
      expect(result.w, 1);
      expect(result.attendanceRatioPct, closeTo(75.0, 0.01)); // 3/4 = 75%
      expect(result.womenRatioPct, closeTo(33.33, 0.1));      // 1/3 ≈ 33.3%
      expect(result.qValid, isTrue);
    });

    test('Not compliant: attendance < 50% (2/5)', () {
      final attendees = [
        makeEntry(id: '1', isWoman: true),
        makeEntry(id: '2', isWoman: false),
      ];
      final result = QuorumEngine.evaluate(attendees, 5);
      expect(result.attendanceRatioPct, closeTo(40.0, 0.01));
      expect(result.qValid, isFalse);
    });

    test('Not compliant: women ratio < 33% (0 women)', () {
      final attendees = [
        makeEntry(id: '1', isWoman: false),
        makeEntry(id: '2', isWoman: false),
        makeEntry(id: '3', isWoman: false),
      ];
      final result = QuorumEngine.evaluate(attendees, 4);
      expect(result.womenRatioPct, closeTo(0.0, 0.01));
      expect(result.qValid, isFalse);
    });

    test('Exact boundary: 50% attendance, 33.3% women → compliant', () {
      final attendees = [
        makeEntry(id: '1', isWoman: true),   // W=1
        makeEntry(id: '2', isWoman: false),
      ];
      final result = QuorumEngine.evaluate(attendees, 4); // A=2, R=4 → 50%
      expect(result.attendanceRatioPct, closeTo(50.0, 0.01));
      expect(result.womenRatioPct, closeTo(50.0, 0.01)); // W=1, A=2 → 50%
      expect(result.qValid, isTrue);
    });

    test('Empty attendees → not compliant', () {
      final result = QuorumEngine.evaluate([], 10);
      expect(result.qValid, isFalse);
    });

    test('Face match count tracked correctly', () {
      final attendees = [
        makeEntry(id: '1', isWoman: true, method: 'face_match'),
        makeEntry(id: '2', isWoman: false, method: 'manual'),
        makeEntry(id: '3', isWoman: false, method: 'face_match'),
      ];
      final result = QuorumEngine.evaluate(attendees, 4);
      expect(result.faceMatchedCount, 2);
      expect(result.manualAddedCount, 1);
    });

    test('explain() contains percentages — never empty on failure', () {
      final attendees = [makeEntry(id: '1', isWoman: false)];
      final result = QuorumEngine.evaluate(attendees, 10); // attendance 10%
      expect(result.qValid, isFalse);
      final explanation = result.explain();
      expect(explanation, isNotEmpty);
      expect(explanation, contains('%'));
    });

    test('explain() says compliant when Q_valid', () {
      final attendees = [
        makeEntry(id: '1', isWoman: true),
        makeEntry(id: '2', isWoman: false),
      ];
      final result = QuorumEngine.evaluate(attendees, 2);
      expect(result.qValid, isTrue);
      expect(result.explain(), contains('met'));
    });
  });
}
