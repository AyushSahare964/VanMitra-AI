# VanMitra-AI: Comprehensive UI/UX Architecture, Screen Flows & Theme System

This document defines the architecture, visual design language, theme design tokens, screen inventory, and user navigational pathways for **VanMitra-AI**—an AI-powered, offline-first digital governance platform designed to democratize Forest Rights Act (FRA 2006) administration and digital Gram Sabha compliance.

---

## 1. UI/UX Design Philosophy & Visual Design System

VanMitra-AI is architected for a wide user spectrum: forest dwellers (tribals, traditional forest dwellers with potentially low digital literacy) to government-appointed Forest Rights Committee (FRC) officials and Village Admins. 

### Core UX Principles:
1. **Familiarity & Trust (MAHA-DBT Portal Aesthetics):** Replicates the verified color palettes, clear iconography, and spatial framing of official government systems (such as Maharashtra's MAHA-DBT portal and traditional Indian administrative design) to build instant trust with community members and public officials.
2. **High Contrast & Sunlight Legibility:** Operates on an **All-White High-Contrast Surface Theme** (`#FFFFFF` backgrounds with Slate near-black typography) ensuring clear visibility under direct outdoor forest sunlight on entry-level smartphones.
3. **Vernacular & Audio-First Interfaces:** Every critical screen supports 4 scheduled languages (**Marathi, Hindi, English, Kannada**) with text-to-speech (TTS) playback read-aloud buttons and voice-note input options for seamless inclusivity.
4. **Offline-First Resilience Indicators:** Visual connectivity badges clearly inform users whether their inputs are saved locally in high-speed **Hive DB offline storage** or securely synced to **Firebase Cloud Firestore**.

---

### Master Theme & Color Palette Tokens (`AppColors`)

| Color Category | Name | Hex Code | Visual Preview | Semantic Purpose & Usage in UI |
| :--- | :--- | :--- | :--- | :--- |
| **Govt Portal Tokens** | **Govt Blue** | `#0B3D91` | 🔵 Navy | Official header bars, primary interactive buttons, and system notices. |
| | **Accent Saffron** | `#FF7A00` | 🟠 Saffron | Active bottom navigation tab, urgent "New Claim" call-to-action (CTA) buttons, notice ticker bar. |
| | **Success Green** | `#1E8E3E` | 🟢 Green | Approved FRA claim status, valid Gram Sabha quorum met indicator. |
| | **Warning Amber** | `#F2A900` | 🟡 Amber | Pending verification, incomplete Rule 13 evidence, borderline quorum warnings. |
| | **Alert Red** | `#D32F2F` | 🔴 Red | Rejected claims, severe deforestation/encroachment satellite alerts, chain tampering detected. |
| **Branding Primary** | **Ashoka Navy** | `#000080` | Navy | Main brand identity, deep contrast title headers, card highlights. |
| | **Primary Light** | `#333399` | Light Navy | Secondary button borders, hovered states, subtitle underlines. |
| **Branding Secondary** | **Saffron Bright** | `#FFFF9933`| Light Saffron | Highlights, alert badges, floating action buttons (FAB). |
| **Surface & Cards** | **Pure White** | `#FFFFFF` | White | Scaffold backgrounds, main container cards, form surfaces. |
| | **Card Elevated** | `#FAFAFA` | Off-White | Elevated list item cards, dropdown selection surfaces, dialogue modals. |
| | **Subtle Divider** | `#E2E8F0` | Light Slate | Section splitters, form input borders, chart gridlines. |
| **Typography** | **Text Primary** | `#0F172A` | Slate Black | Maximum readability body copy and form labels. |
| | **Text Secondary**| `#475569` | Mid Slate | Metadata timestamps, subtitle explanations, legal Rule references. |
| **Demographic Inclusion** | **Women Quorum** | `#7B1FA2` | 🟣 Purple | Dedicated tracking bars & badges for **Rule 4 Women (33%+ requirement)**. |
| | **ST Representation** | `#00838F` | 3 Cyan | Scheduled Tribe representation statistics and attendance graphs. |
| | **PVTG Representation** | `#E65100` | Orange | Particularly Vulnerable Tribal Groups (PVTG) special attention flags. |
| **Biometrics & Sync**| **Face Verified** | `#512DA8` | Deep Purple | Facial embedding verification stamp during Gram Sabha attendance check-in. |
| | **GPS Verified** | `#1976D2` | Blue | Geofence location validation badge (user within 500m of meeting venue). |

---

## 2. Overall Navigation Flow & Architecture Map

```
[ Splash / Initialization ]
         │
         ▼
[ Language Selection (Marathi / Hindi / English / Kannada) ]
         │
         ▼
[ User Registration / Authentication ] ──(Village Dropdown: OZH-01 / JWH-01)
         │
         ├────────────────────────┬────────────────────────┐
         ▼ (Role: Villager)       ▼ (Role: Admin/FRC)       ▼ (Shared Tools)
 ┌───────────────┐        ┌───────────────┐         ┌─────────────────────────┐
 │ Villager Home │        │  Admin Home   │         │ Legal & Rights Hub      │
 └───────┬───────┘        └───────┬───────┘         ├─ FRA 2006 Reference     │
         │                        │                 ├─ Rule 4 Quorum Guide    │
         │                        │                 ├─ Rule 13 Evidence Guide │
         │                        │                 └─ PESA Act Rights        │
         ▼                        ▼                 └─────────────────────────┘
 ┌─────────────────────────────────────────────────────────────┐
 │                     CORE APPLICATION MODULES                │
 ├─────────────────────────┬─────────────────┬─────────────────┤
 │ MODULE A: FRA CLAIMS    │ MODULE B: ATLAS │ MODULE C: SABHA │
 ├─────────────────────────┼─────────────────┼─────────────────┤
 │ • My Claims Dashboard   │ • GIS Boundary  │ • Upcoming Meet │
 │ • Select Claim Type     │   Map Viewer    │ • Face Enrolment│
 │   (IFR / CR / CFR)      │ • Sentinel-2    │ • Self Check-in │
 │ • Rule 13 Evidence      │   NDVI Alerts   │ • Attendance Log│
 │ • Voice & OCR Claim     │ • Alert Details │ • Quorum Monitor│
 │ • Rejection & Appeal    │   (Red/Amber)   │ • AI Resolution │
 │   Drafting (Section 6)  │ • Alert History │ • SHA-256 Ledger│
 └─────────────────────────┴─────────────────┴─────────────────┘
```

---

## 3. Comprehensive Screen Inventory & Technical Specifications

### I. Onboarding & Authentication Module

#### 1. Splash Screen (`/`)
* **Purpose:** Initial application loading, local Hive box initialization, offline sync queue status checking, and user session verification.
* **Theme & UI Style:** Minimalist, high-impact branding. Centered Ashoka Navy logo over clean white surface with subtle Saffron progress indicator.
* **Connected Entities:** `HiveDatabase` (`settingsBox`, `usersBox`), Firebase Auth session check.
* **Next Destinations:** 
  * If no language selected: -> **Language Selection Screen** (`/language`)
  * If language set but unauthenticated: -> **Registration Screen** (`/registration`)
  * If session active & role == `admin`: -> **Admin Home** (`/admin-home`)
  * If session active & role == `villager`: -> **Villager Home** (`/villager-home`)

#### 2. Language Selection Screen (`/language`)
* **Purpose:** Ensures vernacular empowerment before asking for any text interaction.
* **Theme & UI Style:** Large, highly clickable selection cards with localized scripts (**मराठी, हिन्दी, English, ಕನ್ನಡ**). Selected card highlights in **Accent Saffron** with a green verification checkmark.
* **Connected Entities:** `LocalizationService`, sets preferences in Hive `settingsBox`.
* **Next Destination:** -> **Registration Screen** (`/registration`)

#### 3. User Registration / Onboarding Screen (`/registration`)
* **Purpose:** Authenticates users and assigns them to an official village identity and permission role.
* **Theme & UI Style:** Govt-trusted Form layout. Input fields styled with `#E2E8F0` borders. Includes an interactive **Village Selector Dropdown** showing canonical village identifiers (`OZH-01` for Ozhar, `JWH-01` for Jawahar, etc.) with automated ID display in monospace text. Role selector radio cards between *"Village Citizen / Gram Sabha Member"* and *"Village Admin / FRC Member"*.
* **Connected Entities:** Creates document in `users/{uid}` collection, initializes/upserts village in `villages/{id}`, flushes Cloud Sync Queue via `CloudSyncService().syncPendingItems()`.
* **Next Destination:** -> **Villager Home** (`/villager-home`) OR -> **Admin Home** (`/admin-home`)

---

### II. Role-Based Dashboards

#### 4. Villager Home Dashboard (`/villager-home`)
* **Purpose:** Centralized operating hub for forest community members to file claims, view notices, and check into community meetings.
* **Theme & UI Style:** Features a **MAHA-DBT styled horizontal Notice Ticker** at the top (color-coded by notice severity: Red/Amber/Blue). Quick-action tile grid with bold icons and audio read-aloud buttons. Displays "Sync Status" indicator in header.
* **Key Components:** Notice Board banner, "Apply for Forest Rights (IFR/CFR)" CTA button, Active Meetings badge, Quick legal rights lookup tile.
* **Connected Entities:** Streams from `notices` collection, reads user profile from `users` collection.
* **Next Destinations:** -> **Claim Type Selection** (`/claims/type`), -> **Upcoming Meetings** (`/gram-sabha/upcoming`), -> **My Claims** (`/claims/my`), -> **Legal FRA Rights** (`/legal/fra`), -> **Profile** (`/profile`).

#### 5. Admin & FRC Home Dashboard (`/admin-home`)
* **Purpose:** Command & control panel for Village FRC Secretaries, Sarpanches, and System Administrators to organize Gram Sabhas, verify attendance, monitor claims, and post announcements.
* **Theme & UI Style:** Professional dashboard architecture. Utilizes **Govt Blue** table cards and KPI scorecards (Total Village Claims, Active Quorum Percentage, Offline Pending Sync Items).
* **Key Components:** Notice Broadcasting modal launcher, FRC Claim verification tracker, Gram Sabha scheduling shortcut, Sync Audit log launcher.
* **Connected Entities:** Full read/write access to `villages`, `claims`, `gram_sabha_meetings`, `notices`, and `sync_audit_log`.
* **Next Destinations:** -> **Gram Sabha Dashboard** (`/gram-sabha-dashboard`), -> **Oversight Dashboard** (`/gram-sabha/oversight`), -> **Member Enrollment** (`/gram-sabha/member-enrolment`), -> **Create Meeting** (`/gram-sabha/create`).

#### 6. Village Summary & FRA Dashboard (`/village-dashboard`)
* **Purpose:** Macro-level community overview displaying the cumulative forest land rights secured by the village.
* **Theme & UI Style:** Infographics-driven interface featuring pie charts and progress rings representing approved vs. pending hectares under Section 3(1).
* **Connected Entities:** Aggregates queries from `claims` collection filtered by `villageId`.

---

### III. Module A: AI-Assisted FRA Claims Management

#### 7. My Claims Tracking Screen (`/claims/my`)
* **Purpose:** Allows citizens to track the real-time FRC/SDLC/DLC pipeline status of their filed forest rights claims.
* **Theme & UI Style:** Timeline step-indicator cards. Approved claims glow in **Success Green (`#1E8E3E`)**, Under Review items show **Warning Amber (`#F2A900`)**, and Rejected claims display **Alert Red (`#D32F2F`)** with an automatic *"Draft Section 6 Appeal"* action button.
* **Connected Entities:** Real-time stream via `userClaimsStreamProvider` reading from `claims` where `claimantUserId == currentUser.uid`.
* **Next Destinations:** -> **Claim Detail / Draft Viewer** (`/claims/draft`), -> **Appeal Draft Generator** (`/claims/appeal`).

#### 8. Claim Type Selection Screen (`/claims/type`)
* **Purpose:** Educates and guides the villager to select the correct legal legal category under FRA 2006.
* **Theme & UI Style:** Three prominent interactive selection cards:
  1. **Individual Forest Rights (IFR) - Form A:** Habitation or agricultural cultivation land up to 4 hectares.
  2. **Community Rights (CR) - Form B:** Nistar rights, grazing, minor forest produce (Tendu leaves, Bamboo, Honey).
  3. **Community Forest Resource (CFR) - Form C:** Right to protect, regenerate, or conserve traditional forest boundaries.
* **Next Destination:** -> **Evidence Checklist Screen** (`/claims/evidence`)

#### 9. Rule 13 Evidence Checklist & Assistant (`/claims/evidence`)
* **Purpose:** Pre-validates mandatory documentation required under Rule 13 of FRA Rules 2008 before opening the full application form.
* **Theme & UI Style:** Check-mark driven checklist interface. Color-coded requirements: Primary evidence (75+ year residence proof / ST certificate, Government census, old FIR/fine receipts) vs. Secondary community witness affidavits.
* **Next Destination:** -> **AI Claim Form & OCR Scanner** (`/claims/form`)

#### 10. AI Claim Formulation Screen (`/claims/form`)
* **Purpose:** Complete digital filling of Form A/B/C with conversational AI speech assistance and OCR evidence digitization.
* **Theme & UI Style:** Step-by-step wizard interface. Integrates an active waveform widget for **Whisper Voice Recording** (villager narrates boundary landmarks in Marathi/Hindi, AI transcribes into structured field boundaries) and **Tesseract OCR camera trigger** to extract dates and surveyor numbers from old paper documents.
* **Connected Entities:** Enqueues `SyncAction.createClaim` item into Hive `syncQueueBox`, writes immediately to local `claimsBox`, and triggers `CloudSyncService().syncPendingItems()` for immediate web/cloud propagation.
* **Next Destination:** -> **Claim Draft Preview** (`/claims/draft`)

#### 11. Claim Draft Preview Screen (`/claims/draft`)
* **Purpose:** Generates an official print-ready PDF preview of the finalized claim complete with GPS coordinates and attached digitial evidentiary fingerprints.
* **Theme & UI Style:** Document print view format with formal government framing, digital verification seals, and an interactive submission CTA.
* **Next Destination:** -> **My Claims Tracking** (`/claims/my`)

#### 12. Rejection Diagnosis & Section 6 Appeal Screen (`/claims/rejection` & `/claims/appeal`)
* **Purpose:** Protects citizens from unjustified bureaucratic rejections by automatically analyzing rejection orders against FRA legal rules and generating an official Section 6 Appeal petition.
* **Theme & UI Style:** **Alert Red** warning header highlighting the statutory **60-Day Appeal Window Countdown Timer**. Side-by-side comparison displaying the administrative rejection reason against automated AI rebuttal clauses and legal precedent precedents.
* **Connected Entities:** Reads rejected `claim` object; updates status and generates appeal notice records in `notices` collection via system auto-triggers.

---

### IV. Module B: Satellite GIS & Forest Boundary Atlas

#### 13. GIS Forest Boundary Viewer (`/map/boundary`)
* **Purpose:** Interactive geospatial mapper rendering Community Forest Resource (CFR) boundaries, individual farm plots, and satellite monitoring overlays.
* **Theme & UI Style:** Full-screen rendering of **OpenStreetMap offline vector tiles** layered with custom geometric polygons representing forest boundaries. Includes toggleable layer switches for:
  * 🟢 Approved Land Boundaries (Green Polygon Outlines)
  * 🟠 Pending IFR Claim Polygons (Saffron Dashed Lines)
  * 🛰️ Sentinel-2 NDVI Foliage Loss Overlay (Heatmap intensity)
* **Connected Entities:** Reads boundary polygon geocode arrays from `claims` and `villages` collections.
* **Next Destinations:** -> **Alert Detail Screen** (`/map/alert`), -> **Alert History** (`/map/alerts`).

#### 14. Satellite Alert Detail Screen (`/map/alert`)
* **Purpose:** Investigates automated satellite anomalies (deforestation triggers, illicit encroachment, or forest fires) detected via Sentinel-2 NDVI spectral changes.
* **Theme & UI Style:** Danger/Warning tier indicator header:
  * **Tier 1 (Red Callout):** Active clear-cutting / rapid deforestation within CFR perimeter.
  * **Tier 2 (Amber Callout):** Minor vegetation degradation or possible seasonal drought.
* Displays side-by-side temporal slider (Before vs. After satellite snapshot capture).
* **Connected Entities:** Reads/updates documents in `boundary_alerts` collection (`tier`, `detectedAt`, `resolvedAt`).

#### 15. Alert History Log (`/map/alerts`)
* **Purpose:** Chronological register of all ecological boundary anomalies and their resolution status by the FRC.
* **Theme & UI Style:** Filterable list cards sorted by detection date and severity rating.
* **Connected Entities:** Stream from `boundary_alerts` ordered by `detectedAt DESC`.

---

### V. Module C: Digital Gram Sabha, Quorum Enforcement & Tamper-Evident Ledger

#### 16. Gram Sabha FRC Command Hub (`/gram-sabha-dashboard` & `/gram-sabha`)
* **Purpose:** Primary management portal for conducting official meetings under PESA Act and Section 4 of FRA Rules.
* **Theme & UI Style:** Split navigation tiles: Meeting Schedule Scheduler, Facial Biometric Registry, Attendance Live Ticker, and Cryptographic Minute Book (Ledger).
* **Next Destinations:** -> **Upcoming Meetings** (`/gram-sabha/upcoming`), -> **Member Enrollment** (`/gram-sabha/member-enrolment`), -> **Resolution Ledger** (`/gram-sabha/ledger`), -> **Chain Verification** (`/gram-sabha/verify-chain`).

#### 17. Member Facial Biometric Enrollment (`/gram-sabha/member-enrolment`)
* **Purpose:** Registers adult Gram Sabha members into an offline-first biometric database without compromising citizen privacy.
* **Theme & UI Style:** Camera viewfinder overlay featuring face alignment guide ring. Once face is mapped, shows a **Face Verified Purple (`#512DA8`)** success banner.
* **Privacy & Data Security:** **Never stores or transmits raw photo files.** Converts facial capture locally via PyTorch/TFLite into a mathematical **128-dimension floating-point vector (`List<double>`)** stored inside `gram_sabha_face_enrollments` collection and `membersBox` in Hive.
* **Connected Entities:** Reads/writes `village_members` (stripping embedding payload) and writes vectors solely to `gram_sabha_face_enrollments`.

#### 18. Upcoming Meetings & Meeting Detail (`/gram-sabha/upcoming` & `/gram-sabha/meeting`)
* **Purpose:** Lists scheduled Gram Sabha sessions with meeting venue GPS parameters and agenda items.
* **Theme & UI Style:** Agenda timeline list. Meetings currently in progress flash an interactive *"Open Check-in / Live Quorum"* Saffron badge. Admin users gain access to the "Create Meeting" (`/gram-sabha/create`) modal.
* **Connected Entities:** Streams from `gram_sabha_meetings` ordered by `scheduledDate DESC`.
* **Next Destinations:** -> **Self Check-in / Biometric Attendance** (`/gram-sabha/checkin`), -> **Live Quorum Monitor** (`/gram-sabha/quorum`).

#### 19. GPS & Facial Recognition Check-in (`/gram-sabha/checkin` & `/gram-sabha/log`)
* **Purpose:** Prevents ghost attendance and forged registers by cryptographically verifying member physical presence at the Gram Sabha meeting.
* **Theme & UI Style:** Dual-factor verification display:
  * **Step 1: Geofence Validation Check (`#1976D2` Blue):** Verifies mobile GPS coordinates are within 500 meters of the scheduled meeting venue latitude/longitude.
  * **Step 2: Liveness Facial Match (`#512DA8` Purple):** Compares live webcam match against the stored 128-dim vector (cosine distance threshold < 0.65).
* **Connected Entities:** Generates immutable record in `attendance_records` with ID structure `ATT_{meetingId}_{memberId}` (idempotent design to prevent duplicate voting).

#### 20. Live Rule 4 Quorum & Inclusion Monitor (`/gram-sabha/quorum` & `/gram-sabha/inclusion`)
* **Purpose:** Strictly enforces **Rule 4 of FRA Amendment Rules 2012** which voids any Gram Sabha resolution if mandatory quorum thresholds are bypassed.
* **Theme & UI Style:** Real-time animated KPI gauge meters and stacked progress bars with exact demographic color coding:
  * **Overall Quorum Meter (Success Green):** Requires **≥ 50%** of total registered adult village members checked in.
  * **Women Quorum Meter (Women Purple `#7B1FA2`):** Statutorily mandates that **≥ 33% (One-Third)** of all attendees MUST be women. If under 33%, system locks resolution generation with a **Warning Amber / Red** notice.
  * **ST & PVTG Representation (Cyan `#00838F` / Orange `#E65100`):** Displays real-time participation counts of Scheduled Tribes and Particularly Vulnerable Tribal Groups.
* **Connected Entities:** Evaluates aggregated counts from `attendance_records` against total counts in `village_members`.
* **Next Destination:** -> **AI Resolution Recording** (`/gram-sabha/resolution-recording`) *(Unlocked only when Quorum status == Valid)*.

#### 21. AI Speech-to-Text Resolution Recorder (`/gram-sabha/resolution-recording` & `/gram-sabha/resolution/create`)
* **Purpose:** Captures spoken Gram Sabha debate and decision proceedings, converting spoken vernacular dialects into formatted legal Minutes of Meeting (MoM) and land resolutions.
* **Theme & UI Style:** Large circular recording control desk with real-time speech waveform display. Shows side-by-side automatic transcription: **Spoken Marathi/Hindi (Source)** on left $\rightarrow$ **Standardized FRA English Legal Formatting** on right.
* **Connected Entities:** Creates draft entry for MoM publication in `gram_sabha_mom_records` and individual decision entries in `resolutions`.

#### 22. Cryptographic Tamper-Evident Ledger & MoM Viewer (`/gram-sabha/ledger`, `/gram-sabha/mom-viewer`, & `/gram-sabha/verify-chain`)
* **Purpose:** Guarantees absolute transparency and immutability of Gram Sabha land grants using a decentralized **SHA-256 Hash Chain** (Blockchain-style immutable linked list).
* **Theme & UI Style:** Digital Ledger ledger formatting. Each passed resolution card displays its cryptographic block identity:
  * **Block Index ($N$)**
  * **Timestamp ($t_n$)**
  * **Previous Block Hash ($H_{n-1}$)**: Hexadecimal string linking to the immediately preceding village meeting resolution.
  * **Current Block Hash ($H_n = \text{SHA256}(H_{n-1} \parallel \text{CanonicalJSON}(Data) \parallel t_n)$)**
* Includes a large **"Run Cryptographic Audit / Verify Chain Integrity"** button.
  * When intact: Screens glows with **Success Green Banner (`Chain Verified: zero tampering detected across all blocks`)**.
  * If tampered (e.g., historical record illegally edited by an external database breach): Screen alerts in **Alert Red (`INTEGRITY FAILURE: Block #4 hash mismatch detected!`)**.
* **Connected Entities:** Uses `FirestoreService().verifyMomChain(villageId)` and `HashChainService` to validate `gram_sabha_mom_records` and `resolutions` collections.

---

### VI. Legal Empowerment Hub & Profile System

#### 23. Legal Rights Reference Hub (`/legal/fra`, `/legal/rule4`, `/legal/rule13`, `/legal/pesa`)
* **Purpose:** Educates villagers about their statutory protections in simplified, easy-to-understand vernacular breakdowns with pictorial aides and audio read-aloud functionality.
* **Theme & UI Style:** Accordion expansion cards with large readability typography and bookmarking tools.
  * **FRA 2006 Overview:** Rights to land ownership, bamboo grazing, and habitat preservation.
  * **Rule 4 Explained:** Why Sarpanches cannot force meetings without 33% women participation.
  * **Rule 13 Evidence Manual:** What to do if forest officials demand non-statutory documents.
  * **PESA Act 1996:** Tribal self-governance rules in Fifth Schedule areas.

#### 24. Profile & Cloud Sync Governance (`/profile` & `/settings`)
* **Purpose:** Displays user credentials, FRC affiliation status, and offline/online database synchronization diagnostics.
* **Theme & UI Style:** Settings list interface with an integrated **Sync Audit Health Card**.
* **Key Components:**
  * **Manual Sync Push Button:** Forces immediate upload of any offline Hive items waiting in `syncQueueBox` to Firestore.
  * **Sync Audit Log Console:** Lists timestamps and HTTP status outcomes of previous sync operations from `sync_audit_log`.
  * **Language Switcher:** Toggle app interface language instantaneously without data reload.
* **Connected Entities:** Reads `users/{uid}`, configures `HiveDatabase.settingsBox`, monitors `CloudSyncService` worker threads.

---

## 4. End-to-End Core Workflows (Sequence & Navigation Matrix)

### Workflow A: New Forest Land Claim Processing & Submission (Offline-First)
```
1. Citizen opens application in deep forest (No 4G/5G Connectivity).
2. Navigates: Villager Home (/villager-home) ──> Apply for FRA Claim (/claims/type).
3. Selects "Individual Forest Rights (IFR)" ──> Completes Rule 13 Checklist (/claims/evidence).
4. Enters AI Claim Form (/claims/form):
   • Records spoken Marathi narration of boundary landmarks via Whisper UI.
   • Snaps photo of 1998 gram panchayat electricity receipt via OCR Scanner.
   • Saves Claim.
5. System Action: Claim stored in local Hive DB (claimsBox) + queued in (syncQueueBox) with status [PENDING].
6. Citizen travels to taluka market or village Gram Panchayat WIFI zone (Internet restored).
7. System Action: App Startup / CloudSyncService fires immediately ──> Pushes item to Firestore (claims collection).
8. Citizen verifies approved green badge on My Claims Dashboard (/claims/my).
```

### Workflow B: Digital Gram Sabha Quorum & Cryptographic Resolution Passing
```
1. FRC Admin schedules meeting via Admin Home (/admin-home) ──> Create Meeting (/gram-sabha/create).
2. On Meeting Day: Citizens assemble at village school grounds.
3. Attendees open Self Check-in (/gram-sabha/checkin):
   • GPS verifies presence within 500m geofence radius.
   • Camera authenticates facial embedding vector (128-dim match).
4. Admin monitors Live Quorum Screen (/gram-sabha/quorum):
   • Total check-ins hit 54% (Overall Quorum Met 🟢).
   • Women check-ins hit 38% (Rule 4 Women Quorum Met 🟣).
   • System UNLOCKS Resolution Recorder.
5. Sabha debates and approves 14 pending forest land claims.
6. Admin records spoken consensus in AI Resolution Recorder (/gram-sabha/resolution-recording).
7. System Action: Generates SHA-256 cryptographically chained Block #15 linking to Block #14.
8. Written to gram_sabha_mom_records & resolutions in Firestore with immutable server timestamps.
```

---

## 5. Summary of Database Mapping Across Screens

Every screen in the above architecture is explicitly mapped to one or more of the **12 Canonical Firestore Collections** verified in `firestore.rules` and `firestore.indexes.json`:

| Collection Name | Primary Screens / Routes Interacting With It | Access Model |
| :--- | :--- | :--- |
| `users` | Registration (`/registration`), Profile (`/profile`), All Homes | Read / Write via Auth UID |
| `villages` | Village Dashboard (`/village-dashboard`), Registration | Read / Admin Upsert |
| `village_members` | Member Enrolment (`/gram-sabha/member-enrolment`), Quorum Monitor | Bulk Seed & Read |
| `gram_sabha_meetings` | Upcoming Meetings (`/gram-sabha/upcoming`), Meeting Detail | Real-time Stream & Queue Sync |
| `attendance_records` | Check-in (`/gram-sabha/checkin`), Attendance Log (`/gram-sabha/log`) | Idempotent Create & Aggregate |
| `claims` | My Claims (`/claims/my`), AI Claim Form (`/claims/form`), Admin Track | User/Village Streams & Queue Sync |
| `resolutions` | Resolution Ledger (`/gram-sabha/ledger`), Resolution Recorder | Immutable Append-Only Ledger |
| `gram_sabha_mom_records`| MoM Viewer (`/gram-sabha/mom-viewer`), Chain Verify (`/verify-chain`)| SHA-256 Chained Immutable Storage |
| `gram_sabha_face_enrollments` | Member Facial Biometric Enrolment, Check-in verification | 128-dim Vector Map Storage |
| `notices` | Notice Ticker (All Dashboards), Admin Broadcast Hub | Global Stream & Admin Create |
| `boundary_alerts` | GIS Map (`/map/boundary`), Alert Detail (`/map/alert`), Alert History| Stream filtered by Village/Tier |
| `sync_audit_log` | Sync Audit Console, Cloud Sync diagnostics in Settings | Worker Auto-Append Logging |

---
*Document Version: 2.0.0 (Verified against live Firebase project `vanmitra-ai` and Flutter web Chrome engine).*
