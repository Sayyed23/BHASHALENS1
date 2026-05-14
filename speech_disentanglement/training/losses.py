"""Loss functions used across the 3 training stages."""

from __future__ import annotations

import math

import torch
import torch.nn as nn
import torch.nn.functional as F


class AAMSoftmax(nn.Module):
    """Additive Angular Margin softmax (a.k.a. ArcFace) for speaker classification.

    `logits` here are pre-normalized cosine similarities of shape (B, N).
    """

    def __init__(self, margin: float = 0.2, scale: float = 30.0) -> None:
        super().__init__()
        self.margin = margin
        self.scale = scale
        self._cos_m = math.cos(margin)
        self._sin_m = math.sin(margin)
        self._th = math.cos(math.pi - margin)
        self._mm = math.sin(math.pi - margin) * margin

    def forward(self, cos_sim: torch.Tensor, labels: torch.Tensor) -> torch.Tensor:
        sin = torch.sqrt(torch.clamp(1.0 - cos_sim * cos_sim, min=0.0, max=1.0))
        phi = cos_sim * self._cos_m - sin * self._sin_m
        phi = torch.where(cos_sim > self._th, phi, cos_sim - self._mm)
        one_hot = F.one_hot(labels, num_classes=cos_sim.size(-1)).to(cos_sim.dtype)
        output = (one_hot * phi) + ((1.0 - one_hot) * cos_sim)
        return F.cross_entropy(output * self.scale, labels)


class InfoNCE(nn.Module):
    """Symmetric InfoNCE for (audio, keyword-text) pairs."""

    def __init__(self, temperature: float = 0.07) -> None:
        super().__init__()
        self.temperature = temperature

    def forward(self, a: torch.Tensor, b: torch.Tensor) -> torch.Tensor:
        a = F.normalize(a, dim=-1)
        b = F.normalize(b, dim=-1)
        logits = a @ b.t() / self.temperature
        labels = torch.arange(a.size(0), device=a.device)
        return 0.5 * (F.cross_entropy(logits, labels) + F.cross_entropy(logits.t(), labels))
