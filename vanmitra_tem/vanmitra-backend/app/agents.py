"""
VanMitra-AI Model A — Agent Implementations
============================================
All 7 single-responsibility agents from the Colab notebook (VanMitra_ModelA_Colab.ipynb),
plus supporting data classes and the shared FAISS RAG retriever.

Architecture:
  OrchestratorAgent ← holds full ClaimRecord state
  ├─ IntakeAgent        (input sanitize/validate only)
  ├─ EligibilityAgent   (FDST/OTFD test only)
  ├─ DocVerifyAgent     (OCR + fuzzy cross-check only)
  ├─ ScoringAgent       (weighted evidence score only)
  ├─ DraftAgent         (RAG-grounded Form A/B/C draft only)
  ├─ RejectionAgent     (rejection reason classification only)
  └─ AppealAgent        (Section 6 appeal draft only)

None of the specialist agents talk to each other directly.
OrchestratorAgent is the only component that holds full ClaimRecord state.

Dependency:
  pip install fastapi uvicorn python-multipart sentence-transformers
              faiss-cpu rapidfuzz pytesseract Pillow
  apt-get install tesseract-ocr tesseract-ocr-mar tesseract-ocr-hin
"""

import json
import re
import textwrap
import uuid
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np

# ─── Evidence weights (source of truth: assets/ai_config/evidence_weights.json) ────
# Loaded at runtime so Flutter ↔ Python ↔ FastAPI stay numerically identical.
_WEIGHTS_PATH = Path(__file__).parent.parent / "assets" / "ai_config" / "evidence_weights.json"
if _WEIGHTS_PATH.exists():
    with open(_WEIGHTS_PATH, encoding="utf-8") as _f:
        EVIDENCE_WEIGHTS: Dict[str, float] = json.load(_f)
else:
    # Fallback if running standalone outside the Flutter workspace
    EVIDENCE_WEIGHTS = {
        "government_records": 0.25,
        "physical_structures": 0.25,
        "satellite_imagery": 0.15,
        "elder_statements": 0.15,
        "traditional_structures": 0.10,
        "other_govt_schemes": 0.10,
    }

CUTOFF_DATE = date(2005, 12, 13)

FORM_TITLES = {
    "A": {"mr": "फॉर्म अ — वैयक्तिक वन हक्क दावा", "en": "Form A — Individual Forest Rights Claim"},
    "B": {"mr": "फॉर्म ब — सामुदायिक हक्क दावा", "en": "Form B — Community Rights Claim"},
    "C": {"mr": "फॉर्म क — सामुदायिक वन संसाधन हक्क दावा", "en": "Form C — Community Forest Resource Rights Claim"},
}

REJECTION_CLASSES = [
    "procedural_defect", "insufficient_evidence", "boundary_dispute",
    "occupation_not_proven", "wrong_jurisdiction", "beyond_time_limit",
    "duplicate_claim", "valid_rejection", "invalid_rejection",
]

REJECTION_KEYWORDS = {
    "procedural_defect": ["signature", "unsigned", "incomplete form", "स्वाक्षरी"],
    "insufficient_evidence": ["evidence", "proof", "पुरावा", "documents lacking"],
    "boundary_dispute": ["boundary", "overlap", "सीमा", "adjoining claim"],
    "occupation_not_proven": ["occupation", "2005", "ताबा", "residence not proven"],
    "wrong_jurisdiction": ["jurisdiction", "wrong committee", "अधिकार क्षेत्र"],
    "beyond_time_limit": ["time limit", "late", "deadline", "मुदत"],
    "duplicate_claim": ["duplicate", "already filed", "पुनरावृत्ती"],
}


# ─── Data classes ────────────────────────────────────────────────────────────────

@dataclass
class Evidence:
    category: str                   # key into EVIDENCE_WEIGHTS
    description: str
    file_ref: Optional[str] = None
    verification_status: str = "unverified"   # unverified|auto_verified|needs_review|rejected
    confidence: float = 0.0


@dataclass
class Rejection:
    reason_class: Optional[str] = None
    order_ref: Optional[str] = None
    appeal_deadline: Optional[str] = None


@dataclass
class ClaimRecord:
    form_type: str                  # "A" | "B" | "C"
    claimant_category: str          # "FDST" | "OTFD"
    claimant_scope: str             # individual | family | community | gram_sabha
    claimant_name: str
    father_husband_name: str
    tribe_caste: str
    village: str
    gram_sabha: str
    tehsil: str
    district: str
    residence_start_date: str       # ISO date string
    depends_on_forest: bool
    survey_khasra_no: Optional[str]
    area_value: float
    area_unit: str
    nature_of_right: List[str]
    community_details: Dict = field(default_factory=dict)
    evidence: List[Evidence] = field(default_factory=list)
    witnesses: List[Dict] = field(default_factory=list)
    sketch_map_ref: Optional[str] = None
    language: str = "mr"
    claim_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    status: str = "draft"
    evidence_score: float = 0.0
    rejection: Rejection = field(default_factory=Rejection)
    draft_text: str = ""
    hash_chain_ref: Optional[str] = None


# ─── Shared FAISS RAG (loaded once, shared by DraftAgent and AppealAgent) ────────

FRA_CORPUS = [
    "Forest Dwelling Scheduled Tribes (FDST) must belong to a Scheduled Tribe in that area, "
    "have resided in forest land before 13 December 2005, and depend on the forest for livelihood.",

    "Other Traditional Forest Dwellers (OTFD) must have lived in and depended on the forest for "
    "at least 75 years (three generations) before 13 December 2005, and depend on the forest for livelihood.",

    "Claims may be filed by an individual tribal person, a tribal family, the entire village or Gram Sabha, "
    "or a forest-dependent community for Community Forest Rights.",

    "Rule 13 of the FRA Rules 2008 allows a wide range of evidence: identity proof such as Aadhaar, Voter ID, "
    "Ration Card, Caste Certificate, or PAN; residence proof such as old ration cards, electoral rolls, "
    "school or census records; and occupation proof such as revenue records, forest department records, "
    "old survey maps, satellite images, cultivation records, and old pattas or leases.",

    "Community and traditional evidence is especially important in tribal areas and includes statements "
    "of village elders, Gram Sabha resolutions, traditional maps, and evidence of grazing, bamboo "
    "collection, tendu collection, and fishing.",

    "For Community Forest Resource (CFR) claims under Form C, evidence includes the village boundary map, "
    "traditional forest-use map, evidence of customary use of forest resources, and consent of neighbouring "
    "villages where applicable.",

    "If a tribal family has no documentary evidence, the FRA specifically allows oral evidence, witness "
    "testimony, statements of elders, community verification by the Gram Sabha, and physical verification "
    "by the Forest Rights Committee (FRC).",

    "The Gram Sabha forms a Forest Rights Committee (FRC) of 10 to 15 members, at least one-third of whom "
    "must be women, and the FRC helps villagers file claims using Form A, B, or C.",

    "The Forest Rights Committee conducts field verification, checking boundaries, land use, cultivation, "
    "and traditional forest dependence, and elders and local residents may provide testimony.",

    "The FRC submits its findings to the Gram Sabha, which discusses and passes a resolution recommending "
    "acceptance or rejection of claims.",

    "The claim then goes to the Sub-Divisional Level Committee (SDLC), headed by the Sub-Divisional "
    "Officer, which reviews the Gram Sabha's recommendations and evidence.",

    "The District Level Committee (DLC), usually chaired by the District Collector, is the final authority "
    "for approving or rejecting claims; if approved, a forest rights title certificate is issued.",

    "Form A is the claim for Individual Forest Rights (IFR), filed by an individual or family, and requires "
    "claimant details, tribe/caste, village and Gram Sabha details, FDST or OTFD status, details of forest "
    "land occupied including survey or khasra number, area under cultivation, duration of occupation, "
    "type of right claimed such as habitation or self-cultivation, evidence attached, witness signatures, "
    "and a sketch map of the land if available.",

    "Form B is the claim for Community Rights (CR), filed by a Gram Sabha, village community, tribal "
    "community, pastoralists, or forest-dependent groups, and requires the name of the village or "
    "community, the nature of the community right claimed, the forest area used, traditional uses such as "
    "grazing, fishing, water bodies, bamboo collection, tendu leaves, fuelwood, minor forest produce, and "
    "seasonal access routes, boundaries of the claimed area, evidence of customary use, and community "
    "resolutions with witness statements.",

    "A rejected claim may be appealed within a sixty day window under Section 6 of the Forest Rights Act; "
    "common invalid grounds for rejection include failure to cite the specific Rule 13 evidence category "
    "considered, absence of Forest Rights Committee field verification, and rejection issued without a "
    "reasoned order.",

    "Common reasons genuine claims get rejected include lack of awareness about the FRA, missing or poorly "
    "maintained records, difficulty collecting evidence, delays in Gram Sabha verification, incorrect "
    "mapping of forest boundaries, poor tracking of claim status, and language barriers for tribal "
    "communities.",
]


def _build_rag_index():
    """Build the FAISS index from the FRA corpus. Falls back to keyword-only if unavailable."""
    try:
        from sentence_transformers import SentenceTransformer
        import faiss
        embedder = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
        embeddings = embedder.encode(FRA_CORPUS, convert_to_numpy=True)
        index = faiss.IndexFlatL2(embeddings.shape[1])
        index.add(embeddings)
        return embedder, index
    except Exception:
        return None, None


_embedder, _rag_index = _build_rag_index()


def retrieve(query: str, k: int = 3) -> List[str]:
    """Retrieve top-k relevant FRA corpus chunks for a query.

    Falls back to returning the first k chunks when sentence-transformers
    or faiss are unavailable (e.g. minimal deploy).
    """
    if _embedder is None or _rag_index is None:
        return FRA_CORPUS[:k]
    q_emb = _embedder.encode([query], convert_to_numpy=True)
    _, indices = _rag_index.search(q_emb, k)
    return [FRA_CORPUS[i] for i in indices[0]]


# ─── 1. IntakeAgent ──────────────────────────────────────────────────────────────

class IntakeAgent:
    """Guards the edge between the villager and every other agent.
    Single job: sanitize + validate raw input. Never talks to Draft/Rejection/Appeal directly."""

    REQUIRED_FIELDS = [
        "claimant_name", "father_husband_name", "tribe_caste",
        "village", "gram_sabha", "tehsil", "district",
        "residence_start_date", "form_type",
    ]

    def process(self, raw: Dict) -> Dict:
        clean = {}
        flags = []

        for f in self.REQUIRED_FIELDS:
            value = raw.get(f)
            if value is None or (isinstance(value, str) and not value.strip()):
                flags.append(f"Missing required field '{f}' -- escalate to human FRC member.")
                clean[f] = None
            else:
                clean[f] = value.strip() if isinstance(value, str) else value

        for f in ("claimant_name", "father_husband_name", "village", "gram_sabha"):
            if clean.get(f):
                clean[f] = re.sub(r"\s+", " ", re.sub(r"[\x00-\x1f]", "", clean[f])).strip()

        rsd = raw.get("residence_start_date")
        try:
            if rsd:
                date.fromisoformat(rsd)
        except ValueError:
            flags.append("residence_start_date is not a valid ISO date -- escalate to human FRC member.")

        if raw.get("form_type") not in ("A", "B", "C"):
            flags.append("form_type must be A, B, or C -- escalate to human FRC member.")

        clean["needs_human_review"] = len(flags) > 0
        clean["review_notes"] = flags
        return clean


# ─── 2. EligibilityAgent ─────────────────────────────────────────────────────────

class EligibilityAgent:
    """Single job: FDST / OTFD eligibility test (FRA Sec. 2(c)/2(o)). Nothing else."""

    def check(self, is_scheduled_tribe: bool, residence_start: date,
              depends_on_forest: bool, years_of_dependence: int) -> Dict:
        result = {"eligible": False, "category": None, "reasons": []}
        residence_before_cutoff = residence_start < CUTOFF_DATE

        if is_scheduled_tribe and residence_before_cutoff and depends_on_forest:
            result.update(eligible=True, category="FDST")
            result["reasons"].append("Meets FDST criteria: ST + pre-2005 residence + forest dependence.")
            return result

        if years_of_dependence >= 75 and residence_before_cutoff and depends_on_forest:
            result.update(eligible=True, category="OTFD")
            result["reasons"].append("Meets OTFD criteria: >=75 years (3 generations) dependence + pre-2005 residence.")
            return result

        if not residence_before_cutoff:
            result["reasons"].append("Residence/occupation must have started before 13 Dec 2005.")
        if not depends_on_forest:
            result["reasons"].append("Must demonstrate bona fide dependence on forest for livelihood.")
        if not is_scheduled_tribe and years_of_dependence < 75:
            result["reasons"].append("Neither ST-status nor 75-year OTFD dependence threshold is met.")

        return result


# ─── 3. ScoringAgent ─────────────────────────────────────────────────────────────

class ScoringAgent:
    """Single job: compute the weighted Evidence Score from already-verified evidence."""

    STATUS_VALUE = {"auto_verified": 1.0, "needs_review": 0.6, "unverified": 0.3, "rejected": 0.0}

    def score(self, evidence_list: List[Evidence]) -> float:
        best_per_category: Dict[str, float] = {}
        for ev in evidence_list:
            v = self.STATUS_VALUE.get(ev.verification_status, 0.0)
            best_per_category[ev.category] = max(best_per_category.get(ev.category, 0.0), v)

        num, den = 0.0, 0.0
        for cat, weight in EVIDENCE_WEIGHTS.items():
            xi = best_per_category.get(cat, 0.0)
            num += weight * xi
            den += weight
        return round(num / den, 3) if den else 0.0

    def risk_level(self, score: float) -> str:
        if score >= 0.8:
            return "🟢 Ready — Submit"
        elif score >= 0.6:
            return "🟡 Partial — Warn"
        else:
            return "🔴 High Risk — Alert"


# ─── 4. DocVerifyAgent ───────────────────────────────────────────────────────────

class DocVerifyAgent:
    """Single job: OCR + document-type cross-check. Returns a verdict, never a score or draft."""

    def verify(self, image_bytes: bytes, expected_category: str, claim: ClaimRecord) -> Dict:
        try:
            import pytesseract
            from PIL import Image
            from rapidfuzz import fuzz
            import io

            img = Image.open(io.BytesIO(image_bytes))
            ocr_text = pytesseract.image_to_string(img, lang="eng+mar+hin")

            name_score = fuzz.partial_ratio(claim.claimant_name.lower(), ocr_text.lower())
            survey_score = 0
            if claim.survey_khasra_no:
                survey_score = fuzz.partial_ratio(
                    str(claim.survey_khasra_no).lower(), ocr_text.lower()
                )

            match_confidence = round(max(name_score, survey_score) / 100, 2)

            if match_confidence >= 0.8:
                status = "auto_verified"
            elif match_confidence >= 0.4:
                status = "needs_review"
            else:
                status = "rejected"

            extracted_fields = {
                "name_match_score": round(name_score / 100, 2),
                "survey_no_match_score": round(survey_score / 100, 2) if claim.survey_khasra_no else None,
            }

            return {
                "document_type": expected_category,
                "verification_status": status,
                "extracted_fields": extracted_fields,
                "extracted_text_preview": ocr_text.strip()[:200],
                "match_confidence": match_confidence,
            }

        except ImportError:
            # tesseract/pytesseract not installed — return needs_review
            return {
                "document_type": expected_category,
                "verification_status": "needs_review",
                "extracted_fields": {},
                "extracted_text_preview": "[OCR not available — tesseract not installed]",
                "match_confidence": 0.0,
            }
        except Exception as e:
            return {
                "document_type": expected_category,
                "verification_status": "needs_review",
                "extracted_fields": {},
                "extracted_text_preview": f"[OCR error: {str(e)[:100]}]",
                "match_confidence": 0.0,
            }


# ─── 5. DraftAgent ───────────────────────────────────────────────────────────────

class DraftAgent:
    """Single job: RAG-grounded Form A/B/C draft rendering. Consumes a fully-populated
    ClaimRecord handed to it by the OrchestratorAgent — never verifies or scores anything itself."""

    def __init__(self):
        self._scorer = ScoringAgent()

    def generate(self, claim: ClaimRecord, top_k_context: int = 2) -> str:
        lang = claim.language
        title = FORM_TITLES.get(claim.form_type, {}).get(lang,
                FORM_TITLES.get(claim.form_type, {}).get("en", f"Form {claim.form_type}"))

        query = f"Form {claim.form_type} evidence and eligibility for {claim.claimant_category}"
        context = retrieve(query, k=top_k_context)
        legal_grounding = "\n".join(f"  • {c}" for c in context)

        evidence_lines = "\n".join(
            f"  - {ev.description} ({ev.category}, status: {ev.verification_status})"
            for ev in claim.evidence
        ) or "  - [To be attached / oral evidence per Rule 13(3)]"

        risk = self._scorer.risk_level(claim.evidence_score)

        draft = textwrap.dedent(f"""
        {title}
        ------------------------------------------------------------
        सेवेसी, / To: Forest Rights Committee, {claim.gram_sabha}, {claim.tehsil}, {claim.district}

        Claimant: {claim.claimant_name}  (Father/Husband: {claim.father_husband_name})
        Tribe/Caste: {claim.tribe_caste}   Category: {claim.claimant_category}
        Village: {claim.village}   Gram Sabha: {claim.gram_sabha}
        Tehsil: {claim.tehsil}   District: {claim.district}

        Land / Resource Details:
          Survey/Khasra No.: {claim.survey_khasra_no or "N/A"}
          Area: {claim.area_value} {claim.area_unit}
          Nature of right claimed: {", ".join(claim.nature_of_right)}
          Occupation/use since: {claim.residence_start_date}

        Evidence Submitted:
        {evidence_lines}

        Evidence Score: {claim.evidence_score}  ({risk})

        Legal Grounding (retrieved from FRA corpus):
        {legal_grounding}

        We respectfully request the Forest Rights Committee and Gram Sabha to verify and recommend
        this claim to the Sub-Divisional Level Committee for approval under the Forest Rights Act, 2006.

        Witnesses: {", ".join(w.get("name", "") for w in claim.witnesses) or "[to be attested at FRC verification]"}
        Date: {date.today().isoformat()}
        ------------------------------------------------------------
        """).strip()

        return draft


# ─── 6. RejectionAgent ───────────────────────────────────────────────────────────

class RejectionAgent:
    """Single job: classify why a claim was rejected, and whether the rejection is
    legally valid. Does NOT draft the appeal — that is AppealAgent's separate job."""

    def classify(self, ocr_text: str) -> Dict:
        text_l = ocr_text.lower()
        scores = {cls: sum(1 for kw in kws if kw.lower() in text_l)
                  for cls, kws in REJECTION_KEYWORDS.items()}
        best_class = max(scores, key=scores.get) if any(scores.values()) else "invalid_rejection"

        cites_rule13 = "rule 13" in text_l or "नियम १३" in ocr_text or "नियम 13" in ocr_text
        is_valid = best_class not in ("invalid_rejection",) and cites_rule13

        return {
            "rejection_reason": best_class,
            "is_rejection_valid": is_valid,
            "validity_explanation": (
                "Rejection cites Rule 13 evidence category and a specific defect." if is_valid
                else "Rejection does not clearly cite the Rule 13 evidence category considered -- "
                     "may be appealable under Section 6."
            ),
            "appeal_recommended": not is_valid,
        }


# ─── 7. AppealAgent ──────────────────────────────────────────────────────────────

class AppealAgent:
    """Single job: draft the Section 6 appeal from a RejectionAgent verdict.
    Separate agent from RejectionAgent because classifying vs. drafting are different failure modes."""

    def generate(self, claim: ClaimRecord, rejection_analysis: Dict) -> Dict:
        query = f"Section 6 appeal {rejection_analysis['rejection_reason']} evidence rule 13"
        context = retrieve(query, k=2)
        legal_grounding = "\n".join(f"  • {c}" for c in context)

        appeal_deadline = (date.today() + timedelta(days=60)).isoformat()

        appeal_text = textwrap.dedent(f"""
        SECTION 6 APPEAL — Forest Rights Act, 2006
        ------------------------------------------------------------
        Re: Claim {claim.claim_id} ({FORM_TITLES.get(claim.form_type, {}).get('en', f'Form {claim.form_type}')})
        Claimant: {claim.claimant_name}, {claim.village}, {claim.tehsil}, {claim.district}

        Ground of rejection cited: {rejection_analysis['rejection_reason']}
        Our assessment: {rejection_analysis['validity_explanation']}

        We submit this appeal under Section 6 of the Forest Rights Act, 2006, requesting the
        Sub-Divisional Level Committee to reconsider the claim in light of the following:
        {legal_grounding}

        Appeal deadline: {appeal_deadline} (60 days from rejection order)
        ------------------------------------------------------------
        """).strip()

        return {"appeal_text": appeal_text, "appeal_deadline": appeal_deadline, "is_ai_generated": True}


# ─── OrchestratorAgent ───────────────────────────────────────────────────────────

class OrchestratorAgent:
    """The only agent that holds full ClaimRecord state. Routes control between
    IntakeAgent, EligibilityAgent, DocVerifyAgent, ScoringAgent, DraftAgent,
    RejectionAgent, and AppealAgent -- none of which talk to each other directly."""

    def __init__(self):
        self.intake = IntakeAgent()
        self.eligibility = EligibilityAgent()
        self.scoring = ScoringAgent()
        self.doc_verify = DocVerifyAgent()
        self.draft = DraftAgent()
        self.rejection = RejectionAgent()
        self.appeal = AppealAgent()

    def run_claim_pipeline(self, claim: ClaimRecord, is_scheduled_tribe: bool,
                           years_of_dependence: int) -> Dict:
        # 1) EligibilityAgent — structured verdict only
        eligibility_verdict = self.eligibility.check(
            is_scheduled_tribe=is_scheduled_tribe,
            residence_start=date.fromisoformat(claim.residence_start_date),
            depends_on_forest=claim.depends_on_forest,
            years_of_dependence=years_of_dependence,
        )

        # 2) ScoringAgent — reads verification statuses DocVerifyAgent already set on claim.evidence
        claim.evidence_score = self.scoring.score(claim.evidence)

        # 3) DraftAgent — only gets the actual verified ClaimRecord, never a re-summarized version
        claim.draft_text = self.draft.generate(claim)

        return {
            "claim_id": claim.claim_id,
            "eligibility": eligibility_verdict,
            "evidence_score": claim.evidence_score,
            "risk_level": self.scoring.risk_level(claim.evidence_score),
            "draft_text": claim.draft_text,
            "form_type": claim.form_type,
            "is_ai_generated": True,
            "language": claim.language,
            "disclaimer": "AI-generated draft — review required before submission.",
        }

    def run_rejection_appeal_pipeline(self, claim: ClaimRecord, ocr_rejection_text: str) -> Dict:
        rejection_verdict = self.rejection.classify(ocr_rejection_text)
        claim.rejection.reason_class = rejection_verdict["rejection_reason"]
        appeal_result = self.appeal.generate(claim, rejection_verdict)
        claim.rejection.appeal_deadline = appeal_result["appeal_deadline"]
        return {"rejection": rejection_verdict, "appeal": appeal_result}

    def verify_document(self, image_bytes: bytes, expected_category: str,
                        claim: ClaimRecord) -> Dict:
        return self.doc_verify.verify(image_bytes, expected_category, claim)
