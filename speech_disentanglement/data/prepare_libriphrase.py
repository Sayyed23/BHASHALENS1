"""Build a manifest for LibriPhrase (Easy + Hard).

LibriPhrase ships pre-computed phrase pairs derived from LibriSpeech;
each row gives an anchor utterance, a positive (different recording of
the same phrase by the same speaker), and a hard negative (phonetically
similar phrase). We map those into our flat `Sample` schema and record
the pairing in the `extra` dict so the joint training stage can build
contrastive batches.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from .manifest import Sample, write_manifest


def _load_pairs(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def build(root: Path, out_dir: Path) -> None:
    samples: list[Sample] = []
    for split in ("train", "dev", "test"):
        csv_path = root / f"libriphrase_{split}.csv"
        if not csv_path.exists():
            continue
        rows = _load_pairs(csv_path)
        per_split: list[Sample] = []
        for r in rows:
            per_split.append(
                Sample(
                    audio_path=str((root / r["anchor_path"]).resolve()),
                    duration_s=float(r.get("anchor_dur", 1.0)),
                    text=r.get("anchor_text", ""),
                    speaker_id=r.get("anchor_speaker", ""),
                    language="en",
                    extra={
                        "positive_path": r.get("positive_path", ""),
                        "negative_path": r.get("negative_path", ""),
                        "negative_text": r.get("negative_text", ""),
                        "pair_kind": r.get("kind", "easy"),
                    },
                )
            )
        n = write_manifest(out_dir / f"{split}.jsonl", per_split)
        print(f"libriphrase {split}: {n}")
        samples.extend(per_split)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    build(args.root, args.out)


if __name__ == "__main__":
    main()
