"""3-shot enrollment CLI.

Reads three short recordings of the user saying the chosen keyword,
computes the mean speaker d-vector + mean keyword embedding, and writes
them to a single `.npz` file consumed by `streaming.py`.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import torch

from ..models import PVT
from .g2p import pad_phoneme_batch, text_to_phoneme_ids


def _load_wav(path: Path, target_sr: int = 16_000) -> torch.Tensor:
    import soundfile as sf  # noqa: WPS433

    wav, sr = sf.read(str(path), dtype="float32", always_2d=False)
    if wav.ndim > 1:
        wav = wav.mean(axis=-1)
    if sr != target_sr:
        raise SystemExit(f"{path}: expected {target_sr} Hz, got {sr} Hz")
    return torch.from_numpy(wav)


def enroll(
    model: PVT,
    recordings: list[Path],
    keyword: str,
) -> dict[str, np.ndarray]:
    if len(recordings) < 1:
        raise ValueError("need at least one enrollment recording")

    phoneme_ids = pad_phoneme_batch([text_to_phoneme_ids(keyword) for _ in recordings])
    phoneme_t = torch.tensor(phoneme_ids, dtype=torch.long)

    wavs = [_load_wav(p) for p in recordings]
    target_len = max(w.numel() for w in wavs)
    padded = torch.stack([torch.nn.functional.pad(w, (0, target_len - w.numel())) for w in wavs])

    model.eval()
    with torch.no_grad():
        out = model(padded, phoneme_t)

    kw_emb = out["kw_emb"].mean(dim=0).cpu().numpy()
    spk_emb = out["spk_emb"].mean(dim=0).cpu().numpy()

    return {
        "kw_emb": kw_emb.astype(np.float32),
        "spk_emb": spk_emb.astype(np.float32),
        "keyword": np.array(keyword, dtype=object),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--keyword", required=True, help="The custom word/phrase being enrolled")
    p.add_argument("--recordings", nargs="+", type=Path, required=True,
                   help="At least 3 mono 16 kHz WAVs of the user speaking the keyword")
    p.add_argument("--checkpoint", type=Path, default=None,
                   help="Optional PVT checkpoint to load; if omitted, uses random init "
                        "(for plumbing smoke tests only).")
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args(argv)

    model = PVT()
    if args.checkpoint is not None:
        state = torch.load(args.checkpoint, map_location="cpu")
        model.load_state_dict(state.get("model", state), strict=False)

    enrolled = enroll(model, args.recordings, args.keyword)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    np.savez(args.out, **enrolled)
    print(f"wrote enrollment to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
