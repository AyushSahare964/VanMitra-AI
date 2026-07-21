# VanMitra-AI — Flutter + Firebase Integration Plan
### (Firestore-only — no Firebase Storage access)

This plan assumes **Firebase Storage is not available on this project**. Every
place the original spec referenced `gs://.../claim_documents/...` etc. is
replaced here with **base64-encoded file content stored directly as Firestore
document fields**, in per-file subdocuments (not stuffed into the parent doc).

---

## 0. Why subdocuments, not one big field

Firestore hard-caps every document at **1 MiB**. Base64 inflates binary size
by ~33%, so a single 900 KB base64 string already uses most of that budget.
If we tried to hold 3-4 claim photos inside the `claims/{claimId}` doc itself,
we'd blow past the limit almost immediately. Instead:

- Every uploaded file becomes **its own document** in a subcollection
  (`claims/{claimId}/documents/{docId}`, `boundary_alerts/{alertId}/images/{imageId}`, etc.)
- Each subdocument is capped at ~900 KB of base64 text (enforced in
  `firestore.rules` via `withinFileLimit()`), leaving headroom for metadata.
- Files bigger than that (meeting-minutes PDFs) are split into **ordered
  chunks**, each its own subdocument, and reassembled on read.

## 1. Real capacity limit to plan around

Firestore's Spark free tier gives **1 GiB of total stored data** (not per
collection — the whole project). Base64 overhead eats into that budget faster
than raw files would in Storage. Rough math for a 1-village pilot:

| Item | Compressed size (client-side) | Base64 size | Est. count | Total |
|---|---|---|---|---|
| Claim site photo | ~80 KB (JPEG, resized to ~1000px, quality 55) | ~107 KB | ~500 | ~53 MB |
| Claim scanned doc (ration card, voter ID) | ~60 KB | ~80 KB | ~1000 | ~80 MB |
| Face embedding | ~2 KB (already a small vector, AES-256 encrypted) | ~3 KB | ~500 users | ~1.5 MB |
| Meeting minutes PDF (chunked) | ~150 KB/meeting | ~200 KB | ~50 meetings | ~10 MB |
| Boundary alert before/after images | ~100 KB each | ~135 KB | ~50 alerts × 2 | ~13.5 MB |

**Total ≈ 160 MB for a 1-village pilot** — comfortably inside the 1 GiB free
tier. At 5+ villages this climbs toward several hundred MB; keep an eye on it
in Firebase Console → Firestore → Usage, and see Section 7 (cleanup/archival)
below before it becomes a problem.

**The client-side compression step is not optional** — without it, an
uncompressed phone photo (3-8 MB) won't even fit under the 900 KB-base64 cap,
and the upload will be rejected by `firestore.rules` before it ever reaches
the network.

---

## Phase 0 — Rotate the exposed key & prep the project

(Unchanged from before — do this regardless of the storage decision.)

1. Rotate the service-account key that was shared earlier in Firebase Console
   → Project Settings → Service Accounts → delete key → generate new one.
   Never ship it in the app or commit it to git.
2. `google-services.json` stays in `android/app/` — it's safe, public client config.
3. ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=vanmitra-ai
   ```

---

## Phase 1 — Deploy the backend (Firestore rules, indexes, functions)

```bash
cd firebase/functions && npm install && cd ..
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
```
(No `firebase deploy --only storage` — there's no `storage.rules` in this
package since Storage isn't part of the architecture.)

**Acceptance test:** Firestore → Rules tab shows the deployed ruleset;
Functions tab shows `onUserCreate`, `registerMember`, `approvePendingUser`,
`verifyResolutionChain` all "Healthy".

---

## Phase 2 — pubspec.yaml & project wiring

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_messaging: ^15.0.0
  cloud_functions: ^5.0.0
  connectivity_plus: ^6.0.0
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  crypto: ^3.0.3                  # SHA-256 hash chain
  image_picker: ^1.1.0            # capture claim photos
  flutter_image_compress: ^2.3.0  # REQUIRED: compress before base64 encoding
  # firebase_storage removed — not used in this architecture
```

`lib/main.dart` is unchanged from the earlier plan (no Storage bucket to
configure).

---

## Phase 3 — Auth layer

Unchanged from before: `AuthService` wraps Phone OTP + custom claims, admins
pre-register phone numbers via the `registerMember` callable, claims are set
by `onUserCreate` on first login. See prior guidance for the full snippet —
none of this depends on Storage.

---

## Phase 4 — File handling: compress → base64 → Firestore subdocument

This is the core replacement for Firebase Storage. Create
`lib/services/file_encode_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileEncodeService {
  /// Compresses an image file and returns a base64 string safely under the
  /// 900 KB Firestore-rules cap. Retries at lower quality if still too big.
  static Future<String> encodeImage(File file, {int maxBytes = 850000}) async {
    var quality = 60;
    Uint8List? bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: quality,
      minWidth: 1000,
    );
    while (bytes != null && base64.encode(bytes).length > maxBytes && quality > 20) {
      quality -= 10;
      bytes = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: quality,
        minWidth: 800,
      );
    }
    if (bytes == null || base64.encode(bytes).length > maxBytes) {
      throw Exception('Image too large even after compression — ask user to retake at lower resolution');
    }
    return base64.encode(bytes);
  }
}
```

Upload a claim photo as a **subdocument**, not a field on the claim itself:

```dart
Future<void> uploadClaimDocument({
  required String claimId,
  required String villageId,
  required File file,
  required String category, // sitePhoto | rationCard | voterId | otherDoc
}) async {
  final base64Data = await FileEncodeService.encodeImage(file);
  final docRef = FirebaseFirestore.instance
      .collection('claims').doc(claimId)
      .collection('documents').doc();

  await docRef.set({
    'id': docRef.id,
    'claimId': claimId,
    'villageId': villageId,
    'claimantUserId': FirebaseAuth.instance.currentUser!.uid,
    'category': category,
    'mimeType': 'image/jpeg',
    'base64Data': base64Data,
    'sizeBytes': base64Data.length,
    'uploadedAt': FieldValue.serverTimestamp(),
  });

  // Keep a lightweight reference on the parent claim so lists/thumbnails don't
  // need to fetch full base64 payloads just to show a count/icon.
  await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
    'documentRefs': FieldValue.arrayUnion([docRef.id]),
  });
}
```

**Rendering:** decode and display directly, no download step:
```dart
Image.memory(base64Decode(doc['base64Data']))
```

**Offline behavior:** since this is a plain Firestore write, it goes through
the exact same Hive-queue → `CloudSyncService` → Firestore pipeline as every
other entity (Section below) — no separate "upload queue" needed. The base64
string is just another field in the queued payload.

**Acceptance test:** Take a claim photo offline, confirm it renders instantly
from the local Hive cache; go online, confirm the `claims/{id}/documents/{id}`
subdocument appears in Firestore Console and is under ~900 KB.

---

## Phase 5 — Chunked storage for larger files (meeting minutes PDFs)

PDFs of meeting minutes can exceed the 900 KB cap easily. Split client-side:

```dart
Future<void> uploadMeetingMinutes(String meetingId, String villageId, File pdf) async {
  final bytes = await pdf.readAsBytes();
  final base64Full = base64.encode(bytes);
  const chunkSize = 850000; // chars per chunk, safely under the rules cap
  final chunks = <String>[];
  for (var i = 0; i < base64Full.length; i += chunkSize) {
    chunks.add(base64Full.substring(i, (i + chunkSize).clamp(0, base64Full.length)));
  }

  final batch = FirebaseFirestore.instance.batch();
  final col = FirebaseFirestore.instance
      .collection('gram_sabha_meetings').doc(meetingId)
      .collection('minutes_chunks');

  for (var i = 0; i < chunks.length; i++) {
    batch.set(col.doc('chunk_${i.toString().padLeft(4, '0')}'), {
      'chunkIndex': i,
      'totalChunks': chunks.length,
      'base64Chunk': chunks[i],
      'mimeType': 'application/pdf',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  await FirebaseFirestore.instance.collection('gram_sabha_meetings').doc(meetingId).update({
    'minutesChunkCount': chunks.length,
  });
}
```

Reassemble on read:
```dart
Future<File> downloadMeetingMinutes(String meetingId) async {
  final snap = await FirebaseFirestore.instance
      .collection('gram_sabha_meetings').doc(meetingId)
      .collection('minutes_chunks')
      .orderBy('chunkIndex')
      .get();
  final full = snap.docs.map((d) => d['base64Chunk'] as String).join();
  final bytes = base64.decode(full);
  final file = File('${(await getTemporaryDirectory()).path}/minutes_$meetingId.pdf');
  return file.writeAsBytes(bytes);
}
```

Apply the same chunking pattern to `boundary_alerts/{alertId}/images/{imageId}`
if before/after satellite images ever exceed the single-document cap (usually
they won't after compression, but the pattern is there if needed).

**Acceptance test:** Generate a 3-page meeting minutes PDF (~1.5 MB), confirm
it splits into the expected number of chunk documents, and that
`downloadMeetingMinutes` reproduces a byte-identical file.

---

## Phase 6 — Sync layer (Hive ⇄ Firestore)

Same priority order as before — unchanged by the storage decision:

1. `village_members`
2. `gram_sabha_meetings` (before its minutes_chunks / before attendance)
3. `attendance_records`
4. `resolutions`
5. `claims` (parent doc first, then its `documents` subcollection)
6. `boundary_alerts` (parent doc, then its `images` subcollection)
7. `notices`

The only change: file uploads (Phase 4/5) are now just additional Firestore
writes in this same queue — there's no separate storage-upload retry path to
build or maintain.

---

## Phase 7 — Real-time UI, push notifications, security audit

Unchanged from the general Firebase integration plan:
- Reuse `StreamBuilder`/`snapshots()` patterns for admin dashboards.
- FCM push on claim status change / new notice, via Cloud Function triggers.
- Run the Firebase Emulator Suite before launch and verify:
  - Village A cannot read Village B's `claims/{id}/documents/{id}`
  - An oversized (uncompressed) upload is rejected by `withinFileLimit()`
  - `resolutions` / `attendance_records` remain immutable/undeletable
  - Only the owning user or `super_admin` can read `users/{uid}/private/faceEmbedding`

---

## Phase 8 — Storage-budget housekeeping (specific to this architecture)

Because every file now lives inside Firestore's 1 GiB free allotment instead
of Storage's separate 5 GB allotment, add a light cleanup routine:

- A scheduled Cloud Function (`functions.pubsub.schedule('every 24 hours')`)
  that deletes `sync_audit_log` entries older than 1 year (per the original
  spec's TTL recommendation) — audit log payloads don't contain base64 files,
  but they do accumulate.
- Consider **not** storing a full-resolution copy of rejected/superseded claim
  photos — when a villager re-uploads a photo for the same category, delete
  the old `documents/{docId}` subdocument first (admin or the Cloud Function,
  since regular users can't delete under the rules above).
- Monitor Firestore → Usage → Stored data monthly; if approaching 1 GiB,
  that's the trigger to either enable the Blaze plan (which unlocks Firebase
  Storage properly) or drop image quality further.

---

## Rollout order recap

| Week | Focus |
|---|---|
| 1 | Phase 0-2: rotate key, deploy Firestore rules/functions, wire pubspec |
| 1-2 | Phase 3: Auth + custom claims |
| 2 | Phase 4: compress → base64 → Firestore subdocument upload/render |
| 2-3 | Phase 5: chunked storage for meeting-minutes PDFs |
| 3 | Phase 6: Hive → Firestore sync service (files included in same queue) |
| 3-4 | Phase 7: dashboards, FCM, emulator security audit |
| Ongoing | Phase 8: storage-budget housekeeping |
