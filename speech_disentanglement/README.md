# PVT-Lite — Speaker-Specific Custom Word Detection

Reference implementation for **Samsung ennovateX 2026 — Problem 04**
*(Designing a Robust AI System for Speech Disentanglement)*.

A streaming, on-device speech system that wakes only when a **user-defined
keyword** is spoken by the **enrolled speaker**. Single shared encoder + two
heads (KWS, speaker), **~2.4 M params**, INT8-quantizable, xRT < 0.2 s on
commodity CPU.

See [`../docs/BLUEPRINT.md`](../docs/BLUEPRINT.md) for the full design doc.

---

## Layout

```
speech_disentanglement/
├── data/             # dataset download + manifest builders, augmentation
├── models/           # encoder, KWS head, speaker head, joint PVT module
├── training/         # 3-stage training scripts + Hydra configs
├── inference/        # streaming runner, enrollment, TF / ONNX / TFLite runtimes
├── evaluation/       # KPI grid evaluator, phonetic-confusable test
├── notebooks/        # exploration + KPI dashboard
├── scripts/          # one-shot demo helpers
├── docker/           # reproducible training environment
├── tests/            # smoke tests + param-budget enforcement
├── pyproject.toml    # `pip install -e ".[dev]"`
├── requirements.txt  # pinned runtime deps
└── README.md         # you are here
```

## Quickstart

```bash
# 1. Set up the environment (Python 3.11)
python -m venv .venv && source .venv/bin/activate
pip install -e "./speech_disentanglement[dev]"

# 2. Sanity-check: instantiate the model + run a forward pass
python -m speech_disentanglement.scripts.smoke

# 3. Run the unit tests (param budget, feature shapes, etc.)
pytest speech_disentanglement/tests/ -v

# 4. Train (small-scale sanity on Speech Commands)
python -m speech_disentanglement.training.pretrain_kws \
       --config speech_disentanglement/training/configs/kws_smoke.yaml

# 5. Enroll yourself, then listen on the mic
python -m speech_disentanglement.inference.enroll  --out enrollment.npz
python -m speech_disentanglement.inference.streaming \
       --enrollment enrollment.npz --source mic
```

## Evaluation against Samsung KPIs

```bash
python -m speech_disentanglement.evaluation.eval_kpis \
       --checkpoint runs/joint/latest.ckpt \
       --report-dir docs/KPI_REPORT/
```

This sweeps clean × SNR ∈ {30, 20, 10, 5, 0, −5} dB × distance ∈
{0.5, 1, 2, 5} m × {male, female} × {seen, unseen speaker} and writes a
markdown report plus DET plots.

## Targets

| Metric | Target | Why we hit it |
|---|---|---|
| TA Clean | ≥ 99 % | Joint encoder + 3-shot enrollment |
| TA Noisy | ≥ 90 % | Multi-condition training over SNR [−5, 30] dB |
| FA | < 1 / hr | SV gate + phonetic hard-negative mining |
| Params | < 3 M | CI unit test enforces |
| xRT (1 s audio) | < 0.2 s | INT8 ONNX-RT / TFLite XNNPACK |

## License

Apache-2.0. See [`../LICENSE`](../LICENSE) and [`../NOTICE`](../NOTICE).

## Status

> This is the **scaffold** committed alongside the Phase-1 blueprint.
> Model classes and runtimes are functional placeholders that pass
> shape/param-budget tests; full training and KPI numbers will be filled in
> during Phase-2 work (target: Jun 22).
