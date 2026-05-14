"""Joint Personal Voice Trigger (PVT) module.

Combines log-mel frontend + shared encoder + KWS head + speaker head into
one nn.Module suitable for end-to-end training, tracing, and quantization.
"""

from __future__ import annotations

from dataclasses import dataclass, field

import torch
import torch.nn as nn

from .encoder import EncoderConfig, StreamingEncoder
from .features import FeatureConfig, LogMelFrontend
from .kws_head import KWSHead, KWSHeadConfig
from .speaker_head import SpeakerHead, SpeakerHeadConfig


@dataclass
class PVTConfig:
    features: FeatureConfig = field(default_factory=FeatureConfig)
    encoder: EncoderConfig = field(default_factory=EncoderConfig)
    kws: KWSHeadConfig = field(default_factory=KWSHeadConfig)
    speaker: SpeakerHeadConfig = field(default_factory=SpeakerHeadConfig)


class PVT(nn.Module):
    """Joint speaker-conditioned custom-keyword detector."""

    def __init__(self, cfg: PVTConfig | None = None) -> None:
        super().__init__()
        self.cfg = cfg or PVTConfig()

        # Wire the dims together so the heads always see the right shapes.
        self.cfg.kws = KWSHeadConfig(
            audio_dim=self.cfg.encoder.output_dim,
            phoneme_vocab=self.cfg.kws.phoneme_vocab,
            phoneme_dim=self.cfg.kws.phoneme_dim,
            proj_dim=self.cfg.kws.proj_dim,
            num_heads=self.cfg.kws.num_heads,
        )
        self.cfg.speaker = SpeakerHeadConfig(
            in_dim=self.cfg.encoder.output_dim,
            hidden=self.cfg.speaker.hidden,
            emb_dim=self.cfg.speaker.emb_dim,
            num_speakers=self.cfg.speaker.num_speakers,
        )

        self.features = LogMelFrontend(self.cfg.features)
        self.encoder = StreamingEncoder(self.cfg.encoder)
        self.kws_head = KWSHead(self.cfg.kws)
        self.speaker_head = SpeakerHead(self.cfg.speaker)

    # ------------------------------------------------------------------ #
    def forward(
        self,
        wav: torch.Tensor,
        phoneme_ids: torch.Tensor,
        speaker_ids: torch.Tensor | None = None,
    ) -> dict[str, torch.Tensor]:
        feats = self.features(wav)             # (B, F, T')
        audio_emb = self.encoder(feats)        # (B, D, T')
        kws_score, kw_emb = self.kws_head(audio_emb, phoneme_ids)
        spk_out = self.speaker_head(audio_emb, speaker_ids)
        return {
            "kws_score": kws_score,
            "kw_emb": kw_emb,
            "spk_emb": spk_out["embedding"],
            **({"spk_logits": spk_out["logits"]} if "logits" in spk_out else {}),
        }

    @torch.no_grad()
    def embed(self, wav: torch.Tensor) -> torch.Tensor:
        """Encode a waveform into per-frame embeddings (used for streaming)."""
        return self.encoder(self.features(wav))
