"""End-to-end smoke tests covering the joint train + enroll + detect loop."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import torch

from speech_disentanglement.inference.enroll import enroll
from speech_disentanglement.inference.g2p import (
    pad_phoneme_batch,
    text_to_phoneme_ids,
)
from speech_disentanglement.inference.streaming import (
    StreamingConfig,
    StreamingDetector,
)
from speech_disentanglement.models import PVT, PVTConfig
from speech_disentanglement.models.speaker_head import SpeakerHeadConfig
from speech_disentanglement.training.losses import AAMSoftmax, InfoNCE


def test_g2p_basic() -> None:
    ids = text_to_phoneme_ids("hello world")
    assert all(0 <= i < 80 for i in ids)
    assert len(ids) >= 5


def test_g2p_pad_batch() -> None:
    ids = [text_to_phoneme_ids("hi"), text_to_phoneme_ids("hello")]
    padded = pad_phoneme_batch(ids)
    assert len({len(s) for s in padded}) == 1


def test_joint_smoke_backward() -> None:
    # Training build has a small AAM classifier so we can exercise spk loss.
    model = PVT(PVTConfig(speaker=SpeakerHeadConfig(num_speakers=32)))
    wav = torch.randn(2, 16_000)
    phon = torch.tensor(pad_phoneme_batch(
        [text_to_phoneme_ids("hello"), text_to_phoneme_ids("hello")]
    ))
    spk_ids = torch.tensor([0, 1])
    out = model(wav, phon, spk_ids)
    target = torch.tensor([1.0, 0.0])
    l_kws = torch.nn.functional.binary_cross_entropy_with_logits(out["kws_score"], target)
    l_spk = AAMSoftmax()(out["spk_logits"], spk_ids)
    shuffled = out["kw_emb"][torch.randperm(2)]
    l_ct = InfoNCE()(out["kw_emb"], shuffled)
    loss = l_kws + l_spk + 0.3 * l_ct
    loss.backward()
    grads = [p.grad for p in model.parameters() if p.grad is not None]
    assert grads, "no parameter received a gradient"


def test_enroll_and_detect(tmp_path: Path) -> None:
    import soundfile as sf  # pytest will skip below if missing

    rec_paths = []
    rng = np.random.default_rng(0)
    for i in range(3):
        wav = rng.standard_normal(16_000).astype(np.float32) * 0.05
        p = tmp_path / f"enroll_{i}.wav"
        sf.write(p, wav, 16_000)
        rec_paths.append(p)

    model = PVT()
    enrolled = enroll(model, rec_paths, keyword="hello")
    enroll_npz = tmp_path / "enrollment.npz"
    np.savez(enroll_npz, **enrolled)

    detector = StreamingDetector(
        model,
        enroll_npz,
        StreamingConfig(kws_threshold=-1.0, spk_threshold=-1.0),
    )
    # Feed 1 s of audio in 200 ms hops; thresholds at -1 -> should accept.
    accepts = 0
    for _ in range(5):
        evt = detector.feed(rng.standard_normal(3_200).astype(np.float32))
        if evt and evt["accept"]:
            accepts += 1
    assert accepts >= 1
