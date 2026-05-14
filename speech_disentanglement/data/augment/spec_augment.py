"""Lightweight SpecAugment (no time-warp) suitable for streaming KWS/SV."""

from __future__ import annotations

from dataclasses import dataclass

import torch


@dataclass
class SpecAugment:
    n_freq_masks: int = 2
    freq_mask_param: int = 8
    n_time_masks: int = 2
    time_mask_param: int = 20
    p: float = 0.8

    def __call__(self, mels: torch.Tensor) -> torch.Tensor:
        if torch.rand(1).item() > self.p:
            return mels
        n_mels, t = mels.shape[-2], mels.shape[-1]
        out = mels.clone()
        for _ in range(self.n_freq_masks):
            f = int(torch.randint(0, self.freq_mask_param + 1, (1,)).item())
            f0 = int(torch.randint(0, max(1, n_mels - f), (1,)).item())
            out[..., f0 : f0 + f, :] = 0.0
        for _ in range(self.n_time_masks):
            tt = int(torch.randint(0, self.time_mask_param + 1, (1,)).item())
            t0 = int(torch.randint(0, max(1, t - tt), (1,)).item())
            out[..., :, t0 : t0 + tt] = 0.0
        return out
