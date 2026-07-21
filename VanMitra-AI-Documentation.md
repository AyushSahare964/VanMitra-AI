# VanMitra-AI — वन मित्र AI

**Team:** Gangs Of Kondhwa | **Track:** AI for Societal Good | **Pilot Village:** Ozhar, Jawhar Taluka, Palghar District, Maharashtra

**Team Members:** Sanskruti Ruyarkar, Ayush Sahare, Piyush Dhane, Samrudhhi Shinde

---

## 1. Problem Statement

Tribal and forest-dwelling communities face major hurdles securing land rights under the **Forest Rights Act (FRA) 2006**:
- Complex, ambiguous documentation requirements (Rule 13) cause frequent, poorly-explained claim rejections.
- Gram Sabha (village council) meeting quorums and consent resolutions are often manipulated or backdated to enable illegal land diversion.
- Communities lack tools to monitor their forest boundaries for encroachment once rights are granted.
- Existing government portals are online-only, unavailable in Indic languages, and offer no tamper-proofing for records — unusable in low-connectivity rural areas.

**Beneficiaries:** tribal claimants (individual & community), Gram Sabha Secretaries/Forest Rights Committees, and oversight NGOs/District Officers.

---

## 2. Solution Overview

VanMitra-AI is an **offline-first governance app** (Flutter + Python FastAPI, Hive local DB, Firebase sync) with three modules:
- **Module A — AI Legal Assistant:** OCR + RAG-based pipeline that scores evidence, drafts FRA claim forms, and generates appeal drafts for rejected claims.
- **Module B — Satellite Digital Fencing:** Offline maps of forest boundaries with satellite-based encroachment/deforestation alerts.
- **Module C — Gram Sabha Integrity Ledger:** Digitises meetings with GPS geofencing, on-device face recognition for attendance, automated quorum checks, trilingual resolution recording, and a SHA-256 tamper-proof ledger.

---

## 3. Application Workflow / Routing

```
Launch → Language Selection → Registration/Login (Villager or Admin role)
   → Villager: Claims Portal, Notice Board, CFR Boundary Map
   → Admin: Gram Sabha Dashboard, Meetings, Member Enrolment, Cloud Sync
```
The app has 22 screens across five feature areas (onboarding, claims, appeals, meetings/ledger, and admin tools), backed by 8 FastAPI endpoints for eligibility checks, document verification, draft generation, transcription, and appeal drafting. All data is written locally first (14 offline data stores) and synced to Firebase once connectivity returns.

---

## 4. Key Use Cases

| Use Case | Actor | Outcome |
|---|---|---|
| File an FRA Claim | Villager | AI-scored, legally-grounded claim draft in the local language |
| Appeal a Rejected Claim | Villager | Auto-generated appeal citing procedural defects, with deadline countdown |
| Conduct a Gram Sabha Meeting | Secretary | Real-time, GPS/face-verified attendance and quorum tracking |
| Record a Resolution | Secretary | Trilingual, hash-chained meeting minutes |
| Verify Ledger Integrity | Any user/NGO | Tamper detection across the full meeting record chain |
| Monitor Forest Boundary | Community | Encroachment/deforestation alerts on an offline map |
| Enrol Members | Secretary | Face-verified attendance enabled for future meetings (no raw photos stored) |

---

## 5. Features & Functionality

- Evidence Completeness Score for FRA claims, with a transparent, tiered readiness indicator
- AI pipeline for claim drafting, document verification, and appeal generation
- Tamper-proof SHA-256 hash-chained meeting ledger with full-chain verification
- On-device face recognition for attendance (privacy-preserving — embeddings only, no stored photos)
- GPS geofencing and automated quorum validation per FRA rules
- Minutes-of-Meeting assembly with PDF export in local scripts
- On-device speech-to-text and trilingual translation for resolutions
- Four-language localisation (English, Hindi, Marathi, Konkani)
- Offline-first sync queue with automatic retry once online
- Admin notice board for village-wide announcements

---

## 6. How It Works

1. **Setup:** Choose a language, register with name/phone/role (Villager or Secretary/Admin).
2. **Filing a Claim:** Select claim type, enter land details, upload evidence — the app scores completeness live and generates a legal draft for review and submission.
3. **Appealing a Rejection:** Photograph the rejection order; the app analyses it and drafts an appeal with a countdown to the filing deadline.
4. **Conducting a Meeting:** Create a GPS-tagged meeting, verify attendance via geofence and face match (or manual override), track quorum live, record and translate resolutions, then hash them into the ledger and export the minutes as a PDF.
5. **Verifying Integrity:** Anyone can re-verify the full meeting ledger to confirm no record has been altered.

---

## 7. Assumptions, Limitations & Future Improvements

**Assumptions:** Secretaries have access to a mid-range Android device with GPS/camera; baseline village registration data is available during onboarding; lighting is adequate for face enrolment.

**Limitations:** OCR accuracy drops on poor-quality documents; AI drafting and voice transcription need connectivity (falls back to offline templates); face recognition has edge cases in poor lighting (manual override available); Konkani language support is less complete; not yet tested beyond a single-village pilot.

**Future Improvements:** fully on-device voice transcription; satellite pipeline integration for automated encroachment detection; GPS-based boundary mapping; an NGO verification portal; SMS-based sync for zero-connectivity areas; additional tribal language support; automated testing and deployment pipeline.

---

## 8. Repository

**GitHub:** [github.com/AyushSahare964/VanMitra-AI](https://github.com/AyushSahare964/VanMitra-AI)

```bash
git clone https://github.com/AyushSahare964/VanMitra-AI.git
```
