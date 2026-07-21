"""
VanMitra-AI Model A — FastAPI Backend
======================================
Full endpoint implementations backed by the 7-agent + OrchestratorAgent architecture
defined in app/agents.py (translated from VanMitra_ModelA_Colab.ipynb).

Run locally:
  uvicorn app.main:app --reload --port 8000

Android emulator → host: VANMITRA_API_BASE_URL=http://10.0.2.2:8000

Endpoints:
  GET  /api/v1/health
  POST /api/v1/eligibility-check
  POST /api/v1/verify-document
  POST /api/v1/generate-draft
  POST /api/v1/transcribe
  POST /api/v1/analyze-rejection
  POST /api/v1/generate-appeal
  POST /api/v1/notices            (Notice Board sync)
  GET  /api/v1/notices
"""

from datetime import date, datetime
from typing import Dict, List, Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .agents import (
    ClaimRecord,
    Evidence,
    OrchestratorAgent,
    CUTOFF_DATE,
)

app = FastAPI(
    title="VanMitra-AI Model A API",
    description="Forest Rights Act claim processing backend — Ozhar village (जव्हार, पालघर)",
    version="1.0.0",
)

# Allow Flutter debug builds to reach the API from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Single OrchestratorAgent instance — initialized at startup, shared across all requests.
# Holds the FAISS index in memory after first request.
_orchestrator = OrchestratorAgent()

# In-memory notices store (replace with DB in production)
_notices: List[Dict] = []


# ─── Health ───────────────────────────────────────────────────────────────────────

@app.get("/api/v1/health")
def health_check():
    """Lightweight health check polled by Flutter before every AI call."""
    return {
        "status": "ok",
        "service": "VanMitra-AI Model A",
        "timestamp": datetime.utcnow().isoformat(),
        "agents": ["intake", "eligibility", "doc_verify", "scoring", "draft", "rejection", "appeal"],
    }


# ─── Eligibility Check ────────────────────────────────────────────────────────────

class EligibilityRequest(BaseModel):
    is_scheduled_tribe: bool
    residence_start_date: str          # ISO date string e.g. "1995-06-01"
    depends_on_forest: bool = True
    years_of_dependence: int = 0


@app.post("/api/v1/eligibility-check")
def eligibility_check(req: EligibilityRequest):
    """IntakeAgent sanitizes, then EligibilityAgent.check() — no evidence or draft logic."""
    try:
        residence_start = date.fromisoformat(req.residence_start_date)
    except ValueError:
        raise HTTPException(status_code=422, detail="residence_start_date must be ISO format YYYY-MM-DD")

    result = _orchestrator.eligibility.check(
        is_scheduled_tribe=req.is_scheduled_tribe,
        residence_start=residence_start,
        depends_on_forest=req.depends_on_forest,
        years_of_dependence=req.years_of_dependence,
    )
    result["cutoff_date"] = CUTOFF_DATE.isoformat()
    return result


# ─── Document Verification ────────────────────────────────────────────────────────

class DocVerifyMeta(BaseModel):
    expected_category: str
    claimant_name: str
    survey_khasra_no: Optional[str] = None
    gram_sabha: str = "Ozhar Gram Sabha"
    tehsil: str = "Jawhar"
    district: str = "Palghar"


@app.post("/api/v1/verify-document")
async def verify_document(
    image: UploadFile = File(...),
    expected_category: str = Form(...),
    claimant_name: str = Form(""),
    survey_khasra_no: Optional[str] = Form(None),
):
    """DocVerifyAgent.verify() only — returns {document_type, verification_status, extracted_fields, match_confidence}."""
    image_bytes = await image.read()

    # Build a minimal ClaimRecord with the claimant context needed for fuzzy matching
    claim = ClaimRecord(
        form_type="A",
        claimant_category="FDST",
        claimant_scope="individual",
        claimant_name=claimant_name or "Unknown",
        father_husband_name="",
        tribe_caste="",
        village="Ozhar",
        gram_sabha="Ozhar Gram Sabha",
        tehsil="Jawhar",
        district="Palghar",
        residence_start_date="1990-01-01",
        depends_on_forest=True,
        survey_khasra_no=survey_khasra_no,
        area_value=0,
        area_unit="sqm",
        nature_of_right=["cultivation"],
    )

    result = _orchestrator.verify_document(image_bytes, expected_category, claim)
    return result


# ─── Generate Draft ───────────────────────────────────────────────────────────────

class ClaimInput(BaseModel):
    form_type: str = Field(..., pattern="^[ABC]$")
    claimant_name: str
    father_husband_name: str
    tribe_caste: str = "Warli"
    village: str = "Ozhar"
    gram_sabha: str = "Ozhar Gram Sabha"
    tehsil: str = "Jawhar"
    district: str = "Palghar"
    survey_number: Optional[str] = None
    area_sq_meters: float = 0.0
    nature_of_right: str = "cultivation"
    occupation_years: int = 0
    residence_start_date: str = "1990-01-01"
    depends_on_forest: bool = True
    is_scheduled_tribe: bool = True
    evidence: Optional[Dict[str, str]] = None  # category → verification_status
    language: str = "mr"
    claimant_scope: str = "individual"


@app.post("/api/v1/generate-draft")
def generate_draft(payload: ClaimInput):
    """Build ClaimRecord from payload, run OrchestratorAgent pipeline, return draft."""
    # Convert evidence dict to Evidence objects
    evidence_list = []
    if payload.evidence:
        for category, status in payload.evidence.items():
            evidence_list.append(Evidence(
                category=category,
                description=f"{category} evidence",
                verification_status=status,
                confidence=1.0 if status == "auto_verified" else 0.6,
            ))

    claim = ClaimRecord(
        form_type=payload.form_type,
        claimant_category="FDST" if payload.is_scheduled_tribe else "OTFD",
        claimant_scope=payload.claimant_scope,
        claimant_name=payload.claimant_name,
        father_husband_name=payload.father_husband_name,
        tribe_caste=payload.tribe_caste,
        village=payload.village,
        gram_sabha=payload.gram_sabha,
        tehsil=payload.tehsil,
        district=payload.district,
        residence_start_date=payload.residence_start_date,
        depends_on_forest=payload.depends_on_forest,
        survey_khasra_no=payload.survey_number,
        area_value=payload.area_sq_meters,
        area_unit="sqm",
        nature_of_right=[payload.nature_of_right],
        evidence=evidence_list,
        language=payload.language,
    )

    result = _orchestrator.run_claim_pipeline(
        claim=claim,
        is_scheduled_tribe=payload.is_scheduled_tribe,
        years_of_dependence=payload.occupation_years,
    )
    return result


# ─── Transcribe Voice ─────────────────────────────────────────────────────────────

@app.post("/api/v1/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    language: str = Form("mr"),
):
    """Whisper ASR — transcribed text feeds IntakeAgent, not directly into DraftAgent."""
    try:
        import whisper
        import tempfile
        import os
        audio_bytes = await audio.read()
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name
        model = whisper.load_model("base")
        result = whisper.transcribe(model, tmp_path, language=language)
        os.unlink(tmp_path)
        return {"text": result["text"], "language": language, "is_ai_generated": True}
    except ImportError:
        raise HTTPException(
            status_code=503,
            detail="Whisper not installed. Install openai-whisper to enable voice transcription."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")


# ─── Analyze Rejection ────────────────────────────────────────────────────────────

@app.post("/api/v1/analyze-rejection")
async def analyze_rejection(image: UploadFile = File(...)):
    """OCR the rejection order image, call RejectionAgent.classify(), return verdict JSON."""
    image_bytes = await image.read()

    try:
        import pytesseract
        from PIL import Image
        import io
        img = Image.open(io.BytesIO(image_bytes))
        ocr_text = pytesseract.image_to_string(img, lang="eng+mar+hin")
    except Exception:
        # No tesseract — return a usable fallback
        return {
            "is_ocr_processed": False,
            "rejection_reason": "unknown",
            "is_rejection_valid": None,
            "validity_explanation": "OCR not available. Please enter rejection details manually.",
            "appeal_recommended": True,
        }

    result = _orchestrator.rejection.classify(ocr_text)
    result["is_ocr_processed"] = True
    result["rejection_date"] = datetime.utcnow().date().isoformat()
    return result


# ─── Generate Appeal ──────────────────────────────────────────────────────────────

class AppealRequest(BaseModel):
    rejection_analysis: Dict
    original_claim: ClaimInput


@app.post("/api/v1/generate-appeal")
def generate_appeal(req: AppealRequest):
    """Call AppealAgent.generate() — returns appeal_text + appeal_deadline."""
    evidence_list = []
    if req.original_claim.evidence:
        for category, status in req.original_claim.evidence.items():
            evidence_list.append(Evidence(
                category=category,
                description=f"{category} evidence",
                verification_status=status,
            ))

    claim = ClaimRecord(
        form_type=req.original_claim.form_type,
        claimant_category="FDST" if req.original_claim.is_scheduled_tribe else "OTFD",
        claimant_scope=req.original_claim.claimant_scope,
        claimant_name=req.original_claim.claimant_name,
        father_husband_name=req.original_claim.father_husband_name,
        tribe_caste=req.original_claim.tribe_caste,
        village=req.original_claim.village,
        gram_sabha=req.original_claim.gram_sabha,
        tehsil=req.original_claim.tehsil,
        district=req.original_claim.district,
        residence_start_date=req.original_claim.residence_start_date,
        depends_on_forest=req.original_claim.depends_on_forest,
        survey_khasra_no=req.original_claim.survey_number,
        area_value=req.original_claim.area_sq_meters,
        area_unit="sqm",
        nature_of_right=[req.original_claim.nature_of_right],
        evidence=evidence_list,
        language=req.original_claim.language,
    )

    result = _orchestrator.appeal.generate(claim, req.rejection_analysis)
    return result


# ─── Notice Board Sync ────────────────────────────────────────────────────────────

@app.get("/api/v1/notices")
def get_notices():
    """Return all active notices (from the in-memory store / future DB)."""
    return {"notices": _notices, "count": len(_notices)}


@app.post("/api/v1/notices")
def post_notice(notice: Dict):
    """Admin-posted or system-generated notice sync endpoint."""
    _notices.append(notice)
    return {"status": "ok", "notice_id": notice.get("noticeId", "unknown")}
