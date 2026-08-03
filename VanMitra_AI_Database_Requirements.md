# VanMitra-AI — Database Requirements

> **Source**: Derived from `vanmitra_tem` (Flutter/Dart models + Firestore service layer)  
> **Backend**: Google Cloud Firestore (NoSQL document database)  
> **Local/Offline**: Hive (on-device key-value store)  
> **Auth**: Firebase Authentication  
> **Legal Context**: Forest Rights Act (FRA) 2006, PESA 1996, FCA 1980

---

## 1. Database Architecture Overview

VanMitra-AI uses a **dual-database strategy**:

| Layer | Technology | Purpose |
|---|---|---|
| **Cloud (Primary)** | Google Cloud Firestore | Real-time sync, audit trail, multi-device access |
| **Local (Offline)** | Hive (on-device) | Offline-first operation, sync queue |
| **Auth** | Firebase Authentication | User identity management |

### Firestore Collections (Top-Level)

| Collection Name | Description |
|---|---|
| `users` | User profiles and roles |
| `villages` | Village metadata and demographics |
| `village_members` | Registered adult members of each Gram Sabha |
| `gram_sabha_meetings` | Gram Sabha meeting records |
| `attendance_records` | Per-member attendance verification |
| `claims` | FRA claims (Form A & Form B) |
| `resolutions` | Tamper-evident hash-chain resolutions |
| `gram_sabha_mom_records` | Minutes of Meeting (tamper-evident) |
| `gram_sabha_face_enrollments` | Face embeddings (128-dim FaceNet vectors) |
| `notices` | System & admin notices (notice board) |
| `boundary_alerts` | Satellite NDVI boundary-change alerts |
| `sync_audit_log` | Offline sync event log |

---

## 2. Collection Schemas

---

### 2.1 `users`

**Document ID**: Firebase Auth UID

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Firebase Auth UID |
| `email` | `String` | ✅ | User email address |
| `name` | `String` | ✅ | Full display name |
| `role` | `String` (enum) | ✅ | `admin` \| `villager` |
| `villageId` | `String` | ✅ | FK → `villages` |
| `memberId` | `String?` | ❌ | FK → `village_members` (for attendance linking) |
| `preferredLanguage` | `String` | ✅ | `mr` \| `en` \| `hi` \| `kn` (default: `mr`) |
| `createdAt` | `Timestamp` (ISO-8601) | ✅ | Account creation timestamp |
| `hasFaceEnrolled` | `Boolean` | ✅ | Whether face biometric is registered (default: `false`) |

**Roles**:
- `admin` — Gram Sabha Admin: can manage meetings, attendance, resolutions, review claims
- `villager` — Villager / Claimant: can file claims, self check-in, view records

**Indexes Required**:
- `villageId` (filter by village)

---

### 2.2 `villages`

**Document ID**: Auto-generated or village code (e.g., `MH-PU-001`)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique village identifier |
| `nameMarathi` | `String` | ✅ | Village name in Marathi |
| `nameEnglish` | `String` | ✅ | Village name in English |
| `nameHindi` | `String` | ❌ | Village name in Hindi |
| `nameKonkani` | `String` | ❌ | Village name in Konkani |
| `talukaMarathi` | `String` | ✅ | Taluka in Marathi |
| `talukaEnglish` | `String` | ✅ | Taluka in English |
| `districtMarathi` | `String` | ✅ | District in Marathi |
| `districtEnglish` | `String` | ✅ | District in English |
| `stateMarathi` | `String` | ✅ | State in Marathi |
| `stateEnglish` | `String` | ✅ | State in English |
| **Demographics** | | | |
| `totalPopulation` | `Integer` | ✅ | Total village population |
| `registeredAdultMembers` | `Integer` | ✅ | R — total registered adult Gram Sabha members |
| `registeredWomenMembers` | `Integer` | ✅ | W — registered women members |
| `registeredMenMembers` | `Integer` | ✅ | M — registered men members |
| `stMembers` | `Integer` | ✅ | Scheduled Tribe members count |
| `pvtgMembers` | `Integer` | ✅ | PVTG members count |
| `otfdMembers` | `Integer` | ✅ | Other Traditional Forest Dwellers count |
| `stPercentage` | `Float` | ✅ | % of ST members |
| `pvtgPercentage` | `Float` | ✅ | % of PVTG members |
| **Geography** | | | |
| `latitude` | `Float` | ✅ | Village GPS latitude |
| `longitude` | `Float` | ✅ | Village GPS longitude |
| `meetingVenueLat` | `Float` | ✅ | Gram Sabha venue latitude (for geofence) |
| `meetingVenueLng` | `Float` | ✅ | Gram Sabha venue longitude (for geofence) |
| `cfrAreaHectares` | `Float` | ✅ | Community Forest Resource area (ha) |
| **Claim Statistics** | | | |
| `totalApprovedClaims` | `Integer` | ✅ | Count of approved FRA claims |
| `totalApprovedAreaSqm` | `Integer` | ✅ | Total approved area (sq. meters) |
| `approvedRightType` | `String` | ❌ | Type of approved forest right |
| `casteCategory` | `String` | ❌ | Dominant caste/community category |

---

### 2.3 `village_members`

**Document ID**: Auto-generated or `{villageId}_{memberId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique member ID |
| `nameMarathi` | `String` | ✅ | Member name in Marathi |
| `nameEnglish` | `String` | ✅ | Member name in English |
| `gender` | `String` (enum) | ✅ | `male` \| `female` \| `other` |
| `category` | `String` (enum) | ✅ | `st` \| `pvtg` \| `otfd` \| `general` |
| `villageId` | `String` | ✅ | FK → `villages` |
| `age` | `Integer?` | ❌ | Age of member |
| `phoneNumber` | `String?` | ❌ | Contact number |
| `hasSmartphone` | `Boolean` | ✅ | Whether member has a smartphone (default: `true`) |
| `faceEmbeddingId` | `String?` | ❌ | Legacy reference to face data (for compat) |
| `isActive` | `Boolean` | ✅ | Currently a registered member (default: `true`) |
| **Module C — Face Biometrics** | | | |
| `faceEmbedding` | `Array<Float>` (128-dim) | ❌ | FaceNet embedding vector (null if not enrolled) |
| `enrolledAt` | `Timestamp?` | ❌ | Timestamp when face was enrolled |

**Enums**:
- `gender`: `male`, `female`, `other`
- `category`: `st` (Scheduled Tribe), `pvtg` (Particularly Vulnerable Tribal Group), `otfd` (Other Traditional Forest Dweller), `general`

**Indexes Required**:
- `villageId` (filter members by village)
- `villageId + isActive` (active members only)

> [!NOTE]
> The `faceEmbedding` is a **128-dimensional float vector** stored inline. For privacy, **raw face photos are never uploaded** to Firestore — only the mathematical embedding.

---

### 2.4 `gram_sabha_meetings`

**Document ID**: UUID (`{villageId}_{date}_{type}`)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique meeting ID |
| `villageId` | `String` | ✅ | FK → `villages` |
| `scheduledDate` | `Timestamp` (ISO-8601) | ✅ | Planned date/time of meeting |
| `startedAt` | `Timestamp?` | ❌ | When meeting actually started |
| `completedAt` | `Timestamp?` | ❌ | When meeting ended |
| `type` | `String` (enum) | ✅ | `regular` \| `special` \| `consentResolution` |
| `status` | `String` (enum) | ✅ | `scheduled` \| `inProgress` \| `completed` \| `cancelled` |
| `venue` | `String` | ✅ | Venue name/address |
| `venueLat` | `Float` | ✅ | Venue GPS latitude (geofence center) |
| `venueLng` | `Float` | ✅ | Venue GPS longitude |
| `agenda` | `String?` | ❌ | Meeting agenda text |
| `createdByUserId` | `String` | ✅ | FK → `users` (admin who created meeting) |
| `resolutionIds` | `Array<String>` | ✅ | FKs → `resolutions` (default: `[]`) |
| `totalAttendees` | `Integer` | ✅ | Final total attendees (A) |
| `womenAttendees` | `Integer` | ✅ | Final women attendees (W) |
| `stAttendees` | `Integer` | ✅ | ST members who attended |
| `pvtgAttendees` | `Integer` | ✅ | PVTG members who attended |
| `quorumValid` | `Boolean` | ✅ | Whether quorum was met |

**Meeting Types**:
- `regular` — Standard Gram Sabha meeting
- `special` — Called for specific agenda
- `consentResolution` — Requires **enhanced quorum** (per 2009 MoEFCC Circular)

**Quorum Rules** (computed, not stored):
- **Standard**: A/R ≥ 50% AND W/A ≥ 33.3%
- **Enhanced** (consent resolutions): Standard + ST present + PVTG present

**Indexes Required**:
- `villageId + scheduledDate` (DESC)
- `villageId + status`

---

### 2.5 `attendance_records`

**Document ID**: Deterministic — `ATT_{meetingId}_{memberId}` (makes write idempotent)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Deterministic ID |
| `meetingId` | `String` | ✅ | FK → `gram_sabha_meetings` |
| `memberId` | `String` | ✅ | FK → `village_members` |
| `memberName` | `String` | ✅ | Snapshot of member name |
| `villageId` | `String` | ✅ | FK → `villages` (required by Firestore security rules) |
| `method` | `String` (enum) | ✅ | `gpsFace` \| `manual` \| `otp` |
| `timestamp` | `Timestamp` (ISO-8601) | ✅ | When attendance was marked |
| **GPS Verification** | | | |
| `gpsLatitude` | `Float?` | ❌ | Attendee GPS latitude |
| `gpsLongitude` | `Float?` | ❌ | Attendee GPS longitude |
| `gpsAccuracyMeters` | `Float?` | ❌ | GPS accuracy radius |
| `distanceFromVenueMeters` | `Float?` | ❌ | Computed distance from meeting venue |
| `gpsVerified` | `Boolean` | ✅ | Whether GPS check passed (default: `false`) |
| **Face Verification** | | | |
| `faceMatchConfidence` | `Float?` | ❌ | Cosine similarity score [0.0–1.0] |
| `faceVerified` | `Boolean` | ✅ | Whether face match passed (default: `false`) |
| **Manual Entry** | | | |
| `manualEntryByUserId` | `String?` | ❌ | FK → `users` (admin who marked manually) |
| `manualEntryReason` | `String?` | ❌ | Reason for manual override |
| **Demographics Snapshot** | | | |
| `gender` | `String` | ✅ | Snapshot: `male` \| `female` \| `other` |
| `category` | `String` | ✅ | Snapshot: `st` \| `pvtg` \| `otfd` \| `general` |

**Verification Methods**:
- `gpsFace` — GPS geofence + FaceNet biometric (primary method)
- `manual` — Admin marked (for elderly/no-smartphone members)
- `otp` — OTP-based (future)

**Indexes Required**:
- `meetingId + timestamp` (ASC)
- `villageId + meetingId`

> [!IMPORTANT]
> `villageId` must be present in every document — it is required by the Firestore security rule `sameVillage(request.resource.data.villageId)`.

---

### 2.6 `claims`

**Document ID**: UUID

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique claim ID |
| `claimantUserId` | `String` | ✅ | FK → `users` |
| `villageId` | `String` | ✅ | FK → `villages` |
| `type` | `String` (enum) | ✅ | `formA` \| `formB` |
| `status` | `String` (enum) | ✅ | See lifecycle below |
| `nature` | `String` (enum) | ✅ | Type of forest right claimed |
| **Claimant Details** | | | |
| `claimantName` | `String` | ✅ | Name in Marathi |
| `claimantNameEn` | `String` | ✅ | Name in English |
| `fatherHusbandName` | `String?` | ❌ | Father/husband name |
| `address` | `String?` | ❌ | Claimant address |
| **Land Details** | | | |
| `surveyNumber` | `String?` | ❌ | Survey / Gat number |
| `areaSqMeters` | `Float?` | ❌ | Claimed area in sq. meters |
| `landDescription` | `String?` | ❌ | Description of claimed land |
| **Occupation** | | | |
| `occupationYears` | `Integer?` | ❌ | Number of years of occupation |
| `occupationBefore2005` | `Boolean` | ✅ | Occupied before 13.12.2005 (cutoff date) |
| **Evidence** | | | |
| `evidenceFlags` | `Map<String, Boolean>` | ✅ | Category key → present/absent |
| `evidenceScore` | `Float` | ✅ | E ∈ [0.0, 1.0] — completeness score |
| `missingEvidence` | `Array<String>` | ✅ | List of missing category keys |
| **Dates** | | | |
| `createdAt` | `Timestamp` | ✅ | Draft creation time |
| `submittedAt` | `Timestamp?` | ❌ | When submitted for review |
| `reviewedAt` | `Timestamp?` | ❌ | When review completed |
| `rejectedAt` | `Timestamp?` | ❌ | When rejected |
| `rejectionReason` | `String?` | ❌ | Reason for rejection |
| `appealDeadline` | `Timestamp?` | ❌ | `rejectedAt + 60 days` |
| **Sync** | | | |
| `isSynced` | `Boolean` | ✅ | Whether synced to cloud |

**Claim Types**:
- `formA` — Individual Forest Right (IFR) under Sec. 3(1)(a), or Community Rights (CR) under Sec. 3(1)(b-d)
- `formB` — Community Forest Resource Right (CFRR) under Sec. 3(1)(i)

**Claim Status Lifecycle**:

```
draft → submitted → underReview → approved
                              ↘ rejected → appealFiled
```

**Claim Nature Types**:
`cultivation`, `habitation`, `mfpCollection`, `grazing`, `waterBodies`, `traditionalResource`, `other`

**Evidence Score Tiers**:
- 🟢 Green: E ≥ 0.8
- 🟡 Yellow: E ≥ 0.6
- 🔴 Red: E < 0.6

**Indexes Required**:
- `villageId + createdAt` (DESC)
- `claimantUserId + createdAt` (DESC)
- `villageId + status`

---

### 2.7 `resolutions`

**Document ID**: UUID (Firestore security rules block updates — append-only)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique resolution ID |
| `meetingId` | `String` | ✅ | FK → `gram_sabha_meetings` |
| `villageId` | `String` | ✅ | FK → `villages` |
| `type` | `String` (enum) | ✅ | Resolution type |
| `text` | `String` | ✅ | Resolution text (Marathi or English) |
| `summary` | `String?` | ❌ | Short summary |
| `timestamp` | `Timestamp` | ✅ | When resolution was recorded |
| `recordedByUserId` | `String` | ✅ | FK → `users` |
| **Quorum Snapshot** | | | |
| `quorumValid` | `Boolean` | ✅ | Was quorum valid at time of resolution? |
| `totalPresent` | `Integer` | ✅ | A — attendees at resolution time |
| `totalRegistered` | `Integer` | ✅ | R — total registered members |
| `womenPresent` | `Integer` | ✅ | W — women present |
| `stPresent` | `Integer` | ✅ | ST members present |
| `pvtgPresent` | `Integer` | ✅ | PVTG members present |
| `attendancePercentage` | `Float` | ✅ | A/R × 100 |
| `womenPercentage` | `Float` | ✅ | W/A × 100 |
| **Hash Chain (Tamper-Evident Ledger)** | | | |
| `hash` | `String` | ✅ | Hₙ = SHA-256(Hₙ₋₁ ∥ Dₙ ∥ tₙ) |
| `previousHash` | `String` | ✅ | Hₙ₋₁ (previous block hash) |
| `blockIndex` | `Integer` | ✅ | Position in chain (0 = genesis) |
| **Relations** | | | |
| `relatedClaimId` | `String?` | ❌ | FK → `claims` (if `claimApproval` type) |
| `isCompliant` | `Boolean` | ✅ | `quorumValid AND enhanced quorum (if consent)` |

**Resolution Types**:
- `claimApproval` — FRA Sec. 6(1) — Gram Sabha claim verification
- `cfrManagement` — FRA Sec. 3(1)(i) — CFR management
- `consentForDiversion` — FCA 1980 + 2009 MoEFCC Circular (requires enhanced quorum)
- `mfpSaleTransit` — FRA Sec. 3(1)(c) — MFP rights
- `other` — PESA 1996 general powers

**Hash Payload** (tamper-evident content):
```
{type}|{text}|{totalPresent}/{totalRegistered}|W:{womenPresent}|ST:{stPresent}|PVTG:{pvtgPresent}|Q:{quorumValid}|C:{isCompliant}
```

**Indexes Required**:
- `villageId + blockIndex` (ASC)

> [!CAUTION]
> Resolutions are **append-only**. Firestore security rules must block all update/delete operations on this collection.

---

### 2.8 `gram_sabha_mom_records`

**Document ID**: UUID (append-only)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique MoM record ID |
| `meetingId` | `String` | ✅ | FK → `gram_sabha_meetings` |
| `villageId` | `String` | ✅ | FK → `villages` |
| `meetingDate` | `String` (ISO-8601) | ✅ | Date of the meeting |
| `geotag` | `String` | ✅ | `"lat,lng"` format |
| **Multilingual Resolution Text** | | | |
| `decisionTextEn` | `String` | ✅ | Resolution text in English |
| `decisionTextHi` | `String` | ✅ | Resolution text in Hindi |
| `decisionTextMr` | `String` | ✅ | Resolution text in Marathi |
| `sourceLanguage` | `String` | ✅ | Spoken source language: `mr` \| `hi` \| `gon` \| `wbr` |
| **Attendance & Quorum Snapshot** | | | |
| `attendeeCount` | `Integer` | ✅ | A — total verified attendees |
| `registeredCount` | `Integer` | ✅ | R — total registered members |
| `womenCount` | `Integer` | ✅ | W — women attendees |
| `quorumValid` | `Boolean` | ✅ | Q_valid = (A/R ≥ 0.5) AND (W/A ≥ 1/3) |
| `quorumExplanation` | `String` | ✅ | Human-readable quorum explanation |
| `faceMatchedCount` | `Integer` | ✅ | Attendees verified via face biometric |
| `manualAddedCount` | `Integer` | ✅ | Attendees added manually by admin |
| **Hash Chain Fields** | | | |
| `localHash` | `String` | ✅ | Provisional client-side SHA-256 hash |
| `canonicalHash` | `String?` | ❌ | Server-assigned canonical hash (after sync) |
| `timestampUtc` | `String` (ISO-8601) | ✅ | Device UTC timestamp |
| `firestoreTimestamp` | `String?` | ❌ | Firestore server timestamp (canonical tₙ) |
| `serverTimestamp` | `Timestamp` | — | Auto-set by FieldValue.serverTimestamp() on write |
| **Media** | | | |
| `groupPhotoLocalPath` | `String?` | ❌ | On-device path to group photo (never uploaded) |
| **Sync** | | | |
| `isSynced` | `Boolean` | ✅ | Whether published to Firestore |

**Canonical JSON for hashing** (sorted keys, deterministic):
```json
{
  "decision_text_en": "...",
  "decision_text_hi": "...",
  "decision_text_mr": "...",
  "geotag": "lat,lng",
  "group_photo_path": null,
  "meeting_date": "ISO-8601",
  "quorum": { "A": int, "Q_valid": bool, "R": int, "W": int },
  "source_language": "mr",
  "village_id": "..."
}
```

**Hash Formula**: `SHA-256(prevHash | canonicalJSON | timestampUtc)`

**Indexes Required**:
- `villageId + timestampUtc` (ASC)

---

### 2.9 `gram_sabha_face_enrollments`

**Document ID**: `memberId`

| Field | Type | Required | Description |
|---|---|---|---|
| `memberId` | `String` | ✅ | FK → `village_members` (doc ID) |
| `villageId` | `String` | ✅ | FK → `villages` |
| `embedding` | `Array<Float>` (128-dim) | ✅ | FaceNet face embedding vector |
| `enrolledAt` | `Timestamp` | ✅ | When enrollment was captured |

> [!WARNING]
> **Privacy rule**: Raw face images/photos are **never stored** in Firestore. Only the 128-dimensional numerical embedding vector is synced. On-device photos are processed locally and immediately discarded.

**Indexes Required**:
- `villageId` (fetch all embeddings for a village)

---

### 2.10 `notices`

**Document ID**: `noticeId`

| Field | Type | Required | Description |
|---|---|---|---|
| `noticeId` | `String` | ✅ | Unique notice ID |
| `category` | `String` (enum) | ✅ | Notice category |
| `titleByLang` | `Map<String, String>` | ✅ | `{ "mr": "...", "en": "...", "hi": "...", "kn": "..." }` |
| `bodyByLang` | `Map<String, String>` | ✅ | Localized body text by language code |
| `severity` | `String` (enum) | ✅ | `info` \| `warning` \| `critical` |
| `validFrom` | `Timestamp` | ✅ | When notice becomes active |
| `validUntil` | `Timestamp` | ✅ | When notice expires |
| `linkedMeetingId` | `String?` | ❌ | FK → `gram_sabha_meetings` (deep-link) |
| `linkedClaimId` | `String?` | ❌ | FK → `claims` (deep-link) |
| `source` | `String` (enum) | ✅ | `adminPosted` \| `systemGenerated` |
| `isDismissed` | `Boolean` | ✅ | Whether user dismissed (default: `false`) |
| `createdAt` | `Timestamp` | ✅ | Notice creation time |

**Categories**: `meetingSchedule`, `claimDeadline`, `documentRequirement`, `portalDowntime`, `general`

**Severity Mapping**:
- `info` → Government blue ticker
- `warning` → Amber ticker
- `critical` → Red ticker

**Indexes Required**:
- `validUntil` (filter active notices: `validUntil > now()`)

---

### 2.11 `boundary_alerts`

**Document ID**: UUID

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | ✅ | Unique alert ID |
| `villageId` | `String` | ✅ | FK → `villages` |
| `tier` | `String` (enum) | ✅ | `green` \| `yellow` \| `red` |
| `detectedAt` | `Timestamp` | ✅ | When the change was detected |
| `resolvedAt` | `Timestamp?` | ❌ | When the alert was resolved |
| **Location** | | | |
| `latitude` | `Float` | ✅ | Latitude of change area |
| `longitude` | `Float` | ✅ | Longitude of change area |
| `affectedAreaSqMeters` | `Float?` | ❌ | Area of detected change |
| **NDVI Data** | | | |
| `ndviChange` | `Float?` | ❌ | ΔNDVI value (negative = vegetation loss) |
| `imagerySource` | `String?` | ❌ | e.g., `"Sentinel-2 L2A"` |
| `imageryDate` | `Timestamp?` | ❌ | Date of satellite imagery used |
| **Description** | | | |
| `description` | `String` | ✅ | Change description in English |
| `descriptionMr` | `String?` | ❌ | Change description in Marathi |
| **Actions** | | | |
| `isReported` | `Boolean` | ✅ | Whether formally reported (default: `false`) |
| `reportedTo` | `String?` | ❌ | e.g., `"District Office"` / `"NGO"` |
| `reportedAt` | `Timestamp?` | ❌ | When reported |

**Alert Tiers** (NDVI change-detection thresholds):
- 🟢 `green` — No significant change, routine monitoring
- 🟡 `yellow` — Localised change, possible natural/seasonal variation, logged for weekly review
- 🔴 `red` — ΔNDVI < −θ, probable unauthorised activity — immediate Gram Sabha alert

**Indexes Required**:
- `villageId + tier` (filter `red` alerts only — used in live stream)
- `villageId + detectedAt` (DESC)

---

### 2.12 `sync_audit_log`

**Document ID**: Auto-generated

| Field | Type | Required | Description |
|---|---|---|---|
| `action` | `String` | ✅ | The sync action performed |
| `entityId` | `String` | ✅ | ID of the synced entity |
| `entityType` | `String` | ✅ | `claim` \| `meeting` \| `attendance` \| `resolution` \| etc. |
| `payload` | `Map` | ✅ | Full data payload that was synced |
| `createdAt` | `Timestamp` | ✅ | When sync item was queued |
| `lastAttemptAt` | `Timestamp?` | ❌ | Last sync attempt timestamp |
| `attemptCount` | `Integer` | ✅ | Number of sync attempts (default: `0`) |
| `errorMessage` | `String?` | ❌ | Error message if failed |
| `status` | `String` (enum) | ✅ | `pending` \| `inProgress` \| `completed` \| `failed` |

**Sync Actions**: `createClaim`, `updateClaim`, `submitClaim`, `createMeeting`, `updateMeeting`, `markAttendance`, `createResolution`, `enrollFace`, `reportAlert`, `publishMomRecord`, `syncFaceEnrollment`

---

## 3. Local Offline Storage (Hive)

Hive boxes are used for on-device offline-first operation:

| Hive Box Name | Stores | Notes |
|---|---|---|
| `notices` | `Notice` objects | Notice board data |
| `sync_queue` | `SyncItem` objects | Pending offline actions |
| `claims_cache` | `Claim` objects | Local drafts and cache |
| `meetings_cache` | `GramSabhaMeeting` objects | Cached meeting list |
| `members_cache` | `VillageMember` objects | Cached member list (for attendance) |
| `face_embeddings` | `Map<memberId, List<double>>` | Local face embedding store (128-dim) |

---

## 4. Relationships Diagram

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
  └── attendance_records (memberId →)
  └── gram_sabha_face_enrollments (memberId →)
```

---

## 5. Evidence Categories (Rule 13, FRA Rules 2008)

Stored as a static reference lookup (not a Firestore collection). Used to populate `evidenceFlags` in `claims`.

| Key | Name (EN) | Weight | Description |
|---|---|---|---|
| `government_records` | Government Records | 0.25 | Voter ID, ration card, revenue records, court orders |
| `physical_attestation` | Physical Structures | 0.25 | Houses, wells, fencing, crops on the land |
| `satellite_imagery` | Satellite/Aerial Imagery | 0.15 | Pre-2005 imagery from Google Earth, ISRO Bhuvan |
| `elder_statements` | Statements of Elders | 0.15 | Written sworn statements from ≥ 2 elder neighbours |
| `traditional_structures` | Traditional Community Structures | 0.10 | Sacred groves (dev rai), burial sites, customary markers |
| `other_govt_schemes` | Other Government Scheme Evidence | 0.10 | MGNREGA job cards, BPL records, Anganwadi records |

**Evidence Score Formula**: `E = Σ(weight_i) for all present evidence categories`

---

## 6. Security Rules Summary

| Collection | Create | Read | Update | Delete |
|---|---|---|---|---|
| `users` | Auth | Own doc or admin | Own doc | ❌ |
| `villages` | Admin | Same village | Admin | ❌ |
| `village_members` | Admin | Same village | Admin | ❌ |
| `gram_sabha_meetings` | Admin | Same village | Admin (status only) | ❌ |
| `attendance_records` | Authenticated (same village) | Same village | ❌ | ❌ |
| `claims` | Authenticated (self) | Same village | Self / Admin | ❌ |
| `resolutions` | Admin | Same village | ❌ (append-only) | ❌ |
| `gram_sabha_mom_records` | Admin | Same village | ❌ (append-only) | ❌ |
| `gram_sabha_face_enrollments` | Admin | Admin | Admin | ❌ |
| `notices` | Admin | All authenticated | Admin | ❌ |
| `boundary_alerts` | Admin/System | Same village | Admin | ❌ |
| `sync_audit_log` | System | Admin | ❌ | ❌ |

> [!IMPORTANT]
> `sameVillage()` rule checks `request.resource.data.villageId == resource.data.villageId` and matches the user's enrolled `villageId`. This is why `villageId` is a **required field in every collection**.

---

## 7. Quorum Computation Rules

| Check | Formula | Threshold |
|---|---|---|
| Attendance (A/R) | `totalPresent / registeredAdultMembers` | ≥ 50% |
| Women (W/A) | `womenPresent / totalPresent` | ≥ 33.3% (1/3) |
| ST Representation | `stPresent > 0` | Required for consent resolutions |
| PVTG Representation | `pvtgPresent > 0` | Required for consent resolutions |
| **Standard Quorum** | A/R ≥ 0.5 AND W/A ≥ 1/3 | All regular & special meetings |
| **Enhanced Quorum** | Standard + ST present + PVTG present | Consent resolution meetings only |

---

## 8. Summary of Enum Values

| Entity | Field | Allowed Values |
|---|---|---|
| `User` | `role` | `admin`, `villager` |
| `User` | `preferredLanguage` | `en`, `hi`, `mr`, `kn` |
| `VillageMember` | `gender` | `male`, `female`, `other` |
| `VillageMember` | `category` | `st`, `pvtg`, `otfd`, `general` |
| `GramSabhaMeeting` | `type` | `regular`, `special`, `consentResolution` |
| `GramSabhaMeeting` | `status` | `scheduled`, `inProgress`, `completed`, `cancelled` |
| `AttendanceRecord` | `method` | `gpsFace`, `manual`, `otp` |
| `Claim` | `type` | `formA`, `formB` |
| `Claim` | `status` | `draft`, `submitted`, `underReview`, `approved`, `rejected`, `appealFiled` |
| `Claim` | `nature` | `cultivation`, `habitation`, `mfpCollection`, `grazing`, `waterBodies`, `traditionalResource`, `other` |
| `Resolution` | `type` | `claimApproval`, `cfrManagement`, `consentForDiversion`, `mfpSaleTransit`, `other` |
| `BoundaryAlert` | `tier` | `green`, `yellow`, `red` |
| `Notice` | `category` | `meetingSchedule`, `claimDeadline`, `documentRequirement`, `portalDowntime`, `general` |
| `Notice` | `severity` | `info`, `warning`, `critical` |
| `Notice` | `source` | `adminPosted`, `systemGenerated` |
| `SyncItem` | `action` | `createClaim`, `updateClaim`, `submitClaim`, `createMeeting`, `updateMeeting`, `markAttendance`, `createResolution`, `enrollFace`, `reportAlert`, `publishMomRecord`, `syncFaceEnrollment` |
| `SyncItem` | `status` | `pending`, `inProgress`, `completed`, `failed` |
