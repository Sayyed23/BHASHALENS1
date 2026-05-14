"""Stage 2: open-vocabulary KWS pretraining (LibriPhrase + Speech Commands)."""

from __future__ import annotations

import argparse
from pathlib import Path

import torch
import yaml

from ..models import PVT, count_params
from .losses import InfoNCE


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

    model = PVT()
    print(f"PVT params: {count_params(model):,}")

    if args.smoke:
        wav = torch.randn(4, 16_000)
        phoneme_ids = torch.randint(1, 80, (4, 12))
        out = model(wav, phoneme_ids)
        # Treat (kw_emb, kw_emb_shuffled) as a tiny contrastive batch.
        shuffled = out["kw_emb"][torch.randperm(4)]
        loss = InfoNCE()(out["kw_emb"], shuffled)
        loss.backward()
        print(f"smoke loss: {loss.item():.4f}")
        return 0

    raise SystemExit(
        "Full training loop intentionally not committed in the scaffold."
    )


if __name__ == "__main__":
    raise SystemExit(main())
