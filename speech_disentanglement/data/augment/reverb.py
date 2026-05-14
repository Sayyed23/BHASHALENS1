"""Distance-aware reverberation via Room Impulse Response (RIR) convolution.

We bucket the OpenSLR SLR28 RIRs by source-to-mic distance metadata into
{0.5, 1, 2, 5} m bins and sample one per call. At training time the bin is
chosen uniformly so the model sees the full 0.5-5 m range.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

import torch
import torch.nn.functional as F


def _convolve_1d(wav: torch.Tensor, rir: torch.Tensor) -> torch.Tensor:
    """Causal 1-D convolution that preserves the input length."""
    wav = wav.view(1, 1, -1)
    rir = rir.view(1, 1, -1) / (rir.abs().sum() + 1e-9)
    pad = rir.shape[-1] - 1
    out = F.conv1d(F.pad(wav, (pad, 0)), rir)
    return out.view(-1)


def sample_rir_for_distance(
    rirs_by_distance: Mapping[float, Sequence[Path]],
    target_distance_m: float,
) -> Path:
    distances = sorted(rirs_by_distance.keys())
    closest = min(distances, key=lambda d: abs(d - target_distance_m))
    pool = rirs_by_distance[closest]
    idx = torch.randint(0, len(pool), (1,)).item()
    return pool[idx]


@dataclass
class RIRConvolver:
    rirs_by_distance: Mapping[float, Sequence[Path]]
    distance_choices: Sequence[float] = (0.5, 1.0, 2.0, 5.0)
    p: float = 0.7

    def __call__(self, wav: torch.Tensor) -> tuple[torch.Tensor, float | None]:
        if torch.rand(1).item() > self.p or not self.rirs_by_distance:
            return wav, None
        import soundfile as sf  # noqa: WPS433

        target_d = float(self.distance_choices[
            torch.randint(0, len(self.distance_choices), (1,)).item()
        ])
        rir_path = sample_rir_for_distance(self.rirs_by_distance, target_d)
        rir, _ = sf.read(str(rir_path), dtype="float32")
        rir_t = torch.from_numpy(rir)
        if rir_t.dim() > 1:
            rir_t = rir_t.mean(dim=-1)
        return _convolve_1d(wav, rir_t), target_d
