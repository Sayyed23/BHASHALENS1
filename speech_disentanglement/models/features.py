"""Log-Mel front-end with per-utterance CMVN.

Pure torchaudio so it can be traced to ONNX / TFLite. No trainable params,
so this module does not count against the 3 M-param budget.
"""

from __future__ import annotations

from dataclasses import dataclass

import torch
import torch.nn as nn


@dataclass(frozen=True)
class FeatureConfig:
    sample_rate: int = 16_000
    n_fft: int = 400          # 25 ms @ 16 kHz
    hop_length: int = 160     # 10 ms @ 16 kHz
    n_mels: int = 40
    f_min: float = 20.0
    f_max: float = 7_600.0
    log_floor: float = 1e-6


class LogMelFrontend(nn.Module):
    """Compute a 40-d log-mel spectrogram with CMVN.

    Input:  (B, T) raw waveform at 16 kHz, float in [-1, 1].
    Output: (B, F, T') where F == n_mels and T' == T // hop_length + 1.
    """

    def __init__(self, cfg: FeatureConfig | None = None) -> None:
        super().__init__()
        self.cfg = cfg or FeatureConfig()
        # We import torchaudio lazily so the model package imports cleanly in
        # environments that only need shape/param info (e.g. the CI smoke
        # tests on a minimal install).
        import torchaudio.transforms as T  # noqa: WPS433 (intentional)

        self.melspec = T.MelSpectrogram(
            sample_rate=self.cfg.sample_rate,
            n_fft=self.cfg.n_fft,
            hop_length=self.cfg.hop_length,
            n_mels=self.cfg.n_mels,
            f_min=self.cfg.f_min,
            f_max=self.cfg.f_max,
            power=2.0,
            center=True,
        )

    def forward(self, wav: torch.Tensor) -> torch.Tensor:
        if wav.dim() == 1:
            wav = wav.unsqueeze(0)
        spec = self.melspec(wav)                       # (B, n_mels, T')
        spec = torch.log(spec + self.cfg.log_floor)    # (B, n_mels, T')
        # Per-utterance CMVN over the time axis.
        mean = spec.mean(dim=-1, keepdim=True)
        std = spec.std(dim=-1, keepdim=True).clamp_min(1e-5)
        return (spec - mean) / std

    @property
    def n_mels(self) -> int:
        return self.cfg.n_mels
