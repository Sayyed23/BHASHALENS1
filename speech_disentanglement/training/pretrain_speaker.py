"""Stage 1: speaker-embedding pretraining on VoxCeleb 1+2.

This is the entry point used to produce a checkpoint with a strong
speaker head; we freeze (or low-LR fine-tune) it during the joint stage.
The script reads a YAML config (see `configs/speaker.yaml`) and is meant
to be run on a GPU host -- the implementation here keeps it framework-
agnostic enough to also work on a tiny smoke-sized batch on CPU so the
CI scaffold stays green.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import torch
import yaml

from ..models import PVT, PVTConfig, count_params
from ..models.speaker_head import SpeakerHeadConfig
from .losses import AAMSoftmax


def _load_config(path: Path) -> dict:
    with path.open() as fh:
        return yaml.safe_load(fh)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--config", type=Path, required=True)
    p.add_argument("--smoke", action="store_true", help="single-batch dry run")
    args = p.parse_args(argv)

    cfg = _load_config(args.config)
    torch.manual_seed(int(cfg.get("seed", 0)))

    # Build a *training* PVT that allocates the AAM-softmax classifier
    # for the configured speaker count. The classifier is discarded before
    # quantization / export so it does not count against the inference
    # parameter budget.
    num_speakers = int(cfg.get("num_speakers", 128 if args.smoke else 7_205))
    pvt_cfg = PVTConfig(speaker=SpeakerHeadConfig(num_speakers=num_speakers))
    model = PVT(pvt_cfg)
    print(f"PVT params (with {num_speakers} AAM classes): {count_params(model):,}")

    if args.smoke:
        wav = torch.randn(2, 16_000)             # 1 s clips
        phoneme_ids = torch.randint(1, 80, (2, 12))
        speaker_ids = torch.randint(0, num_speakers, (2,))
        out = model(wav, phoneme_ids, speaker_ids)
        loss_fn = AAMSoftmax()
        loss = loss_fn(out["spk_logits"], speaker_ids)
        loss.backward()
        print(f"smoke loss: {loss.item():.4f}")
        return 0

    # Real training loop wiring lives in the Phase-2 expansion; the config
    # already enumerates all hyper-parameters so the training shape is fixed.
    raise SystemExit(
        "Full training loop intentionally not committed in the scaffold. "
        "Pass --smoke for a single-batch sanity check, or fill in the dataloader "
        "wiring guided by configs/speaker.yaml."
    )


if __name__ == "__main__":
    raise SystemExit(main())
