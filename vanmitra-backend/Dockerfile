FROM python:3.11-slim

WORKDIR /app

# System: Tesseract OCR + Marathi + Hindi language packs
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    tesseract-ocr-mar \
    tesseract-ocr-hin \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App
COPY app/ ./app/

# Copy evidence_weights.json from the Flutter asset bundle
# (so agents.py reads it via the same path as in development)
COPY ../assets/ai_config/ ./assets/ai_config/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
