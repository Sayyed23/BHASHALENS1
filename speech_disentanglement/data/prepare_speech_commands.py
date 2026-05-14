"""Build a manifest for Google Speech Commands v2.

Usage:
    python -m speech_disentanglement.data.prepare_speech_commands \
        --root /path/to/speech_commands_v2 \
        --out  speech_disentanglement/data/manifests/speech_commands

We do NOT download the dataset here (it's 2.4 GB) -- call
`scripts/download_data.sh` first, or point `--root` at an existing copy.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from .manifest import Sample, write_manifest

_SPLIT_FILES = {
    "validation": "validation_list.txt",
    "test": "testing_list.txt",
}


def _load_split_index(root: Path) -> dict[str, str]:
    """Map each clip to a split using the official txt files."""
    split = {}
    for name, fname in _SPLIT_FILES.items():
        p = root / fname
        if not p.exists():
            continue
        for line in p.read_text().splitlines():
            line = line.strip()
            if line:
                split[line] = name
    return split


def build(root: Path, out_dir: Path) -> None:
    split_index = _load_split_index(root)
    train, dev, test = [], [], []
    for wav in sorted(root.rglob("*.wav")):
        rel = wav.relative_to(root).as_posix()
        keyword = wav.parent.name
        if keyword in {"_background_noise_", ""}:
            continue
        # Speech Commands clips are exactly 1 s nominally.
        sample = Sample(
            audio_path=str(wav.resolve()),
            duration_s=1.0,
            text=keyword,
            speaker_id=wav.stem.split("_nohash_")[0],
            language="en",
        )
        bucket = split_index.get(rel)
        if bucket == "validation":
            dev.append(sample)
        elif bucket == "test":
            test.append(sample)
        else:
            train.append(sample)
    n_train = write_manifest(out_dir / "train.jsonl", train)
    n_dev = write_manifest(out_dir / "dev.jsonl", dev)
    n_test = write_manifest(out_dir / "test.jsonl", test)
    print(f"speech_commands: train={n_train}, dev={n_dev}, test={n_test}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    build(args.root, args.out)


if __name__ == "__main__":
    main()
