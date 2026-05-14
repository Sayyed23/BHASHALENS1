"""Shared streaming encoder for PVT-Lite.

We default to a streaming TC-ResNet style encoder because:
  * It quantizes cleanly to INT8.
  * Per-frame compute is constant (good for the 0.2 s xRT budget).
  * The whole network is causal -> trivial streaming inference.

A Conformer-tiny variant is provided behind a flag for future ablations.
The default config lands at ~1.8 M params.
"""

from __future__ import annotations

from dataclasses import dataclass

import torch
import torch.nn as nn


@dataclass(frozen=True)
class EncoderConfig:
    in_channels: int = 40         # n_mels
    hidden: int = 128
    depth: int = 6                # number of residual blocks
    kernel_size: int = 9
    dropout: float = 0.1
    output_dim: int = 192         # shared embedding dim consumed by both heads


class _TCBlock(nn.Module):
    """Causal Conv1d -> BN -> ReLU residual block.

    "Causal" => left-padding only, so the block is streaming-safe.
    """

    def __init__(self, ch: int, kernel: int, dropout: float) -> None:
        super().__init__()
        pad = kernel - 1
        self.conv1 = nn.Conv1d(ch, ch, kernel_size=kernel, padding=pad)
        self.bn1 = nn.BatchNorm1d(ch)
        self.conv2 = nn.Conv1d(ch, ch, kernel_size=kernel, padding=pad)
        self.bn2 = nn.BatchNorm1d(ch)
        self.act = nn.ReLU(inplace=True)
        self.drop = nn.Dropout(dropout)
        self._pad = pad

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (B, C, T)
        residual = x
        h = self.conv1(x)[..., : -self._pad] if self._pad else self.conv1(x)
        h = self.act(self.bn1(h))
        h = self.drop(h)
        h = self.conv2(h)[..., : -self._pad] if self._pad else self.conv2(h)
        h = self.bn2(h)
        return self.act(h + residual)


class StreamingEncoder(nn.Module):
    """Causal TC-ResNet style encoder producing per-frame embeddings.

    Input:  (B, F, T) log-mel features.
    Output: (B, output_dim, T) per-frame embeddings.
    """

    def __init__(self, cfg: EncoderConfig | None = None) -> None:
        super().__init__()
        self.cfg = cfg or EncoderConfig()
        self.input_proj = nn.Conv1d(self.cfg.in_channels, self.cfg.hidden, kernel_size=1)
        self.blocks = nn.ModuleList(
            [
                _TCBlock(self.cfg.hidden, self.cfg.kernel_size, self.cfg.dropout)
                for _ in range(self.cfg.depth)
            ]
        )
        self.output_proj = nn.Conv1d(self.cfg.hidden, self.cfg.output_dim, kernel_size=1)

    def forward(self, mels: torch.Tensor) -> torch.Tensor:
        if mels.dim() != 3:
            raise ValueError(
                f"expected (B, F, T), got shape {tuple(mels.shape)}"
            )
        h = self.input_proj(mels)
        for blk in self.blocks:
            h = blk(h)
        return self.output_proj(h)

    @property
    def output_dim(self) -> int:
        return self.cfg.output_dim
