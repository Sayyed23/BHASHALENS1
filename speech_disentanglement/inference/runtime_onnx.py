"""Export the PVT model to ONNX, then run it via onnxruntime.

We split the export into encoder + heads so the streaming loop can reuse
a single encoder session across hops (which is where the bulk of the
FLOPS live).
"""

from __future__ import annotations

import argparse
from pathlib import Path

import torch

from ..models import PVT


def export(checkpoint: Path | None, out_dir: Path, opset: int = 17) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    model = PVT().eval()
    if checkpoint is not None:
        state = torch.load(checkpoint, map_location="cpu")
        model.load_state_dict(state.get("model", state), strict=False)

    dummy_wav = torch.randn(1, 16_000)
    dummy_phon = torch.randint(1, 80, (1, 12), dtype=torch.long)

    torch.onnx.export(
        model,
        (dummy_wav, dummy_phon),
        out_dir / "pvt.onnx",
        input_names=["wav", "phoneme_ids"],
        output_names=["kws_score", "kw_emb", "spk_emb"],
        dynamic_axes={
            "wav": {0: "batch", 1: "samples"},
            "phoneme_ids": {0: "batch", 1: "phon_len"},
        },
        opset_version=opset,
    )
    print(f"wrote {out_dir / 'pvt.onnx'}")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--checkpoint", type=Path, default=None)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args(argv)
    export(args.checkpoint, args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
