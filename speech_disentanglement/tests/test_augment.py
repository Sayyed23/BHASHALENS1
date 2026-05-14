"""Tests for the audio augmentation primitives."""

from __future__ import annotations

import torch

from speech_disentanglement.data.augment.noise_mix import mix_at_snr
from speech_disentanglement.data.augment.spec_augment import SpecAugment


def _rms(x: torch.Tensor) -> torch.Tensor:
    return torch.sqrt(torch.clamp((x ** 2).mean(), min=1e-12))


def test_mix_at_snr_produces_target_snr() -> None:
    torch.manual_seed(0)
    clean = torch.randn(16_000) * 0.1
    noise = torch.randn(16_000)
    for target_snr in (-5.0, 0.0, 10.0, 30.0):
        mixed = mix_at_snr(clean, noise.clone(), target_snr)
        # Estimate actual SNR from the additive noise we re-derive.
        added = mixed - clean
        actual = 20 * torch.log10(_rms(clean) / _rms(added)).item()
        assert abs(actual - target_snr) < 0.2, f"target={target_snr}, actual={actual:.2f}"


def test_spec_augment_keeps_shape() -> None:
    torch.manual_seed(0)
    mels = torch.randn(2, 40, 100)
    out = SpecAugment(p=1.0)(mels)
    assert out.shape == mels.shape


def test_spec_augment_can_zero_some_cells() -> None:
    torch.manual_seed(0)
    mels = torch.ones(1, 40, 100)
    out = SpecAugment(p=1.0, n_freq_masks=1, freq_mask_param=4,
                      n_time_masks=1, time_mask_param=10)(mels)
    # At least one cell should be masked to 0.
    assert (out == 0).any().item()
