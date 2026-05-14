"""ECAPA-mini speaker embedding head.

Stripped-down ECAPA-TDNN: no SE blocks, channels=128, single
multi-scale-feature-aggregation (MSFA) path, attentive statistics
pooling -> 192-d d-vector. AAM-softmax classifier head is trainable but
discarded at inference time (we keep only the embedding).
"""

from __future__ import annotations

from dataclasses import dataclass

import torch
import torch.nn as nn
import torch.nn.functional as F


@dataclass(frozen=True)
class SpeakerHeadConfig:
    in_dim: int = 192          # StreamingEncoder.output_dim
    hidden: int = 128
    emb_dim: int = 192
    # 0 = no AAM-softmax classifier (inference-only build, default).
    # Training scripts override this with the speaker count of the train split
    # (e.g. 7_205 for VoxCeleb 1+2 dev). The classifier weight is discarded at
    # inference, so it does not count against the Samsung 3 M param budget.
    num_speakers: int = 0


class _AttentiveStatsPool(nn.Module):
    def __init__(self, dim: int) -> None:
        super().__init__()
        self.attn = nn.Sequential(
            nn.Conv1d(dim, dim, kernel_size=1),
            nn.ReLU(inplace=True),
            nn.Conv1d(dim, dim, kernel_size=1),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (B, D, T) -> (B, 2*D)
        alpha = torch.softmax(self.attn(x), dim=-1)
        mu = (alpha * x).sum(dim=-1)
        sigma = ((alpha * (x - mu.unsqueeze(-1)) ** 2).sum(dim=-1) + 1e-9).sqrt()
        return torch.cat([mu, sigma], dim=-1)


class SpeakerHead(nn.Module):
    """ECAPA-mini speaker embedding head."""

    def __init__(self, cfg: SpeakerHeadConfig | None = None) -> None:
        super().__init__()
        self.cfg = cfg or SpeakerHeadConfig()
        self.proj = nn.Conv1d(self.cfg.in_dim, self.cfg.hidden, kernel_size=1)
        self.bn = nn.BatchNorm1d(self.cfg.hidden)
        self.pool = _AttentiveStatsPool(self.cfg.hidden)
        self.fc1 = nn.Linear(self.cfg.hidden * 2, self.cfg.emb_dim)
        self.bn1 = nn.BatchNorm1d(self.cfg.emb_dim)
        # AAM-softmax classifier weights — only allocated during training.
        # The classifier is discarded before quantization / export, so it is
        # *not* present in the inference graph and does not count toward the
        # Samsung < 3 M parameter budget.
        if self.cfg.num_speakers > 0:
            self.classifier_weight = nn.Parameter(
                torch.randn(self.cfg.num_speakers, self.cfg.emb_dim)
            )
            nn.init.xavier_uniform_(self.classifier_weight)
        else:
            self.register_parameter("classifier_weight", None)

    def forward(
        self,
        audio_emb: torch.Tensor,
        speaker_ids: torch.Tensor | None = None,
    ) -> dict[str, torch.Tensor]:
        h = self.bn(F.relu(self.proj(audio_emb)))
        pooled = self.pool(h)                       # (B, 2*hidden)
        emb = self.bn1(self.fc1(pooled))            # (B, emb_dim)
        out: dict[str, torch.Tensor] = {"embedding": emb}
        if speaker_ids is not None and self.classifier_weight is not None:
            cos = F.linear(F.normalize(emb), F.normalize(self.classifier_weight))
            out["logits"] = cos
        return out

    @staticmethod
    def cosine(a: torch.Tensor, b: torch.Tensor, eps: float = 1e-8) -> torch.Tensor:
        return F.cosine_similarity(a, b, dim=-1, eps=eps)
