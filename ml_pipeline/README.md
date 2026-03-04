# BhashaLens — MarianMT Training Pipeline

Training pipeline for offline neural machine translation models, designed to run on **Kaggle** or **Google Colab**.

## Language Pairs (8 bidirectional models)

| Direction | Base Model |
|-----------|-----------|
| Hindi → English | `Helsinki-NLP/opus-mt-hi-en` |
| English → Hindi | `Helsinki-NLP/opus-mt-en-hi` |
| Marathi → English | `Helsinki-NLP/opus-mt-mr-en` |
| English → Marathi | `Helsinki-NLP/opus-mt-en-mr` |
| Tamil → English | `Helsinki-NLP/opus-mt-ta-en` |
| English → Tamil | `Helsinki-NLP/opus-mt-en-ta` |
| Gujarati → English | `Helsinki-NLP/opus-mt-gu-en` |
| English → Gujarati | `Helsinki-NLP/opus-mt-en-gu` |

## Notebooks

### 1. Data Collection & Cleaning (`01_data_collection_cleaning.ipynb`)

Downloads and prepares training data from IIT Bombay, AI4Bharat Samanantar, and OPUS. No GPU needed.

**Run on:** Kaggle (CPU) or Colab (CPU)

### 2. MarianMT Training (`02_marianmt_training.ipynb`)

Fine-tunes MarianMT models. Supports checkpoint resume across sessions.

**Run on:** Kaggle (GPU P100/T4) or Colab (GPU T4)

> **Tip:** Train 1-2 language pairs per session. Change `PAIRS_THIS_SESSION` to pick which pairs to train.

### 3. Quantization & ONNX Export (`03_quantize_and_export.ipynb`)

Quantizes trained models to INT8, converts to ONNX, validates quality, and creates deployment ZIPs.

**Run on:** Kaggle or Colab (CPU is fine)

## How to Run

### On Kaggle

1. Create a new Kaggle Notebook
2. Upload `01_data_collection_cleaning.ipynb`
3. Click **Add Data** → Upload the notebook
4. For Notebook 2: **Settings → Accelerator → GPU P100**
5. Run all cells
6. Outputs save to `/kaggle/working/bhashalens_ml/`

### On Google Colab

1. Upload notebook to Google Drive
2. Open with Google Colab
3. For Notebook 2: **Runtime → Change runtime type → T4 GPU**
4. Run all cells — data saves to Google Drive automatically
5. Download model packages from the last cell

## Output Structure

```
bhashalens_ml/
├── data/
│   ├── raw/           # Downloaded datasets
│   ├── mixed/         # Mixed datasets
│   └── cleaned/       # Cleaned train/val/test splits
├── checkpoints/       # Training checkpoints (for resume)
├── models/
│   ├── trained/       # Fine-tuned PyTorch models
│   ├── quantized/     # INT8 quantized models
│   ├── onnx/          # ONNX converted models
│   └── packages/      # Final ZIP packages for Flutter app
│       ├── manifest.json
│       └── {lang_pair}/
│           └── model_package_{lang_pair}_v1.0.0.zip
└── reports/           # Cleaning and evaluation reports
```

## Importing into BhashaLens Flutter App

After training, download the ZIP packages from `models/packages/` and integrate with the Flutter app's model download system.

Each ZIP contains:
- `model.onnx` or `encoder_model.onnx` / `decoder_model.onnx`
- Tokenizer files (`tokenizer_config.json`, `source.spm`, etc.)
- `metadata.json` (BLEU scores, model info)
- `config.json` (inference parameters)
