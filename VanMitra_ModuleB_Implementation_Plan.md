# VanMitra-AI — Module B (Digital Fencing) Implementation Plan
### Wiring the Ozar Siamese Change-Detection Model into the Live App

**Sources reconciled by this plan:**
- `SATELLITE_MODEL_INTEGRATION.md` — backend/API integration spec for a satellite `SatelliteAgent`
- `VanMitra_AI_Screen_Flow_and_UI_Architecture.md` — the live app's screen inventory & Firestore schema (v2.0.0)
- `VanMitra_ModuleB_Ozar.ipynb` — the trained pipeline (Siamese CNN, NDVI/ΔNDVI, risk tiering) and its outputs:
  `siamese_change_model.pt`, `satellite_config.json`, `ozar_alerts.csv`

**What this plan resolves:** the two source specs describe *slightly different* things — the integration
spec assumes a fresh `/api/v1/satellite-verify` endpoint and a generic `Evidence` object; the live app
already has a Module B (screens #13–#15, collection `boundary_alerts`) built around **per-parcel tiered
alerts**, which is exactly what the notebook produces. This plan makes the notebook's trained model the
engine behind the **existing** `boundary_alerts` screens, rather than bolting on a parallel system.

---

## 1. Scope & Fit

```
                         ┌─────────────────────────────┐
   VanMitra_ModuleB_     │  vanmitra_backend/ (FastAPI) │
   Ozar.ipynb  ──trains──▶  SatelliteAgent               │
   (Colab)                │   ├─ loads siamese_change_   │
                          │   │   model.pt (Section 2)   │
                          │   ├─ reads satellite_config   │
                          │   │   .json (Section 2)      │
                          │   └─ writes → boundary_alerts │
                          └───────────────┬───────────────┘
                                          │ Firestore stream
                                          ▼
                          ┌─────────────────────────────┐
                          │  Flutter App (vanmitra_tem/) │
                          │   #13 GIS Boundary Viewer     │
                          │   #14 Satellite Alert Detail  │
                          │   #15 Alert History Log       │
                          │   + parcel status on          │
                          │     Villager Home / My Claims │
                          └─────────────────────────────┘
```

- **OrchestratorAgent** wiring (`self.satellite = SatelliteAgent()`), request/response envelope, error
  codes, and Docker/GDAL changes are carried over **unchanged** from `SATELLITE_MODEL_INTEGRATION.md`
  Sections 3, 9–11 — not repeated in full here, only the deltas below.
- The **evidence category / weight** contract (`government_records`, weight `0.30` in
  `evidence_weights.json`, feeding `ScoringAgent`) is also carried over unchanged.
- What changes: `_run_analysis()` now runs the *actual trained model* instead of a stub, the response
  schema is extended with the notebook's per-parcel fields, and results land in `boundary_alerts` (the
  collection the UI already reads) instead of only being returned inline.

---

## 2. Model Integration Specification (Backend)

### 2.1 Artifacts to ship

| File | From | Destination in `vanmitra_backend/` |
|---|---|---|
| `siamese_change_model.pt` | Notebook Cell 22 | `assets/ai_config/siamese_change_model.pt` |
| `satellite_config.json` | Notebook Cell 22 | `assets/ai_config/satellite_config.json` |
| `ozar_alerts.csv` | Notebook Cell 21 | `assets/seed_data/ozar_alerts.csv` (one-time seed only — see §4.3) |

`satellite_config.json` (as generated) is the single source of truth for thresholds — the backend must
**read these values at startup**, not hard-code the defaults from `SATELLITE_MODEL_INTEGRATION.md`
Section 8's `satellite_config.json` sample, since the trained run's thresholds are authoritative:

```json
{
  "ndvi_thresholds": { "theta_change_candidate": 0.18, "siamese_decision_tau": 0.5 },
  "cluster_thresholds": { "a_min_pixels": 4, "pixel_area_sqm": 100.0 },
  "resolution_feasibility_bands": { "reliable_min_sqm": 900.0, "marginal_min_sqm": 400.0 },
  "land_use_rule": { "domestic_area_threshold_sqm": 1000.0 },
  "area_discrepancy_tolerance_pct": 15.0,
  "model": { "file": "siamese_change_model.pt", "n_params": 6002, "patch_size": 20 },
  "village_boundary_source": "FALLBACK",
  "earth_engine_imagery_used": false
}
```

> `village_boundary_source: "FALLBACK"` and `earth_engine_imagery_used: false` are run-provenance flags,
> not thresholds — surface them as a **"demo data" badge** in the UI (§3.2) rather than silently trusting
> the alert as field-verified. This mirrors the notebook's Cell 21 limitations block.

### 2.2 `requirements.txt`

Same additions as `SATELLITE_MODEL_INTEGRATION.md` §"Python Requirements", **plus** `torch>=2.2.0` and
`scikit-image` is already listed there — the notebook's `SiameseChangeNet` is a PyTorch `nn.Module`, so
`torch` (CPU build is fine; the model is 6,002 params) must be added explicitly:

```diff
 rasterio>=1.3.9
 shapely>=2.0.0
 pyproj>=3.6.0
 scikit-learn>=1.4.0
 scikit-image>=0.22.0
 opencv-python-headless>=4.9.0
 requests>=2.31.0
+torch>=2.2.0
```

### 2.3 `SatelliteAgent._run_analysis()` — real implementation

Replaces the `NotImplementedError` stub in `SATELLITE_MODEL_INTEGRATION.md` §"Satellite Agent — Python
Interface":

```python
import json, torch
from pathlib import Path

AI_CONFIG_DIR = Path(__file__).resolve().parent.parent / "assets" / "ai_config"

class SatelliteAgent:
    def __init__(self):
        cfg = json.loads((AI_CONFIG_DIR / "satellite_config.json").read_text())
        self.theta = cfg["ndvi_thresholds"]["theta_change_candidate"]
        self.tau = cfg["ndvi_thresholds"]["siamese_decision_tau"]
        self.a_min_pixels = cfg["cluster_thresholds"]["a_min_pixels"]
        self.pixel_area_sqm = cfg["cluster_thresholds"]["pixel_area_sqm"]
        self.reliable_min_sqm = cfg["resolution_feasibility_bands"]["reliable_min_sqm"]
        self.marginal_min_sqm = cfg["resolution_feasibility_bands"]["marginal_min_sqm"]
        self.patch_size = cfg["model"]["patch_size"]

        ckpt = torch.load(AI_CONFIG_DIR / cfg["model"]["file"], map_location="cpu")
        self.model = SiameseChangeNet(**ckpt["architecture"])
        self.model.load_state_dict(ckpt["state_dict"])
        self.model.eval()

    def _run_analysis(self, lat, lng, radius, image_bytes):
        # 1. Acquire T1/T2 NIR+RED patches for (lat, lng, radius):
        #      EE_AVAILABLE (prod)  → Sentinel-2 SR via Earth Engine, cloud-masked (notebook Cell 13)
        #      no EE / no imagery   → COORDS reverse-checked against village boundary only; return
        #                             error_code = "NO_DATA_FOR_DATE" rather than fabricating a result
        # 2. Pad both patches to (2, patch_size, patch_size) exactly as notebook Cell 16 pad_to_size()
        # 3. p_change, e1, e2, d = self.model(x1_tensor, x2_tensor)
        # 4. ndvi_mean = compute_ndvi(...).mean()  (notebook Cell 14 compute_ndvi)
        # 5. canopy_pct = derived from land-cover pixel classification (unchanged from Cell 7/9 logic)
        # 6. land_class from the same classify_land_use()-style rule, not a separate model
        raise NotImplementedError("Wire Sentinel-2/EE acquisition — model + thresholds are ready above")

    def _verdict(self, ndvi, canopy, p_change):
        # Combine the Siamese decision (p_change > self.tau) with the NDVI/canopy rule from
        # SATELLITE_MODEL_INTEGRATION.md so a single low signal alone can't force "rejected":
        if p_change <= self.tau and ndvi >= self.theta:
            return "auto_verified"
        elif p_change <= self.tau or ndvi >= self.theta * 0.6:
            return "needs_review"
        return "rejected"
```

`_run_analysis`'s TODO is intentionally left open here: the notebook's Cell 12–13 pipeline (Earth Engine
auth → per-parcel Sentinel-2 acquisition → cloud masking) is Colab-interactive (`ee.Authenticate()`) and
needs a **service-account** flow for a headless backend — that swap is the one piece of real engineering
work left; everything else (model, thresholds, tiering, evidence mapping) is ready to paste in.

### 2.4 Two call patterns, not one

`SATELLITE_MODEL_INTEGRATION.md` only specifies the on-demand `POST /api/v1/satellite-verify` endpoint
(one villager, one parcel, on request — used from the claim-evidence flow, §3.1 below). The notebook's
actual output (`ozar_alerts.csv`, 147 rows, one per parcel) is a **batch job**, matching what screens
#13–#15 already expect (`boundary_alerts` streamed by village). Add a second entry point:

```python
@app.post("/api/v1/satellite-monitor/run")
async def run_village_monitor(village_id: str = Form(...)):
    """
    Weekly scheduled job (Section 11 of SATELLITE_MODEL_INTEGRATION.md's deployment hand-off).
    Runs SatelliteAgent.analyze() over every parcel with boundary_status in (drawn, locked) for
    village_id, exactly as notebook Cell 19's per-parcel loop — never aggregates across parcels —
    and upserts one boundary_alerts/{alertId} document per parcel. Returns a run summary, not the
    per-parcel payloads (those are read back from Firestore by the app).
    """
```

| Endpoint | Trigger | Consumer |
|---|---|---|
| `POST /api/v1/satellite-verify` | On-demand, one parcel, from claim evidence flow | `/claims/evidence`, `/claims/form` |
| `POST /api/v1/satellite-monitor/run` | Scheduled (weekly) or admin-triggered, whole village | Screens #13–#15 via `boundary_alerts` |
| `GET /api/v1/satellite-verify/status/{task_id}` | Poll heavy GeoTIFF jobs | Both (unchanged from integration spec) |

---

## 3. Screen Specifications

Screens #13–#15 already exist in the live app; below are the concrete field-level deltas needed to
surface everything the trained model now produces. New screens are marked **NEW**.

### 3.1 GIS Forest Boundary Viewer (`/map/boundary`) — extended

* **Add layer toggle:** 🔵🟡🔴 **Parcel Risk Tier** (from `boundary_alerts.tier`), independent of the
  existing 🟢 Approved / 🟠 Pending claim-polygon toggles — a parcel can be an *approved* claim and still
  carry a *red* satellite alert.
* **Add per-parcel tap card** (bottom sheet, not a new route): `land_use_type`, `resolution_feasibility`
  badge (`reliable` / `marginal` / `unreliable` — Amber badge for the latter two, since accuracy is lower
  there), and a **"View Alert Detail →"** action into #14 when `tier != green`.
* **Data provenance strip:** small grey text under the layer legend — *"Boundary source:
  {village_boundary_source} · Imagery: {Sentinel-2 (Earth Engine) | Synthetic demo}"* sourced from
  `satellite_config.json`'s provenance flags (§2.1) so field staff never mistake a demo run for a
  verified survey.
* **Connected Entities (updated):** adds `boundary_alerts` (existing collection, now populated by
  `SatelliteAgent` instead of manually) to the boundary polygon read already listed.

### 3.2 Satellite Alert Detail Screen (`/map/alert`) — extended

Current spec only has `tier`, `detectedAt`, `resolvedAt`. Extend the document read to surface the full
notebook output, mapped 1:1 to `boundary_alerts` fields (see §4.1 for the field list):

* **Header:** unchanged Tier 1 (Red) / Tier 2 (Amber) callout, now also rendering 🟢 Green ("No change
  detected") as a neutral confirmation state rather than only showing alerts — closes the current gap
  where a *clean* parcel has no screen at all.
* **New card — Change Summary:** `area_affected_sqm`, `likely_cause` (`Illegal Clearing / Logging` /
  `Possible Seasonal Variation` / rule-based v1, labelled as such — not presented as a validated
  classifier, per notebook Cell 17/21 limitations), `detected_date`.
* **New card — Reliability:** `resolution_feasibility` band with a one-line plain-language explainer
  ("This parcel is small relative to the satellite's 10m pixel grid — treat this alert as indicative,
  confirm on a field visit" for `marginal`/`unreliable`).
* **Existing temporal slider** (before/after) stays, now backed by the T1/T2 acquisition dates from
  `change_detection.baseline_date` / `current_date` (integration spec §"Response Schema") instead of
  placeholder imagery.
* **Connected Entities:** `boundary_alerts` document read/update — unchanged collection, extended fields
  only (no schema-breaking rename).

### 3.3 Alert History Log (`/map/alerts`) — extended

* **Add filters:** by `tier` (existing), plus new `likely_cause` and `resolution_feasibility` filter
  chips, so an FRC admin can e.g. surface only `reliable`-band `red`-tier alerts (highest-confidence
  action items) first.
* **List card:** show `Claimant_Name` + `Survey_No` (present in `ozar_alerts.csv`, absent from the
  current card spec) so the admin doesn't have to open the detail screen to identify whose parcel it is.

### 3.4 Villager-facing parcel status card — **NEW**, embedded (not a new route)

The current architecture has no villager-facing view of their *own* parcel's satellite status — #13–#15
read as admin/FRC tooling. Add a compact status card to the **existing** Villager Home (`/villager-home`)
and My Claims (`/claims/my`) screens, not a new screen, to avoid growing the navigation map:

* **Placement:** below the claim's timeline step-indicator on `/claims/my`, only when that claim's
  `landowner_id` has a matching `boundary_alerts` document.
* **Content:** single-line status — 🟢/🟡/🔴 dot + `likely_cause` in plain vernacular text + "Last
  checked: {detected_date}" — tapping opens #14 (`/map/alert`) filtered to that parcel.
* **Why not a new route:** this is a read-only reflection of data the admin-facing screens already own;
  a dedicated route would duplicate #14 without adding capability.
* **Connected Entities:** reads `boundary_alerts` filtered by the current user's `landowner_id` / claim
  ID — no new collection.

### 3.5 Sync/model provenance badge on Profile & Settings (`/profile` & `/settings`) — extended

* Add one row to the existing **Sync Audit Health Card**: **"Satellite model: v{model file hash / date}
  · {n_params} params · last village run {timestamp}"**, sourced from `satellite_config.json` metadata
  written alongside each `satellite-monitor/run` execution. This gives FRC admins visibility into which
  model version produced the alerts they're acting on — important given the model is explicitly a "demo
  training run" (notebook Cell 16) that will be retrained on real FFC data later.

---

## 4. Datastore

### 4.1 `boundary_alerts` — field-level schema (extends the existing collection, no rename/migration)

The live schema doc only names the collection and says it's "filtered by Village/Tier." This plan pins
down the concrete fields, taken directly from the notebook's actual output shape (`ozar_alerts.csv`) plus
the confidence fields from the integration spec's response schema:

| Field | Type | Source | Notes |
|---|---|---|---|
| `alertId` | `string` (doc ID) | generated | `ALT_{villageId}_{landownerId}` — idempotent, mirrors `attendance_records`' `ATT_{...}` convention already used elsewhere in the app |
| `villageId` | `string` | context | partition key for the village-scoped stream #13–#15 already rely on |
| `landownerId` | `int` | `ozar_alerts.csv: landowner_id` | joins to the parcel/claim |
| `claimantName` | `string` | `ozar_alerts.csv: Claimant_Name` | shown in #14 header, #15 card (§3.3) |
| `surveyNo` | `int` | `ozar_alerts.csv: Survey_No` | shown in #15 card (§3.3) |
| `declaredAreaSqm` | `number` | `ozar_alerts.csv: declared_area_sqm` | |
| `landUseType` | `string` (`"Domestic/Homestead"` \| `"Agricultural/Farmland"`) | `ozar_alerts.csv: land_use_type` | drives the layer toggle in §3.1 |
| `resolutionFeasibility` | `string` (`reliable` \| `marginal` \| `unreliable`) | `ozar_alerts.csv: resolution_feasibility` | Reliability card, §3.2 |
| `areaAffectedSqm` | `number` | `ozar_alerts.csv: area_affected_sqm` | Change Summary card, §3.2 |
| `tier` | `string` (`green` \| `yellow` \| `red`) | `ozar_alerts.csv: tier` | already named in the live schema |
| `likelyCause` | `string` | `ozar_alerts.csv: likely_cause` | labelled "rule-based v1" in UI copy, §3.2 |
| `detectedAt` | `timestamp` | `ozar_alerts.csv: detected_date` | already named in the live schema |
| `resolvedAt` | `timestamp \| null` | admin action | already named in the live schema; unchanged |
| `confidence` | `number (0–1)` | `SatelliteAgent` verdict | from integration spec's `verification_verdict.confidence` |
| `ndviMean` | `number (-1–1)` | `SatelliteAgent` verdict | from integration spec's `ndvi.mean` |
| `modelVersion` | `string` | `satellite_config.json` metadata | drives §3.5's provenance badge |
| `boundarySource` | `string` (`OSM` \| `FALLBACK`) | `satellite_config.json.village_boundary_source` | drives §3.1's provenance strip |
| `imagerySource` | `string` (`sentinel2_ee` \| `synthetic`) | `satellite_config.json.earth_engine_imagery_used` | drives §3.1's provenance strip |

### 4.2 Offline Hive mirror

Following the same offline-first pattern already used for `claimsBox` / `syncQueueBox`:

* **`boundaryAlertsBox`** — read-only local cache of the villager's own parcel's `boundary_alerts`
  documents (§3.4's card needs to render without connectivity, same as every other villager-facing
  status indicator in the app).
* No `syncQueueBox` entry is needed for this collection — alerts are backend-generated (via
  `satellite-monitor/run`), not villager-authored, so there's nothing to queue *outbound*; only the
  inbound cache above is needed.

### 4.3 Seed data vs. production data

`ozar_alerts.csv` is the **synthetic demo run's** output (`village_boundary_source: FALLBACK`,
`earth_engine_imagery_used: false` — notebook Cell 21's own limitations block). Load it into
`boundary_alerts` **only** in a dev/demo Firebase project, tagged `modelVersion: "demo-v1-synthetic"`, so
it's visually distinguishable (via §3.1's provenance strip) from any future production run against real
Sentinel-2 imagery. Never seed it into the `vanmitra-ai` production project referenced in the live
schema doc's footer.

---

## 5. Rollout Checklist

**Backend**
- [ ] Add `torch>=2.2.0` to `requirements.txt` (§2.2)
- [ ] Copy `siamese_change_model.pt` + `satellite_config.json` into `assets/ai_config/` (§2.1)
- [ ] Implement `SatelliteAgent.__init__` + `_verdict` as in §2.3 (model loading + config-driven
      thresholds)
- [ ] Implement the Earth Engine service-account acquisition path inside `_run_analysis` (§2.3's open
      TODO) — the one net-new engineering task
- [ ] Add `POST /api/v1/satellite-monitor/run` (§2.4) alongside the existing on-demand endpoint
- [ ] Point both endpoints at `boundary_alerts` writes using the field mapping in §4.1
- [ ] Update Dockerfile with GDAL packages (unchanged, `SATELLITE_MODEL_INTEGRATION.md` §"Docker /
      Railway Changes")

**App (Flutter)**
- [ ] `#13` — add Parcel Risk Tier layer toggle + tap card + provenance strip (§3.1)
- [ ] `#14` — extend detail read model with Change Summary + Reliability cards, add green "no change"
      state (§3.2)
- [ ] `#15` — add `likely_cause` / `resolution_feasibility` filter chips + claimant/survey no. on cards
      (§3.3)
- [ ] Villager Home / My Claims — add the parcel status card (§3.4), no new route
- [ ] Profile/Settings — add model provenance row to Sync Audit Health Card (§3.5)

**Data**
- [ ] Extend `boundary_alerts` documents with the fields in §4.1 (additive — no migration of existing
      docs required)
- [ ] Add `boundaryAlertsBox` Hive box + read-only sync (§4.2)
- [ ] Seed `ozar_alerts.csv` into a **dev-only** project with `modelVersion: "demo-v1-synthetic"` (§4.3)

**Carried-over limitations to keep visible in the product (not just this doc)** — per notebook Cell 21 /
Section 13, and now surfaced structurally via §3.1's provenance strip and §3.5's model badge rather than
only in a README:
- Boundary geometry in the demo run is simulated, not operator-traced
- `likely_cause` is a rule-based v1 heuristic, not a validated classifier
- The Siamese model is a lightweight demo training run (6,002 params, synthetic Tier-4 data) — retrain on
  real FFC-derived + augmented data before treating `red`-tier alerts as enforcement-grade
