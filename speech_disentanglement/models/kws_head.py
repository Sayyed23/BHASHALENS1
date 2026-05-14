"""KWS head: audio-embedding x phoneme-embedding cross-attention.

Open-vocabulary by construction: the user-defined keyword is converted to
a phoneme sequence at enrollment time (using `g2p_en`, `g2p-hi`, etc.) and
embedded with the small phoneme table below; the audio side comes from the
shared encoder. The head outputs a scalar similarity score plus an audio
"keyword embedding" we cache during enrollment.
"""

from __future__ import annotations

from dataclasses import dataclass

import torch
import torch.nn as nn
import torch.nn.functional as F


@dataclass(frozen=True)
class KWSHeadConfig:
    audio_dim: int = 192        # must match StreamingEncoder.output_dim
    phoneme_vocab: int = 80     # IPA-ish vocab; padded later
    phoneme_dim: int = 64
    proj_dim: int = 128
    num_heads: int = 2


class KWSHead(nn.Module):
    """Audio<->phoneme cross-attention KWS head.

    Forward modes:
        forward(audio_emb, phoneme_ids) -> (score, audio_kw_embedding)

    audio_emb:    (B, audio_dim, T)
    phoneme_ids:  (B, L) long
    """

    def __init__(self, cfg: KWSHeadConfig | None = None) -> None:
        super().__init__()
        self.cfg = cfg or KWSHeadConfig()

        self.phoneme_embed = nn.Embedding(self.cfg.phoneme_vocab, self.cfg.phoneme_dim, padding_idx=0)
        self.phoneme_proj = nn.Linear(self.cfg.phoneme_dim, self.cfg.proj_dim)
        self.audio_proj = nn.Conv1d(self.cfg.audio_dim, self.cfg.proj_dim, kernel_size=1)

        self.attn = nn.MultiheadAttention(
            embed_dim=self.cfg.proj_dim,
            num_heads=self.cfg.num_heads,
            batch_first=True,
        )
        self.norm = nn.LayerNorm(self.cfg.proj_dim)
        self.scorer = nn.Linear(self.cfg.proj_dim, 1)

    # ------------------------------------------------------------------ #
    def encode_phonemes(self, phoneme_ids: torch.Tensor) -> torch.Tensor:
        """Phoneme embedding -> projected representation (B, L, proj_dim)."""
        e = self.phoneme_embed(phoneme_ids)
        return self.phoneme_proj(e)

    def encode_audio(self, audio_emb: torch.Tensor) -> torch.Tensor:
        """Audio (B, C, T) -> (B, T, proj_dim)."""
        return self.audio_proj(audio_emb).transpose(1, 2)

    def forward(
        self,
        audio_emb: torch.Tensor,
        phoneme_ids: torch.Tensor,
    ) -> tuple[torch.Tensor, torch.Tensor]:
        a = self.encode_audio(audio_emb)               # (B, T, D)
        p = self.encode_phonemes(phoneme_ids)          # (B, L, D)
        # Use phoneme tokens as queries; let them gather acoustic evidence.
        attended, _ = self.attn(query=p, key=a, value=a, need_weights=False)
        attended = self.norm(attended)
        # Pool phoneme dimension -> (B, D)
        kw_emb = attended.mean(dim=1)
        score = self.scorer(kw_emb).squeeze(-1)        # (B,)
        return score, kw_emb

    @staticmethod
    def cosine(a: torch.Tensor, b: torch.Tensor, eps: float = 1e-8) -> torch.Tensor:
        return F.cosine_similarity(a, b, dim=-1, eps=eps)
