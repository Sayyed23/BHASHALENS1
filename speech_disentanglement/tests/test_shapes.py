"""Validate forward-pass shapes for every public model component."""

from __future__ import annotations

import torch

from speech_disentanglement.models import (
    PVT,
    KWSHead,
    LogMelFrontend,
    SpeakerHead,
    StreamingEncoder,
)
from speech_disentanglement.models.speaker_head import SpeakerHeadConfig


def test_logmel_shape() -> None:
    fe = LogMelFrontend()
    wav = torch.randn(2, 16_000)         # 1 s @ 16 kHz
    feats = fe(wav)
    assert feats.dim() == 3
    assert feats.shape[0] == 2
    assert feats.shape[1] == fe.n_mels
    # T' = T / hop + 1 (with center=True padding); just sanity-check it grew.
    assert feats.shape[2] >= 80


def test_encoder_shape() -> None:
    enc = StreamingEncoder()
    feats = torch.randn(2, 40, 100)
    out = enc(feats)
    assert out.shape == (2, enc.output_dim, 100)


def test_kws_head_shapes() -> None:
    head = KWSHead()
    audio = torch.randn(2, 192, 100)
    phon = torch.randint(1, 80, (2, 12))
    score, kw_emb = head(audio, phon)
    assert score.shape == (2,)
    assert kw_emb.shape[0] == 2
    assert kw_emb.shape[1] == head.cfg.proj_dim


def test_speaker_head_embedding_only() -> None:
    """Default head is inference-only (no AAM classifier)."""
    head = SpeakerHead()
    audio = torch.randn(2, 192, 100)
    out = head(audio, speaker_ids=torch.tensor([0, 1]))
    assert out["embedding"].shape[0] == 2
    assert out["embedding"].shape[1] == head.cfg.emb_dim
    assert "logits" not in out


def test_speaker_head_training_build() -> None:
    """With num_speakers > 0 the AAM classifier is wired in."""
    head = SpeakerHead(SpeakerHeadConfig(num_speakers=32))
    audio = torch.randn(2, 192, 100)
    out = head(audio, speaker_ids=torch.tensor([0, 1]))
    assert out["embedding"].shape == (2, head.cfg.emb_dim)
    assert out["logits"].shape == (2, 32)


def test_pvt_end_to_end_shapes() -> None:
    model = PVT()
    wav = torch.randn(2, 16_000)
    phon = torch.randint(1, 80, (2, 12))
    out = model(wav, phon)
    assert out["kws_score"].shape == (2,)
    assert out["kw_emb"].shape[0] == 2
    assert out["spk_emb"].shape[0] == 2
    assert "spk_logits" not in out  # only present when speaker_ids provided
