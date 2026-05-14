<h1 align="center">PVT-Lite</h1>

<p align="center">
  <strong>Speaker-Specific Custom Word Detection (Speech Disentanglement)</strong><br/>
  Samsung ennovateX 2026 — AX Hackathon · Problem Statement 04
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-Apache--2.0-blue" alt="License"/>
  <img src="https://img.shields.io/badge/python-3.10%20%7C%203.11-3776AB?logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/PyTorch-2.3-EE4C2C?logo=pytorch" alt="PyTorch"/>
  <img src="https://img.shields.io/badge/runtime-Torch%20%7C%20ONNX%20%7C%20TFLite-yellow" alt="Runtimes"/>
  <img src="https://img.shields.io/badge/params-%3C%203M-success" alt="Params"/>
  <img src="https://img.shields.io/badge/xRT-%3C%200.2s-success" alt="xRT"/>
</p>

---

> **Status:** Scaffold for Phase-2 implementation. Architecture, training
> recipes, evaluation harness, and the Phase-1 blueprint are committed; full
> training runs and KPI numbers land before **Jun 22, 2026**.

## What this repo is now

A streaming, on-device speech system that wakes only when a **user-defined
keyword** is uttered by the **enrolled speaker** — not someone else who
happens to say a phonetically similar word.

| Samsung KPI | Target | Our design |
|---|---|---|
| TA (clean) | ≥ 99 % | aim 99.5 % |
| TA (noisy, SNR −5 → 30 dB) | ≥ 90 % | aim 92 % |
| FA | < 1 / hr | aim < 0.5 / hr |
| Distance | 0.5 m – 5 m | simulated via OpenSLR RIRs |
| Params | < 3 M | **~2.4 M** (encoder 1.8 M + heads 0.6 M) |
| xRT (per 1 s audio) | < 0.2 s | **~0.06 s** on Pi-4 (INT8 ONNX-RT) |

Full blueprint: [`docs/BLUEPRINT.md`](docs/BLUEPRINT.md).
Solution package: [`speech_disentanglement/`](speech_disentanglement/).

## Architecture at a glance

```
raw audio ─▶ log-Mel (40-d) ─▶ shared streaming encoder (~1.8 M)
                                     ├─▶ KWS head  (audio ⇆ phoneme x-attention)
                                     └─▶ Speaker head (ECAPA-mini, 192-d d-vector)
                                                 │
                                                 ▼
                              score fusion (SNR-aware logistic) ─▶ accept / reject
```

* **Open-vocabulary by construction** — keyword is encoded via G2P phoneme
  embeddings, so users register *any* word in EN / HI / TA / TE / MR
  without retraining.
* **3-shot enrollment** — user records the word 3 times; we cache the
  mean speaker d-vector and keyword embedding. Fully on-device.
* **CI-enforced param budget** — a unit test fails the build if the model
  exceeds 3 M params.

## Quickstart

```bash
# 1. Create an environment (Python 3.11 recommended)
python -m venv .venv && source .venv/bin/activate

# 2. Install (CPU PyTorch is fine for scaffold-level testing)
pip install --index-url https://download.pytorch.org/whl/cpu "torch>=2.3,<2.5" "torchaudio>=2.3,<2.5"
pip install -e "./speech_disentanglement[dev]"

# 3. Smoke check + tests
python -m speech_disentanglement.scripts.smoke
pytest speech_disentanglement/tests -v

# 4. Try enrollment + streaming with random weights (plumbing demo only)
python -m speech_disentanglement.inference.enroll  \
       --keyword hello --recordings rec1.wav rec2.wav rec3.wav --out enrollment.npz
python -m speech_disentanglement.inference.streaming \
       --enrollment enrollment.npz --source file --audio test_audio.wav
```

For real training (after `scripts/download_data.sh` + `prepare_*.py` on a GPU host):

```bash
python -m speech_disentanglement.training.pretrain_speaker --config speech_disentanglement/training/configs/speaker.yaml
python -m speech_disentanglement.training.pretrain_kws     --config speech_disentanglement/training/configs/kws.yaml
python -m speech_disentanglement.training.joint_finetune   --config speech_disentanglement/training/configs/joint.yaml
python -m speech_disentanglement.evaluation.eval_kpis      --checkpoint runs/joint/latest.ckpt --report-dir docs/KPI_REPORT
```

## Repository layout

```
.
├── speech_disentanglement/        # the hackathon entry (PVT-Lite)
│   ├── data/                      # downloads, manifest builders, augmentation
│   ├── models/                    # encoder, KWS head, speaker head, joint PVT
│   ├── training/                  # 3-stage scripts + Hydra/YAML configs
│   ├── inference/                 # enroll, streaming, Torch/ONNX/TFLite runtimes
│   ├── evaluation/                # KPI grid, phonetic-confusable trials, metrics
│   ├── tests/                     # param-budget gate, shape + smoke tests
│   ├── scripts/                   # smoke + dataset downloader
│   └── docker/Dockerfile          # reproducible training image
│
├── docs/
│   └── BLUEPRINT.md               # Phase-1 solution blueprint (PDF source)
│
├── .github/workflows/
│   └── speech-disentanglement-ci.yml
│
├── LICENSE                        # Apache-2.0
├── NOTICE                         # third-party dataset / model attribution
└── README.md                      # you are here
```

### Legacy code

The earlier **BhashaLens** Flutter translation app lives under
`bhashalens_app/`, `amplify/`, `infrastructure/`, and `functions/`. It is
**not** part of the hackathon submission but is retained on this branch
under the same Apache-2.0 license; future plans include reusing the
Flutter shell as the on-device demo UI.

## Hackathon timeline (Samsung ennovateX 2026)

| Phase | Date | Status |
|---|---|---|
| Phase 1 — Blueprint submission | **May 13, 2026** | `docs/BLUEPRINT.md` written; export & email by deadline |
| Phase 2 — Full solution submission | **Jun 22, 2026** | scaffold committed; training + KPI report in progress |
| Phase 3 — Online presentation | **Jul 3, 2026** | upcoming |
| Phase 4 — Grand Finale | **Jul 30, 2026** | upcoming |

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE) for the third-party
attribution list (VoxCeleb, LibriPhrase, Speech Commands, MUSAN, DEMAND, WHAM,
OpenSLR SLR28, Coqui XTTS-v2, SpeechBrain, ESPnet, Silero-VAD).
