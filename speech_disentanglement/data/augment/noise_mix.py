"""SNR-controlled additive noise mixing.

Mixes a clean utterance with a randomly chosen noise clip at a target
SNR uniformly sampled from [snr_min, snr_max] (default Samsung range
[-5, 30] dB). Works on torch float waveforms at 16 kHz.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

import torch


def _rms(x: torch.Tensor) -> torch.Tensor:
    return torch.sqrt(torch.clamp((x ** 2).mean(), min=1e-12))


def mix_at_snr(clean: torch.Tensor, noise: torch.Tensor, snr_db: float) -> torch.Tensor:
    """Mix `clean` + `noise` so that the resulting SNR equals `snr_db`.

    Both tensors must be 1-D and at the same sample rate. If `noise` is shorter
    than `clean` it is tiled; if longer, a random crop is taken.
    """
    if noise.numel() < clean.numel():
        repeats = clean.numel() // noise.numel() + 1
        noise = noise.repeat(repeats)[: clean.numel()]
    else:
        offset = torch.randint(0, noise.numel() - clean.numel() + 1, (1,)).item()
        noise = noise[offset : offset + clean.numel()]

    clean_rms = _rms(clean)
    noise_rms = _rms(noise)
    target_noise_rms = clean_rms / (10 ** (snr_db / 20))
    scaled_noise = noise * (target_noise_rms / noise_rms)
    return clean + scaled_noise


@dataclass
class NoiseMixer:
    """Pick a random noise file from a pool and mix it into the clean signal.

    Parameters
    ----------
    noise_files:
        Paths to single-channel 16 kHz WAVs (MUSAN / DEMAND / WHAM).
    snr_min, snr_max:
        Bounds on the uniformly sampled SNR in dB.
    p:
        Probability of applying noise on a given call (so we keep clean copies).
    """

    noise_files: Sequence[Path]
    snr_min: float = -5.0
    snr_max: float = 30.0
    p: float = 0.8

    def __call__(self, wav: torch.Tensor) -> tuple[torch.Tensor, float | None]:
        if torch.rand(1).item() > self.p or not self.noise_files:
            return wav, None
        # Lazy-import soundfile so this module imports on minimal envs.
        import soundfile as sf  # noqa: WPS433

        path = self.noise_files[torch.randint(0, len(self.noise_files), (1,)).item()]
        noise, _ = sf.read(str(path), dtype="float32")
        noise_t = torch.from_numpy(noise)
        if noise_t.dim() > 1:
            noise_t = noise_t.mean(dim=-1)
        snr_db = float(torch.empty(1).uniform_(self.snr_min, self.snr_max).item())
        return mix_at_snr(wav, noise_t, snr_db), snr_db
