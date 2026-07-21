"""
VanMitra-AI — FaceNet Keras → TFLite Conversion Script
=======================================================

QUICK START (Python 3.10 required — TF has no wheel for 3.12+):
----------------------------------------------------------------
Windows PowerShell:

    # IMPORTANT: Use a SHORT path for the venv (e.g. C:\tf310)
    # Long paths like Desktop\...\vanmitra_ai_app\tf_venv310 cause
    # an OSError during tensorflow install on Windows (MAX_PATH=260).

    # Step 1 — create venv at a short path
    py -3.10 -m venv C:\tf310

    # Step 2 — install TensorFlow CPU (no GPU needed for conversion)
    C:\tf310\Scripts\pip install tensorflow-cpu==2.15.0 numpy==1.26.4 --timeout 300

    # Step 3 — run this script from vanmitra_ai_app/ directory
    C:\tf310\Scripts\python vanmitra_ai\convert_facenet.py

    # If download times out, use the Tsinghua mirror:
    C:\tf310\Scripts\pip install tensorflow-cpu==2.15.0 numpy==1.26.4 --timeout 300 -i https://pypi.tuna.tsinghua.edu.cn/simple

Output:
    vanmitra_ai/assets/ml/facenet.tflite  (~23 MB, float16 quantised)

Source model:
    keras-facenet (automatically downloads pre-trained weights)

FaceNet I/O spec (Inception ResNet V1 via keras-facenet):
    Input  : [batch, 160, 160, 3]  float32, pixel values normalised to [-1, 1]
    Output : [batch, 512]          float32, L2-normalised 512-dim face embedding

WHY PYTHON 3.10?
    TensorFlow 2.15.0 officially supports Python 3.9, 3.10, 3.11 only.
    Python 3.12+ / 3.13 / 3.14 have no matching TF wheel on PyPI.
    This script auto-detects your Python version and gives clear instructions.
"""

import os
import sys

# ── Python version check ───────────────────────────────────────────────────────
_major, _minor = sys.version_info.major, sys.version_info.minor
print(f"Python {_major}.{_minor}.{sys.version_info.micro} detected")

if not (_major == 3 and _minor in (9, 10, 11)):
    print()
    print("=" * 65)
    print("  ERROR: Incompatible Python version")
    print("=" * 65)
    print(f"  You are using Python {_major}.{_minor}.")
    print("  TensorFlow 2.15.0 requires Python 3.9, 3.10, or 3.11.")
    print()
    print("  Fix (Windows PowerShell):")
    print()
    print("  1. Create a Python 3.10 virtual environment:")
    print("     py -3.10 -m venv tf_venv310")
    print()
    print("  2. Activate it:")
    print("     .\\tf_venv310\\Scripts\\Activate.ps1")
    print()
    print("  3. Install TensorFlow inside the venv:")
    print("     pip install tensorflow==2.15.0 numpy==1.26.4")
    print()
    print("  4. Run this script again from vanmitra_ai_app/ directory:")
    print("     python vanmitra_ai\\convert_facenet.py")
    print()
    print("  If Python 3.10 is not installed on your system:")
    print("     winget install Python.Python.3.10")
    print("  Then repeat steps 1–4.")
    print("=" * 65)
    sys.exit(1)

# ── TensorFlow import ─────────────────────────────────────────────────────────
try:
    import tensorflow as tf
except ImportError:
    print()
    print("=" * 65)
    print("  ERROR: TensorFlow not installed in this Python environment")
    print("=" * 65)
    print(f"  Active Python: {sys.executable}")
    print()
    print("  Install TensorFlow CPU in this venv (smaller, ~400 MB):")
    print("     pip install tensorflow-cpu==2.15.0 numpy==1.26.4 --timeout 300")
    print()
    print("  If download keeps timing out, use a mirror:")
    print("     pip install tensorflow-cpu==2.15.0 numpy==1.26.4 --timeout 300 \\")
    print("         -i https://pypi.tuna.tsinghua.edu.cn/simple")
    print()
    print("  Then run this script again.")
    print("=" * 65)
    sys.exit(1)

try:
    from keras_facenet import FaceNet
except ImportError:
    print()
    print("=" * 65)
    print("  ERROR: keras-facenet not installed in this Python environment")
    print("=" * 65)
    print(f"  Active Python: {sys.executable}")
    print()
    print("  Install keras-facenet in this venv:")
    print("     pip install keras-facenet --timeout 300")
    print()
    print("  Then run this script again.")
    print("=" * 65)
    sys.exit(1)

tf_ver = tuple(int(x) for x in tf.__version__.split(".")[:2])
print(f"TensorFlow {tf.__version__} found")

# ── Paths ─────────────────────────────────────────────────────────────────────
# Resolve paths relative to the vanmitra_ai_app/ directory,
# regardless of where the script is called from.
_script_dir = os.path.dirname(os.path.abspath(__file__))
_app_dir = os.path.dirname(_script_dir)  # vanmitra_ai_app/

OUTPUT_DIR   = os.path.join(_script_dir, "assets", "ml")
OUTPUT_FILE  = os.path.join(OUTPUT_DIR, "facenet.tflite")

# ── Load ──────────────────────────────────────────────────────────────────────
print("Loading FaceNet model via keras-facenet (will download weights if first time) ...")

# Suppress TF verbose output during load
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

embedder = FaceNet()
model = embedder.model
# keras-facenet uses dynamic shapes. Force a static shape for TFLite
inputs = tf.keras.Input(shape=(160, 160, 3), batch_size=1)
outputs = model(inputs)
fixed_model = tf.keras.Model(inputs, outputs)

print(f"  Fixed Input  shape : {fixed_model.input_shape}")
print(f"  Fixed Output shape : {fixed_model.output_shape}")

# ── Validate ──────────────────────────────────────────────────────────────────
assert fixed_model.input_shape[1:] == (160, 160, 3), (
    f"Unexpected input shape {fixed_model.input_shape} — expected (None, 160, 160, 3)"
)
assert fixed_model.output_shape[1] == 512, (
    f"Unexpected output shape {fixed_model.output_shape} — expected (None, 512)"
)
print("Shape validation passed (160x160x3 -> 512-dim embedding)")

# ── Convert ───────────────────────────────────────────────────────────────────
print("Converting to TFLite (float16 quantisation) ...")
converter = tf.lite.TFLiteConverter.from_keras_model(fixed_model)
converter.optimizations       = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

# ── Save ──────────────────────────────────────────────────────────────────────
os.makedirs(OUTPUT_DIR, exist_ok=True)
with open(OUTPUT_FILE, "wb") as f:
    f.write(tflite_model)

output_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
print(f"Saved  : {OUTPUT_FILE}  ({output_mb:.1f} MB)")

# ── Verify the TFLite model ───────────────────────────────────────────────────
print("Verifying TFLite model ...")
interp = tf.lite.Interpreter(model_path=OUTPUT_FILE)
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out = interp.get_output_details()[0]
print(f"  Input  : shape={inp['shape']}  dtype={inp['dtype'].__name__}")
print(f"  Output : shape={out['shape']}  dtype={out['dtype'].__name__}")

assert list(inp["shape"]) == [1, 160, 160, 3], f"TFLite input mismatch: {inp['shape']}"
assert out["shape"][1] == 512, f"TFLite output mismatch: {out['shape']}"
print("Verification passed")

print()
print("=" * 65)
print("  DONE!  facenet.tflite is ready for Flutter.")
print()
print("  Next steps:")
print("    1. flutter pub get   (if not already done)")
print("    2. flutter run       (face enrolment now uses real TFLite model)")
print("=" * 65)
