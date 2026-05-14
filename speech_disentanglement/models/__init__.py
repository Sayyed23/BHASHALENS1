"""Model definitions for PVT-Lite.

Public API:
    - LogMelFrontend: feature extractor (40-d log-mel, CMVN).
    - StreamingEncoder: shared acoustic encoder (~1.8 M params).
    - KWSHead: open-vocab audio<->phoneme keyword head (~0.3 M).
    - SpeakerHead: ECAPA-mini speaker embedding head (~0.3 M).
    - PVT: joint module combining the above; total ~2.4 M params.
    - count_params: helper used by the CI param-budget test.
"""

from __future__ import annotations

from .encoder import EncoderConfig, StreamingEncoder
from .features import FeatureConfig, LogMelFrontend
from .kws_head import KWSHead, KWSHeadConfig
from .pvt import PVT, PVTConfig
from .speaker_head import SpeakerHead, SpeakerHeadConfig


def count_params(module) -> int:
    """Return the total number of trainable parameters in a torch module."""
    return sum(p.numel() for p in module.parameters() if p.requires_grad)


__all__ = [
    "LogMelFrontend",
    "FeatureConfig",
    "StreamingEncoder",
    "EncoderConfig",
    "KWSHead",
    "KWSHeadConfig",
    "SpeakerHead",
    "SpeakerHeadConfig",
    "PVT",
    "PVTConfig",
    "count_params",
]
