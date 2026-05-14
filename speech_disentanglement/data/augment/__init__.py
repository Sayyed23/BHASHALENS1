"""On-the-fly audio augmentation (noise mixing, RIR convolution, SpecAugment)."""

from .noise_mix import NoiseMixer, mix_at_snr
from .reverb import RIRConvolver, sample_rir_for_distance
from .spec_augment import SpecAugment

__all__ = [
    "NoiseMixer",
    "mix_at_snr",
    "RIRConvolver",
    "sample_rir_for_distance",
    "SpecAugment",
]
