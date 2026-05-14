"""Build manifests for VoxCeleb 1 + 2.

VoxCeleb layout (after extracting both datasets and converting to 16 kHz
mono WAV with the official script):

    <root>/
        wav/
            <speaker_id>/<video_id>/<clip>.wav
        iden_split.txt
        veri_test.txt          # for Vox1-O verification eval

We treat every utterance as a single speaker-labeled `Sample`. The
verification trials are written to a side file
`<out>/veri_trials.jsonl` for the evaluation harness.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import soundfile as sf

from .manifest import Sample, write_manifest


def _enumerate(root: Path) -> list[Sample]:
    samples = []
    for wav in (root / "wav").rglob("*.wav"):
        speaker_id = wav.parents[1].name
        try:
            info = sf.info(str(wav))
            dur = info.frames / info.samplerate
        except Exception:
            dur = 0.0
        samples.append(
            Sample(
                audio_path=str(wav.resolve()),
                duration_s=float(dur),
                text="",
                speaker_id=speaker_id,
                language="multi",
                sample_rate=16_000,
                extra={"video_id": wav.parent.name},
            )
        )
    return samples


def _split(samples: list[Sample], dev_speaker_ratio: float = 0.02) -> tuple[list[Sample], list[Sample]]:
    speakers = sorted({s.speaker_id for s in samples})
    n_dev = max(1, int(len(speakers) * dev_speaker_ratio))
    dev_speakers = set(speakers[:n_dev])
    dev, train = [], []
    for s in samples:
        (dev if s.speaker_id in dev_speakers else train).append(s)
    return train, dev


def _write_trials(root: Path, out_dir: Path) -> int:
    p = root / "veri_test.txt"
    if not p.exists():
        return 0
    out = out_dir / "veri_trials.jsonl"
    out.parent.mkdir(parents=True, exist_ok=True)
    n = 0
    with out.open("w", encoding="utf-8") as fh:
        for line in p.read_text().splitlines():
            parts = line.strip().split()
            if len(parts) != 3:
                continue
            label, a, b = parts
            fh.write(json.dumps({
                "label": int(label),
                "enrol_path": str((root / "wav" / a).resolve()),
                "test_path": str((root / "wav" / b).resolve()),
            }) + "\n")
            n += 1
    return n


def build(root: Path, out_dir: Path) -> None:
    samples = _enumerate(root)
    train, dev = _split(samples)
    n_train = write_manifest(out_dir / "train.jsonl", train)
    n_dev = write_manifest(out_dir / "dev.jsonl", dev)
    n_trials = _write_trials(root, out_dir)
    print(f"voxceleb: train={n_train}, dev={n_dev}, trials={n_trials}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    build(args.root, args.out)


if __name__ == "__main__":
    main()
