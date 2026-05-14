"""JSONL manifest schema shared across all dataset prep scripts.

Every dataset prepare script writes a sequence of `Sample` rows to a JSONL
file under `data/manifests/<dataset>/{train,dev,test}.jsonl`. The training
and evaluation pipelines consume only this schema, so adding a new dataset
is "write a new `prepare_*.py`" + nothing else.
"""

from __future__ import annotations

import json
from collections.abc import Iterable, Iterator
from dataclasses import asdict, dataclass, field
from pathlib import Path


@dataclass
class Sample:
    audio_path: str
    duration_s: float
    text: str = ""                       # transcript or keyword string
    speaker_id: str = ""                 # opaque string id, "" if not known
    language: str = "en"
    sample_rate: int = 16_000
    extra: dict = field(default_factory=dict)


def write_manifest(path: Path, samples: Iterable[Sample]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    n = 0
    with path.open("w", encoding="utf-8") as fh:
        for s in samples:
            fh.write(json.dumps(asdict(s), ensure_ascii=False) + "\n")
            n += 1
    return n


def read_manifest(path: Path) -> Iterator[Sample]:
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            yield Sample(**row)
