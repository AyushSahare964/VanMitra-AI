# 🛰️ VanMitra-AI — Satellite Model Integration Specification

> **Module:** Model B — Satellite Land Verification  
> **Integrates with:** VanMitra-AI Model A FastAPI Backend (`vanmitra_backend/`)  
> **Frontend:** Flutter App (`vanmitra_tem/`) + Website (`website/`)  
> **Version:** 1.0.0  
> **Last Updated:** 2026-08-04

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture Fit](#architecture-fit)
3. [Python Requirements](#python-requirements)
4. [New API Endpoints](#new-api-endpoints)
5. [Request & Response Schemas](#request--response-schemas)
6. [Frontend Integration Contract](#frontend-integration-contract)
7. [Satellite Agent — Python Interface](#satellite-agent--python-interface)
8. [File Structure Changes](#file-structure-changes)
9. [Environment Variables](#environment-variables)
10. [Docker / Railway Changes](#docker--railway-changes)
11. [Error Codes Reference](#error-codes-reference)

---

## Overview

The **Satellite Model (Model B)** adds land-parcel verification using satellite/aerial imagery. It accepts:
- A **latitude/longitude** (or bounding box) of the claimed forest land
- An optional **date range** for historical NDVI analysis
- An optional **uploaded satellite image** (GeoTIFF or JPEG)

It returns:
- **Land-cover classification** (forest / agricultural / settlement / water / other)
- **NDVI score** (vegetation health index, -1 to +1)
- **Canopy coverage %**
- **Change detection** (deforestation flag between two dates)
- **Confidence score** (0-1)
- A **verification verdict** that feeds directly into the `ScoringAgent` evidence pipeline

---

## Architecture Fit

```
OrchestratorAgent (existing)
 ├─ IntakeAgent        ✅ existing
 ├─ EligibilityAgent   ✅ existing
 ├─ DocVerifyAgent     ✅ existing
 ├─ ScoringAgent       ✅ existing  ← satellite verdict fed here
 ├─ DraftAgent         ✅ existing
 ├─ RejectionAgent     ✅ existing
 ├─ AppealAgent        ✅ existing
 └─ SatelliteAgent     🆕 NEW  ← add to agents.py + main.py
```

The `SatelliteAgent` returns an `Evidence` object with:
- `category = "government_records"`  (weight 0.30 per `evidence_weights.json`)
- `description = "Satellite-verified forest land"`
- `verification_status = "auto_verified" | "needs_review" | "rejected"`

This plugs directly into the **existing** `ScoringAgent.score()` without any schema changes.

---

## Python Requirements

Add the following to `vanmitra_backend/requirements.txt`:

```diff
 fastapi>=0.110.0
 uvicorn[standard]>=0.27.0
 python-multipart>=0.0.9
 pydantic>=2.5.0
 sentence-transformers>=2.6.0
 faiss-cpu>=1.8.0
 rapidfuzz>=3.8.0
 Pillow>=10.2.0
 pytesseract>=0.3.10
 numpy>=1.26.0

+# ── NEW: Satellite Model B ────────────────────────────────────────────────
+rasterio>=1.3.9
+shapely>=2.0.0
+pyproj>=3.6.0
+scikit-learn>=1.4.0
+scikit-image>=0.22.0
+opencv-python-headless>=4.9.0
+requests>=2.31.0
+# geopandas>=0.14.0        # Uncomment if vector boundary files needed
+# earthengine-api>=0.1.400 # Uncomment if using Google Earth Engine
+# sentinelhub>=3.9.0       # Uncomment if using Sentinel Hub API
```

> [!IMPORTANT]
> `rasterio` requires **GDAL system libraries**. Update the Dockerfile — see the [Docker section](#docker--railway-changes).

---

## New API Endpoints

### `POST /api/v1/satellite-verify`

Verify a forest land parcel using satellite imagery or coordinates.

| Field | Value |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/satellite-verify` |
| **Content-Type** | `multipart/form-data` |
| **Auth** | None (same as existing endpoints) |

---

### `GET /api/v1/satellite-verify/status/{task_id}`

Poll an async satellite analysis job (for heavy GeoTIFF processing).

| Field | Value |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/satellite-verify/status/{task_id}` |
| **Returns** | `{ "status": "pending|processing|done|failed", "result": {...} }` |

---

## Request & Response Schemas

### Request — `POST /api/v1/satellite-verify`

**`multipart/form-data` fields:**

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `latitude` | `float` | ✅ | — | Centroid latitude of claimed parcel |
| `longitude` | `float` | ✅ | — | Centroid longitude |
| `radius_meters` | `int` | ❌ | `500` | Buffer radius around centroid |
| `start_date` | `string` | ❌ | `2005-12-13` | ISO date `YYYY-MM-DD` for historical baseline |
| `end_date` | `string` | ❌ | today | ISO date for current snapshot |
| `claim_id` | `string` | ❌ | — | Links result to an existing claim |
| `image` | `file` | ❌ | — | GeoTIFF / JPEG / PNG. If omitted, uses coordinate-based lookup |
| `claimant_name` | `string` | ❌ | `""` | For cross-matching with other documents |

**Example (cURL):**
```bash
curl -X POST https://your-backend.railway.app/api/v1/satellite-verify \
  -F "latitude=19.928" \
  -F "longitude=73.221" \
  -F "radius_meters=300" \
  -F "start_date=2005-12-13" \
  -F "end_date=2026-08-01" \
  -F "claim_id=abc-123"
```

---

### Response — `POST /api/v1/satellite-verify`

```json
{
  "claim_id": "abc-123",
  "task_id": "sat-uuid-xyz",
  "status": "done",

  "land_cover": {
    "primary_class": "dense_forest",
    "classes": {
      "dense_forest":   0.72,
      "sparse_forest":  0.15,
      "agricultural":   0.08,
      "settlement":     0.03,
      "water":          0.02
    }
  },

  "ndvi": {
    "mean": 0.61,
    "min": 0.10,
    "max": 0.88,
    "interpretation": "Healthy vegetation — consistent with claimed forest land"
  },

  "canopy_coverage_percent": 71.4,

  "change_detection": {
    "baseline_date": "2005-12-13",
    "current_date":  "2026-08-01",
    "deforestation_detected": false,
    "change_area_sqm": 120,
    "change_severity": "negligible"
  },

  "verification_verdict": {
    "status": "auto_verified",
    "confidence": 0.87,
    "evidence_category": "government_records",
    "description": "Satellite-verified forest land — NDVI 0.61, 71% canopy cover"
  },

  "coordinate_bbox": {
    "north": 19.933,
    "south": 19.923,
    "east":  73.226,
    "west":  73.216
  },

  "is_ai_generated": true,
  "disclaimer": "AI satellite analysis — field verification recommended before submission."
}
```

---

### Response — Error Cases

```json
{
  "status": "failed",
  "error_code": "COORDS_OUT_OF_BOUNDS",
  "message": "Coordinates fall outside Palghar district boundary."
}
```

---

## Frontend Integration Contract

### Flutter App (`vanmitra_tem/`)

#### New Service Class

**File to create:** `lib/services/satellite_service.dart`

```dart
class SatelliteService {
  static const String _baseUrl = 'https://your-backend.railway.app';

  /// POST /api/v1/satellite-verify
  Future<SatelliteVerifyResult> verifyParcel({
    required double latitude,
    required double longitude,
    int radiusMeters = 500,
    String? claimId,
    String? startDate,       // "YYYY-MM-DD"
    File?   satelliteImage,  // optional upload
  });
}
```

#### New Model Class

**File to create:** `lib/models/satellite_result.dart`

```dart
class SatelliteVerifyResult {
  final String  taskId;
  final String  status;                // "auto_verified" | "needs_review" | "rejected"
  final double  ndviMean;
  final double  canopyCoveragePercent;
  final String  primaryLandCover;
  final double  confidence;
  final bool    deforestationDetected;
  final String  description;
  final bool    isAiGenerated;
}
```

#### Where to Show Results

| Screen | Action |
|---|---|
| `ClaimFormScreen` | Add **"Satellite Verify"** button after entering survey coordinates |
| `EvidenceReviewScreen` | Show satellite badge (`🛰️ auto_verified`) in evidence list |
| `ScoringWidget` | NDVI gauge + canopy % bar in evidence score card |
| `DraftPreviewScreen` | Append satellite analysis paragraph to draft text |

---

### Website (`website/`)

#### Add to `website/app.js`

```javascript
// ── Satellite Verify ─────────────────────────────────────────────────────
async function verifySatellite({ lat, lng, radiusMeters = 500, claimId }) {
  const formData = new FormData();
  formData.append('latitude',      lat);
  formData.append('longitude',     lng);
  formData.append('radius_meters', radiusMeters);
  if (claimId) formData.append('claim_id', claimId);

  const res = await fetch(`${API_BASE}/api/v1/satellite-verify`, {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) throw new Error(`Satellite API error: ${res.status}`);
  return res.json();
}

// ── Render satellite result card ─────────────────────────────────────────
function renderSatelliteCard(result) {
  const status = result.verification_verdict.status;
  const ndvi   = result.ndvi.mean.toFixed(2);
  const canopy = result.canopy_coverage_percent.toFixed(1);
  const badge  = status === 'auto_verified' ? '🟢'
               : status === 'needs_review'  ? '🟡' : '🔴';

  document.getElementById('satellite-result').innerHTML = `
    <div class="satellite-card">
      <h3>${badge} Satellite Verification</h3>
      <p>Land Cover: <strong>${result.land_cover.primary_class}</strong></p>
      <p>NDVI Score: <strong>${ndvi}</strong> — ${result.ndvi.interpretation}</p>
      <p>Canopy Coverage: <strong>${canopy}%</strong></p>
      <p>Deforestation: <strong>${result.change_detection.deforestation_detected
        ? '⚠️ Detected' : '✅ None'}</strong></p>
      <p class="confidence">Confidence: ${(result.verification_verdict.confidence * 100).toFixed(0)}%</p>
    </div>
  `;
}
```

---

## Satellite Agent — Python Interface

### Class skeleton for `app/agents.py`

```python
# ── 8. SatelliteAgent ─────────────────────────────────────────────────────────────

class SatelliteAgent:
    """
    Satellite land-cover classification and NDVI analysis.
    Accepts lat/lng + optional GeoTIFF bytes.
    Returns a dict + to_evidence() for ScoringAgent compatibility.
    """

    def analyze(
        self,
        latitude: float,
        longitude: float,
        radius_meters: int = 500,
        image_bytes: Optional[bytes] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
    ) -> Dict:
        """
        Returns satellite verification result dict.
        verdict["status"] maps directly to Evidence.verification_status.
        """
        try:
            ndvi_mean, canopy_pct, land_cover = self._run_analysis(
                latitude, longitude, radius_meters, image_bytes
            )
            status = self._verdict(ndvi_mean, canopy_pct)
            confidence = round(min(ndvi_mean + 0.25, 1.0), 2)
            description = (
                f"Satellite-verified forest land — NDVI {ndvi_mean:.2f}, "
                f"{canopy_pct:.1f}% canopy cover"
            )
            return {
                "status": "done",
                "land_cover": {"primary_class": land_cover},
                "ndvi": {"mean": ndvi_mean, "interpretation": self._ndvi_label(ndvi_mean)},
                "canopy_coverage_percent": canopy_pct,
                "change_detection": {"deforestation_detected": False},
                "verification_verdict": {
                    "status": status,
                    "confidence": confidence,
                    "evidence_category": "government_records",
                    "description": description,
                },
                "is_ai_generated": True,
                "disclaimer": "AI satellite analysis — field verification recommended.",
            }
        except Exception as e:
            return {"status": "failed", "error_code": "ANALYSIS_ERROR", "message": str(e)[:200]}

    def _run_analysis(
        self, lat: float, lng: float, radius: int, image_bytes: Optional[bytes]
    ):
        """
        ⬇️ IMPLEMENT YOUR MODEL LOGIC HERE
        Must return: (ndvi_mean: float, canopy_pct: float, land_class: str)

        Options:
          A) image_bytes is GeoTIFF  → use rasterio + scikit-image
          B) image_bytes is JPEG/PNG → use opencv + pixel analysis
          C) no image                → call external tile API (Sentinel/MODIS)
        """
        raise NotImplementedError("Implement satellite analysis logic")

    def _verdict(self, ndvi: float, canopy: float) -> str:
        if ndvi >= 0.4 and canopy >= 40: return "auto_verified"
        elif ndvi >= 0.2 and canopy >= 20: return "needs_review"
        else: return "rejected"

    def _ndvi_label(self, ndvi: float) -> str:
        if ndvi >= 0.6: return "Healthy vegetation — consistent with claimed forest land"
        elif ndvi >= 0.3: return "Moderate vegetation — partial forest cover"
        elif ndvi >= 0.1: return "Sparse vegetation — may not qualify as forest"
        else: return "Bare land / non-vegetated surface"

    def to_evidence(self, result: Dict) -> Evidence:
        """Convert satellite result to Evidence for ScoringAgent."""
        v = result.get("verification_verdict", {})
        return Evidence(
            category=v.get("evidence_category", "government_records"),
            description=v.get("description", "Satellite analysis"),
            verification_status=v.get("status", "needs_review"),
            confidence=v.get("confidence", 0.5),
        )
```

### Wire into `OrchestratorAgent` (one line)

```python
class OrchestratorAgent:
    def __init__(self):
        self.intake      = IntakeAgent()
        self.eligibility = EligibilityAgent()
        self.scoring     = ScoringAgent()
        self.doc_verify  = DocVerifyAgent()
        self.draft       = DraftAgent()
        self.rejection   = RejectionAgent()
        self.appeal      = AppealAgent()
        self.satellite   = SatelliteAgent()   # ← ADD THIS LINE
```

### New endpoint for `app/main.py`

```python
@app.post("/api/v1/satellite-verify")
async def satellite_verify(
    latitude:      float          = Form(...),
    longitude:     float          = Form(...),
    radius_meters: int            = Form(500),
    claim_id:      Optional[str]  = Form(None),
    start_date:    Optional[str]  = Form(None),
    end_date:      Optional[str]  = Form(None),
    claimant_name: str            = Form(""),
    image:         Optional[UploadFile] = File(None),
):
    image_bytes = await image.read() if image else None
    result = _orchestrator.satellite.analyze(
        latitude=latitude,
        longitude=longitude,
        radius_meters=radius_meters,
        image_bytes=image_bytes,
        start_date=start_date,
        end_date=end_date,
    )
    result["claim_id"] = claim_id or "unlinked"
    result["task_id"]  = str(uuid.uuid4())
    return result
```

---

## File Structure Changes

```
vanmitra_backend/
├── app/
│   ├── __init__.py
│   ├── agents.py          ← MODIFY: add SatelliteAgent class
│   └── main.py            ← MODIFY: add /api/v1/satellite-verify endpoint
├── assets/
│   └── ai_config/
│       ├── evidence_weights.json     (existing)
│       └── satellite_config.json    ← NEW
├── requirements.txt       ← MODIFY: add rasterio, scikit-image, etc.
└── Dockerfile             ← MODIFY: add libgdal-dev
```

### New Asset: `assets/ai_config/satellite_config.json`

```json
{
  "ndvi_thresholds": {
    "auto_verified": 0.4,
    "needs_review":  0.2
  },
  "canopy_thresholds": {
    "auto_verified": 40,
    "needs_review":  20
  },
  "land_cover_classes": [
    "dense_forest", "sparse_forest", "agricultural",
    "settlement", "water", "other"
  ],
  "coordinate_bounds": {
    "description": "Palghar district bounding box",
    "north": 20.4, "south": 19.4,
    "east":  73.6, "west":  72.6
  },
  "default_radius_meters": 500
}
```

---

## Environment Variables

| Variable | Example | Required | Description |
|---|---|---|---|
| `SATELLITE_API_MODE` | `local` | ✅ | `local` / `sentinel` / `gee` |
| `SENTINEL_HUB_CLIENT_ID` | `abc123` | ❌ | Sentinel Hub OAuth client ID |
| `SENTINEL_HUB_CLIENT_SECRET` | `secret` | ❌ | Sentinel Hub OAuth secret |
| `GOOGLE_EARTH_ENGINE_KEY` | `{...json...}` | ❌ | GEE service account JSON |
| `MAX_IMAGE_SIZE_MB` | `20` | ❌ | Upload size limit (default 20 MB) |

---

## Docker / Railway Changes

```diff
 FROM python:3.11-slim

 WORKDIR /app

 RUN apt-get update && apt-get install -y --no-install-recommends \
     tesseract-ocr            \
     tesseract-ocr-mar        \
     tesseract-ocr-hin        \
     libgl1                   \
+    libgdal-dev              \
+    gdal-bin                 \
+    libspatialindex-dev      \
     && rm -rf /var/lib/apt/lists/*

+# Required for rasterio to find GDAL
+ENV GDAL_CONFIG=/usr/bin/gdal-config

 COPY requirements.txt .
 RUN pip install --no-cache-dir -r requirements.txt

 COPY app/    ./app/
 COPY assets/ ./assets/

 EXPOSE 8000
 CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

> [!WARNING]
> Adding GDAL increases Docker image size by ~300 MB. Use a multi-stage build if Railway's free tier storage is constrained.

---

## Error Codes Reference

| `error_code` | HTTP | Meaning | Fix |
|---|---|---|---|
| `COORDS_OUT_OF_BOUNDS` | 422 | Lat/lng outside Palghar district | Check coordinate values |
| `IMAGE_TOO_LARGE` | 413 | Upload > MAX_IMAGE_SIZE_MB | Compress before upload |
| `UNSUPPORTED_FORMAT` | 422 | File not GeoTIFF / JPEG / PNG | Convert format |
| `ANALYSIS_ERROR` | 500 | Internal model failure | Check server logs |
| `NO_DATA_FOR_DATE` | 404 | No imagery for date range | Adjust date range |
| `GDAL_NOT_AVAILABLE` | 503 | rasterio/GDAL not installed | Check Dockerfile |

---

## Quick Integration Checklist

- [ ] Add satellite packages to `requirements.txt`
- [ ] Update `Dockerfile` with GDAL system packages
- [ ] Add `SatelliteAgent` class to `app/agents.py`
- [ ] Wire `self.satellite = SatelliteAgent()` in `OrchestratorAgent.__init__()`
- [ ] Add `/api/v1/satellite-verify` endpoint to `app/main.py`
- [ ] Create `assets/ai_config/satellite_config.json`
- [ ] **Implement** `_run_analysis()` with your model logic
- [ ] Create `SatelliteService` Dart class in Flutter app
- [ ] Create `SatelliteVerifyResult` Dart model class
- [ ] Add satellite result card UI to `ClaimFormScreen`
- [ ] Add satellite JS fetch + render to `website/app.js`
- [ ] Set `SATELLITE_API_MODE` env variable on Railway

---

*VanMitra-AI — Hack4Humanity 2026*
