# VanMitra-AI — Firebase Integration: Final Report
### (Revised: Firestore-only architecture — no Firebase Storage)

**Project:** VanMitra-AI (FRA 2006 Digital Platform) · **Region:** asia-south1 (Mumbai)
**Based on:** `VanMitra_AI_Cloud_Database_Specification.md` (July 2026)
**Prepared:** July 2026

---

## 1. What Changed From the Original Spec

The original specification (Section 8) assumed Firebase Storage was available
for photos, scanned documents, meeting-minutes PDFs, face embeddings, and
satellite before/after images. **Since Storage isn't accessible on this
project, all of that is redesigned to store files as base64-encoded text
directly inside Firestore documents.** Every collection schema, security
rule, and integration step involving files has been reworked accordingly.
Nothing else about the spec's architecture (village-scoped isolation, custom
claims, Hive-first sync, the resolution hash chain) needed to change.

## 2. New File-Storage Design

| Original (Storage-based) | Replacement (Firestore-only) |
|---|---|
| `gs://.../claim_documents/{villageId}/{claimId}/photo.jpg` | `claims/{claimId}/documents/{docId}` — one subdocument per file, `base64Data` field |
| `gs://.../meeting_minutes/{villageId}/{meetingId}/minutes.pdf` | `gram_sabha_meetings/{meetingId}/minutes_chunks/{chunkId}` — PDF split into ordered ~850 KB base64 chunks, reassembled on read |
| `gs://.../boundary_alerts/{villageId}/{alertId}/before.jpg` | `boundary_alerts/{alertId}/images/{imageId}` — same one-doc-per-file pattern |
| `gs://.../face_embeddings/{userId}.bin` | `users/{uid}/private/faceEmbedding` — a private subdocument, still AES-256 encrypted client-side before it's base64-encoded and written |

**Why subdocuments instead of fields on the parent doc:** Firestore caps every
document at 1 MiB, and base64 inflates binary size ~33%. Packing multiple
photos into one `claims/{claimId}` doc would blow past that limit almost
immediately. Each file gets its own subdocument, capped at ~900 KB of base64
text — enforced server-side by a `withinFileLimit()` check in
`firestore.rules`, not just trusted client-side.

## 3. Capacity Trade-off You Should Know About

Firestore's Spark free tier includes **1 GiB of total stored data** for the
whole project — separate from (and smaller than) Storage's old 5 GB
allotment. With aggressive client-side compression (resize + JPEG quality
~55-60%, enforced in the Flutter app before upload), a 1-village pilot lands
around **~160 MB total** — safely inside the free tier. This gets tighter as
you scale past a handful of villages; the integration plan includes a
housekeeping phase (cleanup of superseded photos, monthly usage checks) so
you notice before it becomes a blocker rather than after.

## 4. Security Rule Changes (this revision)

`storage.rules` has been removed entirely — there's nothing to deploy there.
All the protections that used to live in Storage rules now live in
`firestore.rules`, on the new subcollections:

| Protection | Where it's enforced now |
|---|---|
| File size cap (was Storage's `request.resource.size`) | `withinFileLimit()` on `base64Data`/`base64Chunk`, ~900 KB |
| Allowed file types (was Storage's `contentType.matches(...)`) | `isAllowedMimeType()` — `image/jpeg`, `image/png`, `application/pdf` only |
| Village-scoped read access to claim photos | `claims/{claimId}/documents/{docId}` read rule — owner, same-village admin, district officer, or super admin |
| Face embedding privacy (owner-or-super-admin only) | `users/{uid}/private/faceEmbedding` — same rule as before, just relocated from a Storage path to a Firestore subdocument |
| Meeting-minutes admin-only upload | `minutes_chunks` create rule requires `isVillageAdmin()` on the parent meeting's `villageId` (via `get()`) |

All the earlier hardening from the previous review (village re-parenting
guards, notice broadcast restrictions, audit-log spoofing prevention, hash-
chain continuity checks) is preserved unchanged in this revision.

## 5. Deliverables in This Package

| File | Purpose |
|---|---|
| `firestore.rules` | Full ruleset, now including the base64 file-subdocument rules described above (Storage rules removed) |
| `firestore.indexes.json` | The 7 composite indexes from spec Section 9 — unaffected by the storage change |
| `firebase.json` | Deploy config for rules + indexes + functions (no `storage` section) |
| `functions/index.js` | `onUserCreate`, `registerMember`, `approvePendingUser`, `verifyResolutionChain` — unchanged, none of them touch file storage |
| `functions/package.json` | Cloud Functions dependency manifest |
| `VanMitra_Flutter_Integration_Plan.md` | Full phased build plan, now with a dedicated compress → base64 → Firestore-subdocument upload/download implementation (Phases 4-5) replacing the old Storage upload code |

## 6. Recommended Next Steps (in order)

1. Rotate the exposed service-account key, if you haven't already.
2. `firebase deploy --only firestore:rules,firestore:indexes,functions`
3. Add `flutter_image_compress` and `image_picker` to `pubspec.yaml` — client-
   side compression is not optional in this architecture; without it, uploads
   will be rejected by the 900 KB rule before they reach the network.
4. Follow `VanMitra_Flutter_Integration_Plan.md` Phase 0 → Phase 8 in order,
   each with its own acceptance test.
5. Before any real village pilot, run the Firebase Emulator Suite tests listed
   at the end of Phase 7 — including the new oversized-upload rejection test.
6. Keep an eye on Firestore storage usage (Console → Usage) as you onboard
   more villages; the housekeeping steps in Phase 8 exist specifically to
   keep you inside the 1 GiB free tier as long as possible.

## 7. What Wasn't Changed

Collection schemas for non-file fields, the Hive-first sync philosophy, the
custom-claims auth model, the composite indexes, and the SHA-256 resolution
hash chain are all exactly as reviewed previously — this revision only
redesigns how binary files (photos, scans, PDFs, face embeddings) are stored,
because Firebase Storage isn't available on this project.
