"""Stage 3: joint multi-task fine-tune with hard negatives + noise + RIRs."""

from __future__ import annotations

import argparse
from pathlib import Path

import torch
import yaml

from ..models import PVT, PVTConfig, count_params
from ..models.speaker_head import SpeakerHeadConfig
from .losses import AAMSoftmax, InfoNCE


def _load_config(path: Path) -> dict:
    with path.open() as fh:
        return yaml.safe_load(fh)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--config", type=Path, required=True)
    p.add_argument("--smoke", action="store_true")
    args = p.parse_args(argv)

    cfg = _load_config(args.config)
    torch.manual_seed(int(cfg.get("seed", 0)))

    num_speakers = int(cfg.get("num_speakers", 128 if args.smoke else 7_205))
    pvt_cfg = PVTConfig(speaker=SpeakerHeadConfig(num_speakers=num_speakers))
    model = PVT(pvt_cfg)
    print(f"PVT params (with {num_speakers} AAM classes): {count_params(model):,}")
    alpha = float(cfg.get("alpha_kws", 1.0))
    beta = float(cfg.get("beta_spk", 1.0))
    gamma = float(cfg.get("gamma_contrast", 0.3))

    if args.smoke:
        wav = torch.randn(4, 16_000)
        phoneme_ids = torch.randint(1, 80, (4, 12))
        speaker_ids = torch.randint(0, num_speakers, (4,))
        out = model(wav, phoneme_ids, speaker_ids)
        kws_target = torch.tensor([1.0, 1.0, 0.0, 0.0])  # synthetic
        l_kws = torch.nn.functional.binary_cross_entropy_with_logits(
            out["kws_score"], kws_target
        )
        l_spk = AAMSoftmax()(out["spk_logits"], speaker_ids)
        shuffled = out["kw_emb"][torch.randperm(4)]
        l_ct = InfoNCE()(out["kw_emb"], shuffled)
        loss = alpha * l_kws + beta * l_spk + gamma * l_ct
        loss.backward()
        print(
            f"smoke joint: total={loss.item():.4f} "
            f"kws={l_kws.item():.4f} spk={l_spk.item():.4f} ct={l_ct.item():.4f}"
        )
        return 0

    raise SystemExit(
        "Full training loop intentionally not committed in the scaffold."
    )


if __name__ == "__main__":
    raise SystemExit(main())
