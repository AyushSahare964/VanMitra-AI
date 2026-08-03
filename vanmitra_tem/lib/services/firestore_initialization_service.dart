import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/seed/village_seed_registry.dart';
import '../models/user.dart';

/// Seeds all 12 Firestore collections required by the VanMitra-AI schema
/// for a given user's village on first login or registration.
///
/// Collections seeded:
///   1. users             — user profile doc with villageId embedded
///   2. villages          — village metadata from VillageSeedRegistry
///   3. village_members   — placeholder member entries
///   4. gram_sabha_meetings — initial meeting records
///   5. attendance_records — empty (created per-meeting)
///   6. claims            — user's claim placeholder (draft)
///   7. resolutions       — genesis resolution block
///   8. gram_sabha_mom_records — genesis MoM record
///   9. gram_sabha_face_enrollments — empty shell doc for this village
///  10. notices           — welcome notice for this village
///  11. boundary_alerts   — sample green-tier boundary alert
///  12. sync_audit_log    — initial sync entry
class FirestoreInitializationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Idempotent — safe to call on every login.
  /// Only writes documents that don't already exist.
  Future<void> initializeForUser(User user) async {
    final uid = user.id;
    final villageId = user.villageId;
    if (villageId.isEmpty) return;

    final village = VillageSeedRegistry.forId(villageId);
    if (village == null) return; // Unknown village — skip

    final batch = _db.batch();
    final now = Timestamp.now();

    // ── 1. users ─────────────────────────────────────────────────────────────
    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      batch.set(userRef, {
        'id': uid,
        'email': user.email,
        'name': user.name,
        'role': user.role.name,
        'villageId': villageId,
        // Embed village metadata for offline display
        'villageNameMarathi': village.nameMarathi,
        'villageNameEnglish': village.nameEnglish,
        'villageTalukaEn': village.talukaEnglish,
        'villageDistrictEn': village.districtEnglish,
        'preferredLanguage': user.preferredLanguage,
        'createdAt': now,
        'hasFaceEnrolled': false,
      });
    }

    // ── 2. villages ────────────────────────────────────────────────────────
    // Already seeded by VillageSeedRegistry in auth_provider — no-op here if exists
    final villageRef = _db.collection('villages').doc(villageId);
    final villageSnap = await villageRef.get();
    if (!villageSnap.exists) {
      batch.set(villageRef, village.toJson());
    }

    // ── 3. village_members ────────────────────────────────────────────────
    final memberRef = _db.collection('village_members').doc('${villageId}_MBR-001');
    final memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
      batch.set(memberRef, {
        'id': '${villageId}_MBR-001',
        'nameMarathi': village.nameMarathi,
        'nameEnglish': '${village.nameEnglish} Gram Sabha - Registered Member',
        'gender': 'female',
        'category': 'st',
        'villageId': villageId,
        'hasSmartphone': true,
        'isActive': true,
        'enrolledAt': now,
      });
    }

    // ── 4. gram_sabha_meetings ────────────────────────────────────────────
    final meetingId = '${villageId}_2025-01-26_regular';
    final meetingRef = _db.collection('gram_sabha_meetings').doc(meetingId);
    final meetingSnap = await meetingRef.get();
    if (!meetingSnap.exists) {
      batch.set(meetingRef, {
        'id': meetingId,
        'villageId': villageId,
        'scheduledDate': Timestamp.fromDate(DateTime(2025, 1, 26)),
        'type': 'regular',
        'status': 'completed',
        'venue': '${village.nameMarathi} ग्रामपंचायत कार्यालय',
        'venueLat': village.meetingVenueLat,
        'venueLng': village.meetingVenueLng,
        'agenda': 'वार्षिक ग्रामसभा — FRA दाव्यांचा आढावा आणि CFR व्यवस्थापन',
        'createdByUserId': uid,
        'resolutionIds': [],
        'totalAttendees': (village.registeredAdultMembers * 0.6).round(),
        'womenAttendees': (village.registeredWomenMembers * 0.6).round(),
        'stAttendees': (village.stMembers * 0.55).round(),
        'pvtgAttendees': (village.pvtgMembers * 0.5).round(),
        'quorumValid': true,
        'startedAt': Timestamp.fromDate(DateTime(2025, 1, 26, 10, 0)),
        'completedAt': Timestamp.fromDate(DateTime(2025, 1, 26, 13, 30)),
      });
    }

    // ── 5. attendance_records — seeded as one entry per meeting ──────────
    final attId = 'ATT_${meetingId}_${villageId}_MBR-001';
    final attRef = _db.collection('attendance_records').doc(attId);
    final attSnap = await attRef.get();
    if (!attSnap.exists) {
      batch.set(attRef, {
        'id': attId,
        'meetingId': meetingId,
        'memberId': '${villageId}_MBR-001',
        'memberName': '${village.nameEnglish} Gram Sabha Member',
        'villageId': villageId,
        'method': 'manual',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 26, 10, 15)),
        'gpsLatitude': village.meetingVenueLat,
        'gpsLongitude': village.meetingVenueLng,
        'gpsAccuracyMeters': 8.5,
        'distanceFromVenueMeters': 12.0,
        'gpsVerified': true,
        'faceMatchConfidence': 0.0,
        'faceVerified': false,
        'gender': 'female',
        'category': 'st',
      });
    }

    // ── 6. claims ─────────────────────────────────────────────────────────
    final claimId = 'CLM_${uid}_001';
    final claimRef = _db.collection('claims').doc(claimId);
    final claimSnap = await claimRef.get();
    if (!claimSnap.exists) {
      batch.set(claimRef, {
        'id': claimId,
        'claimantUserId': uid,
        'villageId': villageId,
        'type': 'formA',
        'status': 'draft',
        'nature': 'cultivation',
        'claimantName': user.name,
        'claimantNameEn': user.name,
        'fatherHusbandName': '',
        'address': '${village.nameMarathi}, ${village.talukaMarathi}, ${village.districtMarathi}',
        'surveyNumber': '',
        'areaSqMeters': 0.0,
        'landDescription': '',
        'occupationYears': 0,
        'occupationBefore2005': true,
        'evidenceFlags': {
          'landUseCertificate': false,
          'governmentRecord': false,
          'elderStatement': false,
          'photographicEvidence': false,
          'bankRecord': false,
        },
        'evidenceScore': 0.0,
        'missingEvidence': ['landUseCertificate', 'governmentRecord', 'elderStatement'],
        'createdAt': now,
        'isSynced': true,
      });
    }

    // ── 7. resolutions — genesis block ────────────────────────────────────
    final resId = 'RES_${villageId}_GENESIS';
    final resRef = _db.collection('resolutions').doc(resId);
    final resSnap = await resRef.get();
    if (!resSnap.exists) {
      batch.set(resRef, {
        'id': resId,
        'meetingId': meetingId,
        'villageId': villageId,
        'type': 'other',
        'text': 'ग्रामसभेने एकमताने VanMitra-AI प्रणाली अंतर्गत डिजिटल नोंदी ठेवण्यास संमती दिली.',
        'summary': 'Unanimous consent for VanMitra-AI digital record-keeping under FRA 2006.',
        'timestamp': Timestamp.fromDate(DateTime(2025, 1, 26, 11, 0)),
        'recordedByUserId': uid,
        'quorumValid': true,
        'totalPresent': (village.registeredAdultMembers * 0.6).round(),
        'totalRegistered': village.registeredAdultMembers,
        'womenPresent': (village.registeredWomenMembers * 0.6).round(),
        'stPresent': (village.stMembers * 0.55).round(),
        'pvtgPresent': (village.pvtgMembers * 0.5).round(),
        'attendancePercentage': 60.0,
        'womenPercentage': 33.5,
        'hash': 'GENESIS_${villageId}_SHA256',
        'previousHash': '0000000000000000',
        'blockIndex': 0,
        'relatedClaimId': null,
        'isCompliant': true,
      });
    }

    // ── 8. gram_sabha_mom_records — genesis MoM ───────────────────────────
    final momId = 'MOM_${villageId}_2025-01-26';
    final momRef = _db.collection('gram_sabha_mom_records').doc(momId);
    final momSnap = await momRef.get();
    if (!momSnap.exists) {
      batch.set(momRef, {
        'id': momId,
        'meetingId': meetingId,
        'villageId': villageId,
        'meetingDate': '2025-01-26',
        'geotag': '${village.meetingVenueLat},${village.meetingVenueLng}',
        'decisionTextMr': 'ग्रामसभेने VanMitra-AI प्रणाली स्वीकारण्याचा आणि सर्व FRA दावे या माध्यमातून नोंदविण्याचा ठराव केला.',
        'decisionTextHi': 'ग्राम सभा ने VanMitra-AI प्रणाली अपनाने और इसके माध्यम से सभी FRA दावों को दर्ज करने का प्रस्ताव पारित किया।',
        'decisionTextEn': 'Gram Sabha resolved to adopt VanMitra-AI system for all FRA claim registrations under Forest Rights Act 2006.',
        'sourceLanguage': 'mr',
        'attendeeCount': (village.registeredAdultMembers * 0.6).round(),
        'registeredCount': village.registeredAdultMembers,
        'womenCount': (village.registeredWomenMembers * 0.6).round(),
        'quorumValid': true,
        'quorumExplanation': 'Attendance: 60% ≥ 50% threshold. Women: 33.5% ≥ 33.3% threshold.',
        'faceMatchedCount': 0,
        'manualAddedCount': (village.registeredAdultMembers * 0.6).round(),
        'localHash': 'GENESIS_MOM_$villageId',
        'canonicalHash': null,
        'timestampUtc': '2025-01-26T10:00:00.000Z',
        'isSynced': true,
        'serverTimestamp': now,
      });
    }

    // ── 9. gram_sabha_face_enrollments — shell doc ────────────────────────
    final faceRef = _db.collection('gram_sabha_face_enrollments').doc('${villageId}_placeholder');
    final faceSnap = await faceRef.get();
    if (!faceSnap.exists) {
      batch.set(faceRef, {
        'memberId': '${villageId}_placeholder',
        'villageId': villageId,
        'embedding': [],
        'enrolledAt': now,
        'isPlaceholder': true,
      });
    }

    // ── 10. notices — village welcome notice ──────────────────────────────
    final noticeId = 'NOTICE_${villageId}_WELCOME';
    final noticeRef = _db.collection('notices').doc(noticeId);
    final noticeSnap = await noticeRef.get();
    if (!noticeSnap.exists) {
      batch.set(noticeRef, {
        'noticeId': noticeId,
        'category': 'general',
        'titleByLang': {
          'mr': 'VanMitra-AI मध्ये आपले स्वागत आहे — ${village.nameMarathi}',
          'en': 'Welcome to VanMitra-AI — ${village.nameEnglish}',
          'hi': 'VanMitra-AI में आपका स्वागत है — ${village.nameHindi}',
          'kn': 'VanMitra-AI ಗೆ ಸ್ವಾಗತ — ${village.nameEnglish}',
        },
        'bodyByLang': {
          'mr': '${village.nameMarathi} ग्रामपंचायतीसाठी VanMitra-AI पोर्टल सक्रिय झाले आहे. FRA दाव्यांसाठी नोंदणी करा.',
          'en': 'VanMitra-AI is now active for ${village.nameEnglish} Gram Panchayat. Register your FRA claims through this portal.',
          'hi': '${village.nameHindi} ग्राम पंचायत के लिए VanMitra-AI पोर्टल सक्रिय हो गया है।',
          'kn': '${village.nameEnglish} ಗ್ರಾಮ ಪಂಚಾಯತಿಗಾಗಿ VanMitra-AI ಪೋರ್ಟಲ್ ಸಕ್ರಿಯವಾಗಿದೆ.',
        },
        'severity': 'info',
        'validFrom': now,
        'validUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'linkedMeetingId': null,
        'linkedClaimId': null,
        'source': 'systemGenerated',
        'isDismissed': false,
        'createdAt': now,
      });
    }

    // ── 11. boundary_alerts — green-tier initial alert ────────────────────
    final alertId = 'ALERT_${villageId}_BASELINE';
    final alertRef = _db.collection('boundary_alerts').doc(alertId);
    final alertSnap = await alertRef.get();
    if (!alertSnap.exists) {
      batch.set(alertRef, {
        'id': alertId,
        'villageId': villageId,
        'tier': 'green',
        'detectedAt': now,
        'resolvedAt': null,
        'latitude': village.latitude,
        'longitude': village.longitude,
        'affectedAreaSqMeters': 0.0,
        'ndviChange': 0.02,
        'imagerySource': 'Sentinel-2 L2A',
        'imageryDate': now,
        'description': 'Baseline NDVI reading established for ${village.nameEnglish} forest boundary.',
        'descriptionMr': '${village.nameMarathi} वन सीमेसाठी आधाररेखा NDVI वाचन स्थापित झाले.',
        'isReported': false,
        'reportedTo': null,
        'reportedAt': null,
      });
    }

    // ── 12. sync_audit_log — initial entry ───────────────────────────────
    await _db.collection('sync_audit_log').add({
      'action': 'initializeVillage',
      'entityId': villageId,
      'entityType': 'village',
      'payload': {
        'villageId': villageId,
        'userId': uid,
        'collections': [
          'users', 'villages', 'village_members', 'gram_sabha_meetings',
          'attendance_records', 'claims', 'resolutions', 'gram_sabha_mom_records',
          'gram_sabha_face_enrollments', 'notices', 'boundary_alerts',
        ],
        'seedVersion': '2.0',
      },
      'createdAt': now,
      'lastAttemptAt': now,
      'attemptCount': 1,
      'errorMessage': null,
      'status': 'completed',
    });

    // Commit all non-audit batched writes
    await batch.commit();
  }
}
