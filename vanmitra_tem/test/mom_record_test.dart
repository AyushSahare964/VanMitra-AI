import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanmitra_ai/models/mom_record.dart';

/// Tests for MomRecord canonical JSON and hash reproducibility.
/// These tests don't require Hive, so they run without full app setup.
void main() {
  MomRecord buildRecord({String id = 'rec1'}) => MomRecord(
        id: id,
        meetingId: 'meeting-001',
        villageId: 'village-abc',
        meetingDate: '2026-07-10T10:00:00.000Z',
        geotag: '19.7800,73.2200',
        decisionTextEn: 'All members agreed.',
        decisionTextHi: 'सभी सदस्य सहमत हैं।',
        decisionTextMr: 'सर्व सदस्य सहमत आहेत।',
        sourceLanguage: 'mr',
        attendeeCount: 30,
        registeredCount: 50,
        womenCount: 12,
        quorumValid: true,
        quorumExplanation: 'Quorum met: 60% attendance, 40% women.',
        faceMatchedCount: 25,
        manualAddedCount: 5,
        localHash: 'test-hash',
        timestampUtc: '2026-07-10T10:00:00.000Z',
      );

  group('MomRecord.toCanonicalJson()', () {
    test('Keys are sorted alphabetically', () {
      final record = buildRecord();
      final canonical = record.toCanonicalJson();
      final keys = canonical.keys.toList();
      final sorted = List<String>.from(keys)..sort();
      expect(keys, equals(sorted),
          reason: 'toCanonicalJson() must return alphabetically sorted keys');
    });

    test('Two records with same data produce identical canonical JSON', () {
      final r1 = buildRecord(id: 'rec1');
      final r2 = buildRecord(id: 'rec1');
      final json1 = jsonEncode(r1.toCanonicalJson());
      final json2 = jsonEncode(r2.toCanonicalJson());
      expect(json1, equals(json2));
    });

    test('Different village IDs produce different canonical JSON', () {
      final r1 = MomRecord(
        id: 'r1',
        meetingId: 'm1',
        villageId: 'village-A',
        meetingDate: '2026-07-10T10:00:00.000Z',
        geotag: '0,0',
        decisionTextEn: 'text',
        decisionTextHi: 'text',
        decisionTextMr: 'text',
        sourceLanguage: 'mr',
        attendeeCount: 10,
        registeredCount: 20,
        womenCount: 4,
        quorumValid: true,
        quorumExplanation: '',
        faceMatchedCount: 8,
        manualAddedCount: 2,
        localHash: '',
        timestampUtc: '2026-07-10T10:00:00.000Z',
      );
      final r2 = MomRecord(
        id: 'r1',
        meetingId: 'm1',
        villageId: 'village-B', // different
        meetingDate: '2026-07-10T10:00:00.000Z',
        geotag: '0,0',
        decisionTextEn: 'text',
        decisionTextHi: 'text',
        decisionTextMr: 'text',
        sourceLanguage: 'mr',
        attendeeCount: 10,
        registeredCount: 20,
        womenCount: 4,
        quorumValid: true,
        quorumExplanation: '',
        faceMatchedCount: 8,
        manualAddedCount: 2,
        localHash: '',
        timestampUtc: '2026-07-10T10:00:00.000Z',
      );
      expect(
        jsonEncode(r1.toCanonicalJson()),
        isNot(equals(jsonEncode(r2.toCanonicalJson()))),
      );
    });

    test('contentHash matches manual SHA-256 of canonicalJson', () {
      final record = buildRecord();
      final canonical = jsonEncode(record.toCanonicalJson());
      final expected = sha256.convert(utf8.encode(canonical)).toString();
      expect(record.contentHash, equals(expected));
    });
  });

  group('MomRecord.fromJson(toJson())', () {
    test('Round-trip serialisation preserves all fields', () {
      final original = buildRecord();
      final roundTripped = MomRecord.fromJson(original.toJson());
      expect(roundTripped.id, original.id);
      expect(roundTripped.villageId, original.villageId);
      expect(roundTripped.attendeeCount, original.attendeeCount);
      expect(roundTripped.quorumValid, original.quorumValid);
      expect(roundTripped.faceMatchedCount, original.faceMatchedCount);
      expect(roundTripped.decisionTextMr, original.decisionTextMr);
    });
  });
}
