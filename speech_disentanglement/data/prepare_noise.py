"""Aggregate noise sources (MUSAN, DEMAND, WHAM!) into a single pool manifest.

Output JSONL rows carry the noise class in `extra.noise_class` so we can
balance the mixer (Samsung asks for crowd, babble, traffic).
"""

from __future__ import annotations

import argparse
from pathlib import Path

import soundfile as sf

from .manifest import Sample, write_manifest

_MUSAN_CLASS_MAP = {
    "speech": "babble",
    "noise": "noise",
    "music": "music",
}


def _ingest_musan(root: Path) -> list[Sample]:
    out = []
    for wav in (root / "musan").rglob("*.wav") if (root / "musan").exists() else []:
        top = wav.relative_to(root / "musan").parts[0]
        noise_class = _MUSAN_CLASS_MAP.get(top, top)
        info = sf.info(str(wav))
        out.append(
            Sample(
                audio_path=str(wav.resolve()),
                duration_s=info.frames / info.samplerate,
                text="",
                speaker_id="",
                language="multi",
                extra={"noise_class": noise_class, "source": "musan"},
            )
        )
    return out


def _ingest_demand(root: Path) -> list[Sample]:
    out = []
    base = root / "DEMAND"
    if not base.exists():
        return out
    for wav in base.rglob("*.wav"):
        env = wav.parent.name  # e.g. STRAFFIC, PCAFETER
        noise_class = "traffic" if "TRAFFIC" in env else "babble" if "CAF" in env else "noise"
        info = sf.info(str(wav))
        out.append(
            Sample(
                audio_path=str(wav.resolve()),
                duration_s=info.frames / info.samplerate,
                text="",
                speaker_id="",
                language="multi",
                extra={"noise_class": noise_class, "source": "demand", "env": env},
            )
        )
    return out


def build(root: Path, out_dir: Path) -> None:
    pool = _ingest_musan(root) + _ingest_demand(root)
    n = write_manifest(out_dir / "noise_pool.jsonl", pool)
    print(f"noise pool: {n}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    build(args.root, args.out)


if __name__ == "__main__":
    main()
