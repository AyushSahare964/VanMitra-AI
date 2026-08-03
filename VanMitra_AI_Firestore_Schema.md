# VanMitra-AI — Firestore Schema Reference

**Project**: `vanmitra-ai`
**Database**: Google Cloud Firestore (NoSQL, document-based)

---

## Collections at a Glance

| # | Collection | Document ID | Purpose |
|---|---|---|---|
| 1 | `users` | Firebase Auth UID | User profiles and roles |
| 2 | `villages` | Auto / village code | Village metadata and demographics |
| 3 | `village_members` | Auto / `{villageId}_{memberId}` | Registered adult Gram Sabha members |
| 4 | `gram_sabha_meetings` | `{villageId}_{date}_{type}` | Gram Sabha meeting records |
| 5 | `attendance_records` | `ATT_{meetingId}_{memberId}` | Per-member attendance verification |
| 6 | `claims` | UUID | FRA claims (Form A / Form B) |
| 7 | `resolutions` | UUID (append-only) | Tamper-evident hash-chain resolutions |
| 8 | `gram_sabha_mom_records` | UUID (append-only) | Minutes of Meeting (tamper-evident) |
| 9 | `gram_sabha_face_enrollments` | `memberId` | Face embeddings (128-dim FaceNet) |
| 10 | `notices` | `noticeId` | System & admin notices |
| 11 | `boundary_alerts` | UUID | Satellite NDVI boundary-change alerts |
| 12 | `sync_audit_log` | Auto | Offline sync event log |

---

## 1. `users`

Doc ID = Firebase Auth UID

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | Firebase Auth UID |
| `email` | String | ✅ | |
| `name` | String | ✅ | |
| `role` | String enum | ✅ | `admin` \| `villager` |
| `villageId` | String | ✅ | FK → `villages` |
| `memberId` | String | ❌ | FK → `village_members` |
| `preferredLanguage` | String | ✅ | `mr`\|`en`\|`hi`\|`kn` (default `mr`) |
| `createdAt` | Timestamp | ✅ | |
| `hasFaceEnrolled` | Boolean | ✅ | default `false` |

**Indexes**: `villageId`

---

## 2. `villages`

Doc ID = auto-generated or village code (e.g. `MH-PU-001`)

**Identity**

| Field | Type | Req |
|---|---|---|
| `id` | String | ✅ |
| `nameMarathi` / `nameEnglish` | String | ✅ |
| `nameHindi` / `nameKonkani` | String | ❌ |
| `talukaMarathi` / `talukaEnglish` | String | ✅ |
| `districtMarathi` / `districtEnglish` | String | ✅ |
| `stateMarathi` / `stateEnglish` | String | ✅ |

**Demographics**

| Field | Type | Req |
|---|---|---|
| `totalPopulation` | Integer | ✅ |
| `registeredAdultMembers` (R) | Integer | ✅ |
| `registeredWomenMembers` (W) | Integer | ✅ |
| `registeredMenMembers` (M) | Integer | ✅ |
| `stMembers` / `pvtgMembers` / `otfdMembers` | Integer | ✅ |
| `stPercentage` / `pvtgPercentage` | Float | ✅ |

**Geography**

| Field | Type | Req |
|---|---|---|
| `latitude` / `longitude` | Float | ✅ |
| `meetingVenueLat` / `meetingVenueLng` | Float | ✅ |
| `cfrAreaHectares` | Float | ✅ |

**Claim Statistics**

| Field | Type | Req |
|---|---|---|
| `totalApprovedClaims` | Integer | ✅ |
| `totalApprovedAreaSqm` | Integer | ✅ |
| `approvedRightType` | String | ❌ |
| `casteCategory` | String | ❌ |

---

## 3. `village_members`

Doc ID = auto / `{villageId}_{memberId}`

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `nameMarathi` / `nameEnglish` | String | ✅ | |
| `gender` | String enum | ✅ | `male`\|`female`\|`other` |
| `category` | String enum | ✅ | `st`\|`pvtg`\|`otfd`\|`general` |
| `villageId` | String | ✅ | FK → `villages` |
| `age` | Integer | ❌ | |
| `phoneNumber` | String | ❌ | |
| `hasSmartphone` | Boolean | ✅ | default `true` |
| `faceEmbeddingId` | String | ❌ | legacy reference |
| `isActive` | Boolean | ✅ | default `true` |
| `faceEmbedding` | Array\<Float\> (128-dim) | ❌ | null if not enrolled |
| `enrolledAt` | Timestamp | ❌ | |

> ⚠️ Raw face photos are **never** uploaded — only the 128-dim embedding.

**Indexes**: `villageId` · `villageId + isActive`

---

## 4. `gram_sabha_meetings`

Doc ID = `{villageId}_{date}_{type}`

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `villageId` | String | ✅ | FK → `villages` |
| `scheduledDate` | Timestamp | ✅ | |
| `startedAt` / `completedAt` | Timestamp | ❌ | |
| `type` | String enum | ✅ | `regular`\|`special`\|`consentResolution` |
| `status` | String enum | ✅ | `scheduled`\|`inProgress`\|`completed`\|`cancelled` |
| `venue` | String | ✅ | |
| `venueLat` / `venueLng` | Float | ✅ | geofence center |
| `agenda` | String | ❌ | |
| `createdByUserId` | String | ✅ | FK → `users` |
| `resolutionIds` | Array\<String\> | ✅ | default `[]` |
| `totalAttendees` (A) | Integer | ✅ | |
| `womenAttendees` (W) | Integer | ✅ | |
| `stAttendees` / `pvtgAttendees` | Integer | ✅ | |
| `quorumValid` | Boolean | ✅ | |

**Quorum** (computed, not stored): Standard = A/R ≥ 50% AND W/A ≥ 33.3%. Enhanced (consent resolutions) = Standard + ST present + PVTG present.

**Indexes**: `villageId + scheduledDate` (DESC) · `villageId + status`

---

## 5. `attendance_records`

Doc ID = `ATT_{meetingId}_{memberId}` (deterministic, idempotent)

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `meetingId` | String | ✅ | FK → `gram_sabha_meetings` |
| `memberId` | String | ✅ | FK → `village_members` |
| `memberName` | String | ✅ | snapshot |
| `villageId` | String | ✅ | **required by security rules** |
| `method` | String enum | ✅ | `gpsFace`\|`manual`\|`otp` |
| `timestamp` | Timestamp | ✅ | |
| `gpsLatitude` / `gpsLongitude` | Float | ❌ | |
| `gpsAccuracyMeters` | Float | ❌ | |
| `distanceFromVenueMeters` | Float | ❌ | |
| `gpsVerified` | Boolean | ✅ | default `false` |
| `faceMatchConfidence` | Float | ❌ | cosine similarity [0–1] |
| `faceVerified` | Boolean | ✅ | default `false` |
| `manualEntryByUserId` | String | ❌ | FK → `users` |
| `manualEntryReason` | String | ❌ | |
| `gender` | String | ✅ | snapshot |
| `category` | String | ✅ | snapshot |

**Indexes**: `meetingId + timestamp` (ASC) · `villageId + meetingId`

---

## 6. `claims`

Doc ID = UUID

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `claimantUserId` | String | ✅ | FK → `users` |
| `villageId` | String | ✅ | FK → `villages` |
| `type` | String enum | ✅ | `formA`\|`formB` |
| `status` | String enum | ✅ | see lifecycle |
| `nature` | String enum | ✅ | `cultivation`\|`habitation`\|`mfpCollection`\|`grazing`\|`waterBodies`\|`traditionalResource`\|`other` |
| `claimantName` / `claimantNameEn` | String | ✅ | |
| `fatherHusbandName` | String | ❌ | |
| `address` | String | ❌ | |
| `surveyNumber` | String | ❌ | |
| `areaSqMeters` | Float | ❌ | |
| `landDescription` | String | ❌ | |
| `occupationYears` | Integer | ❌ | |
| `occupationBefore2005` | Boolean | ✅ | cutoff 13.12.2005 |
| `evidenceFlags` | Map\<String,Boolean\> | ✅ | category → present/absent |
| `evidenceScore` (E) | Float | ✅ | [0.0–1.0] |
| `missingEvidence` | Array\<String\> | ✅ | |
| `createdAt` | Timestamp | ✅ | |
| `submittedAt` / `reviewedAt` / `rejectedAt` | Timestamp | ❌ | |
| `rejectionReason` | String | ❌ | |
| `appealDeadline` | Timestamp | ❌ | `rejectedAt + 60 days` |
| `isSynced` | Boolean | ✅ | |

**Status lifecycle**: `draft → submitted → underReview → approved`, or `→ rejected → appealFiled`

**Evidence score tiers**: 🟢 E ≥ 0.8 · 🟡 E ≥ 0.6 · 🔴 E < 0.6

**Indexes**: `villageId + createdAt` (DESC) · `claimantUserId + createdAt` (DESC) · `villageId + status`

---

## 7. `resolutions`

Doc ID = UUID — **append-only** (rules block update/delete)

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `meetingId` / `villageId` | String | ✅ | FKs |
| `type` | String enum | ✅ | `claimApproval`\|`cfrManagement`\|`consentForDiversion`\|`mfpSaleTransit`\|`other` |
| `text` | String | ✅ | |
| `summary` | String | ❌ | |
| `timestamp` | Timestamp | ✅ | |
| `recordedByUserId` | String | ✅ | FK → `users` |
| `quorumValid` | Boolean | ✅ | |
| `totalPresent` (A) / `totalRegistered` (R) | Integer | ✅ | |
| `womenPresent` (W) / `stPresent` / `pvtgPresent` | Integer | ✅ | |
| `attendancePercentage` / `womenPercentage` | Float | ✅ | |
| `hash` (Hₙ) | String | ✅ | SHA-256(Hₙ₋₁ ∥ Dₙ ∥ tₙ) |
| `previousHash` (Hₙ₋₁) | String | ✅ | |
| `blockIndex` | Integer | ✅ | 0 = genesis |
| `relatedClaimId` | String | ❌ | FK → `claims` |
| `isCompliant` | Boolean | ✅ | quorumValid AND enhanced quorum if consent |

**Hash payload**: `{type}|{text}|{totalPresent}/{totalRegistered}|W:{womenPresent}|ST:{stPresent}|PVTG:{pvtgPresent}|Q:{quorumValid}|C:{isCompliant}`

**Indexes**: `villageId + blockIndex` (ASC)

---

## 8. `gram_sabha_mom_records`

Doc ID = UUID — **append-only**

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `meetingId` / `villageId` | String | ✅ | FKs |
| `meetingDate` | String (ISO-8601) | ✅ | |
| `geotag` | String | ✅ | `"lat,lng"` |
| `decisionTextEn` / `decisionTextHi` / `decisionTextMr` | String | ✅ | |
| `sourceLanguage` | String | ✅ | `mr`\|`hi`\|`gon`\|`wbr` |
| `attendeeCount` (A) / `registeredCount` (R) / `womenCount` (W) | Integer | ✅ | |
| `quorumValid` | Boolean | ✅ | A/R ≥ 0.5 AND W/A ≥ 1/3 |
| `quorumExplanation` | String | ✅ | |
| `faceMatchedCount` / `manualAddedCount` | Integer | ✅ | |
| `localHash` | String | ✅ | provisional client-side hash |
| `canonicalHash` | String | ❌ | server-assigned |
| `timestampUtc` | String | ✅ | device UTC |
| `firestoreTimestamp` | String | ❌ | canonical tₙ |
| `serverTimestamp` | Timestamp | — | auto via `FieldValue.serverTimestamp()` |
| `groupPhotoLocalPath` | String | ❌ | on-device only, never uploaded |
| `isSynced` | Boolean | ✅ | |

**Hash formula**: `SHA-256(prevHash | canonicalJSON | timestampUtc)`

**Indexes**: `villageId + timestampUtc` (ASC)

---

## 9. `gram_sabha_face_enrollments`

Doc ID = `memberId`

| Field | Type | Req |
|---|---|---|
| `memberId` | String | ✅ |
| `villageId` | String | ✅ |
| `embedding` | Array\<Float\> (128-dim) | ✅ |
| `enrolledAt` | Timestamp | ✅ |

> ⚠️ Raw face images are never stored — only the embedding vector. On-device photos are processed locally and discarded immediately.

**Indexes**: `villageId`

---

## 10. `notices`

Doc ID = `noticeId`

| Field | Type | Req | Notes |
|---|---|---|---|
| `noticeId` | String | ✅ | |
| `category` | String enum | ✅ | `meetingSchedule`\|`claimDeadline`\|`documentRequirement`\|`portalDowntime`\|`general` |
| `titleByLang` / `bodyByLang` | Map\<String,String\> | ✅ | keys: `mr`,`en`,`hi`,`kn` |
| `severity` | String enum | ✅ | `info`\|`warning`\|`critical` |
| `validFrom` / `validUntil` | Timestamp | ✅ | |
| `linkedMeetingId` | String | ❌ | FK → `gram_sabha_meetings` |
| `linkedClaimId` | String | ❌ | FK → `claims` |
| `source` | String enum | ✅ | `adminPosted`\|`systemGenerated` |
| `isDismissed` | Boolean | ✅ | default `false` |
| `createdAt` | Timestamp | ✅ | |

**Severity → UI**: `info` blue · `warning` amber · `critical` red

**Indexes**: `validUntil` (active notices: `validUntil > now()`)

---

## 11. `boundary_alerts`

Doc ID = UUID

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | String | ✅ | |
| `villageId` | String | ✅ | |
| `tier` | String enum | ✅ | `green`\|`yellow`\|`red` |
| `detectedAt` / `resolvedAt` | Timestamp | ✅ / ❌ | |
| `latitude` / `longitude` | Float | ✅ | |
| `affectedAreaSqMeters` | Float | ❌ | |
| `ndviChange` | Float | ❌ | negative = vegetation loss |
| `imagerySource` | String | ❌ | e.g. `"Sentinel-2 L2A"` |
| `imageryDate` | Timestamp | ❌ | |
| `description` / `descriptionMr` | String | ✅ / ❌ | |
| `isReported` | Boolean | ✅ | default `false` |
| `reportedTo` | String | ❌ | e.g. `"District Office"` |
| `reportedAt` | Timestamp | ❌ | |

**Tiers**: 🟢 no change · 🟡 localised change, weekly review · 🔴 ΔNDVI < −θ, immediate Gram Sabha alert

**Indexes**: `villageId + tier` · `villageId + detectedAt` (DESC)

---

## 12. `sync_audit_log`

Doc ID = auto-generated

| Field | Type | Req | Notes |
|---|---|---|---|
| `action` | String | ✅ | see actions below |
| `entityId` / `entityType` | String | ✅ | `claim`\|`meeting`\|`attendance`\|`resolution`\|etc. |
| `payload` | Map | ✅ | full synced data |
| `createdAt` | Timestamp | ✅ | |
| `lastAttemptAt` | Timestamp | ❌ | |
| `attemptCount` | Integer | ✅ | default `0` |
| `errorMessage` | String | ❌ | |
| `status` | String enum | ✅ | `pending`\|`inProgress`\|`completed`\|`failed` |

**Actions**: `createClaim`, `updateClaim`, `submitClaim`, `createMeeting`, `updateMeeting`, `markAttendance`, `createResolution`, `enrollFace`, `reportAlert`, `publishMomRecord`, `syncFaceEnrollment`

---

## Relationships

```
villages
  ├── users (villageId →)
  ├── village_members (villageId →)
  ├── gram_sabha_meetings (villageId →)
  │     ├── attendance_records (meetingId →, villageId →)
  │     ├── resolutions (meetingId →, villageId →)
  │     └── gram_sabha_mom_records (meetingId →, villageId →)
  ├── claims (villageId →)
  │     └── resolutions (relatedClaimId →)
  ├── boundary_alerts (villageId →)
  ├── gram_sabha_face_enrollments (villageId →)
  └── notices (global)

users
  └── claims (claimantUserId →)

village_members
  ├── attendance_records (memberId →)
  └── gram_sabha_face_enrollments (memberId →)
```

> **Rule of thumb**: `villageId` is a **required field on every collection** — it's what `sameVillage()` security rules check against.

---

## Security Rules Summary

| Collection | Create | Read | Update | Delete |
|---|---|---|---|---|
| `users` | Auth | Own doc or admin | Own doc | ❌ |
| `villages` | Admin | Same village | Admin | ❌ |
| `village_members` | Admin | Same village | Admin | ❌ |
| `gram_sabha_meetings` | Admin | Same village | Admin (status only) | ❌ |
| `attendance_records` | Auth (same village) | Same village | ❌ | ❌ |
| `claims` | Auth (self) | Same village | Self / Admin | ❌ |
| `resolutions` | Admin | Same village | ❌ append-only | ❌ |
| `gram_sabha_mom_records` | Admin | Same village | ❌ append-only | ❌ |
| `gram_sabha_face_enrollments` | Admin | Admin | Admin | ❌ |
| `notices` | Admin | All authenticated | Admin | ❌ |
| `boundary_alerts` | Admin/System | Same village | Admin | ❌ |
| `sync_audit_log` | System | Admin | ❌ | ❌ |

---

## Enum Reference

| Entity | Field | Values |
|---|---|---|
| User | `role` | `admin`, `villager` |
| User | `preferredLanguage` | `en`, `hi`, `mr`, `kn` |
| VillageMember | `gender` | `male`, `female`, `other` |
| VillageMember | `category` | `st`, `pvtg`, `otfd`, `general` |
| GramSabhaMeeting | `type` | `regular`, `special`, `consentResolution` |
| GramSabhaMeeting | `status` | `scheduled`, `inProgress`, `completed`, `cancelled` |
| AttendanceRecord | `method` | `gpsFace`, `manual`, `otp` |
| Claim | `type` | `formA`, `formB` |
| Claim | `status` | `draft`, `submitted`, `underReview`, `approved`, `rejected`, `appealFiled` |
| Claim | `nature` | `cultivation`, `habitation`, `mfpCollection`, `grazing`, `waterBodies`, `traditionalResource`, `other` |
| Resolution | `type` | `claimApproval`, `cfrManagement`, `consentForDiversion`, `mfpSaleTransit`, `other` |
| BoundaryAlert | `tier` | `green`, `yellow`, `red` |
| Notice | `category` | `meetingSchedule`, `claimDeadline`, `documentRequirement`, `portalDowntime`, `general` |
| Notice | `severity` | `info`, `warning`, `critical` |
| Notice | `source` | `adminPosted`, `systemGenerated` |
| SyncItem | `action` | `createClaim`, `updateClaim`, `submitClaim`, `createMeeting`, `updateMeeting`, `markAttendance`, `createResolution`, `enrollFace`, `reportAlert`, `publishMomRecord`, `syncFaceEnrollment` |
| SyncItem | `status` | `pending`, `inProgress`, `completed`, `failed` |
