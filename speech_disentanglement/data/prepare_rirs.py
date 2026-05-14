"""Index OpenSLR SLR28 (Aachen IR) impulse responses by source-mic distance.

Output: `rirs_index.json` mapping {distance_bin_m: [path, ...]} so the
`RIRConvolver` can sample by target distance.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# Aachen filenames embed distance, e.g. "office_II_3m_..." -> 3 m.
_DISTANCE_RE = re.compile(r"_(\d+(?:\.\d+)?)m_", re.IGNORECASE)

_DISTANCE_BINS = (0.5, 1.0, 2.0, 5.0)


def _bin(distance_m: float) -> float:
    return min(_DISTANCE_BINS, key=lambda b: abs(b - distance_m))


def build(root: Path, out_path: Path) -> None:
    index: dict[float, list[str]] = {b: [] for b in _DISTANCE_BINS}
    for wav in root.rglob("*.wav"):
        m = _DISTANCE_RE.search(wav.name)
        if not m:
            # Fall back to placing the RIR in the closest bin around 1 m.
            index[1.0].append(str(wav.resolve()))
            continue
        d = float(m.group(1))
        index[_bin(d)].append(str(wav.resolve()))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps({str(k): v for k, v in index.items()}, indent=2))
    summary = ", ".join(f"{k}m: {len(v)}" for k, v in index.items())
    print(f"rir index written ({summary})")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    build(args.root, args.out)


if __name__ == "__main__":
    main()
