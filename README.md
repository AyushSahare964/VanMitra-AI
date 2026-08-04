# VanMitra-AI — Project Root

> Forest Rights Act (FRA 2006) digital assistant for tribal communities.
> Powered by Flutter (frontend) + FastAPI (backend AI) + Firebase (database/auth).

---

## 📁 Project Structure

```
vanmitra_tem/                        ← Project Root (this folder)
│
├── vanmitra_tem/                    ← 📱 FRONTEND — Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── config/                  ← AI agent config loader
│   │   ├── core/                    ← Theme, colors, typography
│   │   ├── data/                    ← Seed data, repositories
│   │   ├── models/                  ← Claim, Meeting, Attendance models
│   │   ├── providers/               ← Riverpod state providers
│   │   ├── screens/                 ← All UI screens
│   │   ├── services/                ← Firebase, AI, OCR services
│   │   └── widgets/                 ← Reusable UI components
│   ├── assets/
│   │   └── ai_config/               ← Shared config JSONs (same as backend)
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
│
├── vanmitra_backend/                ← 🤖 BACKEND — FastAPI AI Server
│   ├── app/
│   │   ├── main.py                  ← FastAPI app + all 9 API endpoints
│   │   └── agents.py                ← 7 AI agents + OrchestratorAgent
│   ├── assets/ai_config/            ← Same config JSONs as Flutter assets
│   ├── Dockerfile                   ← Railway deployment (auto-detected)
│   ├── railway.toml                 ← Railway config-as-code
│   ├── requirements.txt             ← Python dependencies
│   └── README.md                    ← Backend deploy instructions
│
├── functions/                       ← 🔥 Firebase Cloud Functions (Node.js)
│   ├── index.js
│   └── package.json
│
├── firebase.json                    ← Firebase project config
├── firestore.rules                  ← Firestore security rules
├── firestore.indexes.json           ← Firestore composite indexes
└── .firebaserc                      ← Firebase project alias
```

---

## 🚀 Quick Start

### Frontend (Flutter)
```powershell
cd vanmitra_tem
flutter pub get
flutter run -d chrome
```

### Backend (Python FastAPI — local)
```powershell
cd vanmitra_backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Then open `http://localhost:8000/docs` for interactive API docs.

### Connect Flutter to Backend
```powershell
# Pass the backend URL at run time:
flutter run -d chrome --dart-define=VANMITRA_API_BASE_URL=http://localhost:8000

# For production (Railway URL):
flutter run -d chrome --dart-define=VANMITRA_API_BASE_URL=https://YOUR-APP.up.railway.app
```

---

## 🤖 Backend API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/v1/health` | Health check |
| `POST` | `/api/v1/eligibility-check` | FDST/OTFD eligibility |
| `POST` | `/api/v1/verify-document` | OCR document verification |
| `POST` | `/api/v1/generate-draft` | AI claim draft (Form A/B/C) |
| `POST` | `/api/v1/transcribe` | Whisper voice-to-text |
| `POST` | `/api/v1/analyze-rejection` | Rejection classification |
| `POST` | `/api/v1/generate-appeal` | Section 6 appeal draft |

---

## 🔥 Firebase Services Used

| Service | Purpose |
|---------|---------|
| **Firestore** | Claims, meetings, attendance, notices |
| **Authentication** | Village worker / admin login |
| **Hosting** | Web app deployment |
| **Cloud Functions** | Server-side triggers (future) |

---

## 🚢 Deploy Backend to Railway

See [`vanmitra_backend/README.md`](vanmitra_backend/README.md) for step-by-step Railway deployment instructions.

**Short version:**
1. Push this repo to GitHub
2. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
3. Select this repo → set **Root Directory** to `vanmitra_backend`
4. Railway auto-builds the Dockerfile → gives you a public URL
5. Set `VANMITRA_API_BASE_URL` in Flutter to that URL
