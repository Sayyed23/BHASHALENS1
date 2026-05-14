"""Run a one-shot end-to-end smoke check.

Useful as `python -m speech_disentanglement.scripts.smoke` to verify the
package can import, instantiate, forward, and backward on a fresh machine.
"""

from __future__ import annotations

import torch

from speech_disentanglement.models import PVT, PVTConfig, count_params
from speech_disentanglement.models.speaker_head import SpeakerHeadConfig


def main() -> int:
    # Inference-build (no AAM classifier) -- this is what we deploy and what
    # the param-budget gate checks.
    inference_model = PVT()
    n_infer = count_params(inference_model)
    print(f"PVT params (inference build): {n_infer:,}  (target < 3,000,000)")

    # Training-build (with a small AAM classifier so we can exercise the
    # speaker-classification path end-to-end).
    train_cfg = PVTConfig(speaker=SpeakerHeadConfig(num_speakers=128))
    model = PVT(train_cfg)
    n_train = count_params(model)
    print(f"PVT params (training build w/ 128 spk): {n_train:,}")

    wav = torch.randn(2, 16_000)
    phon = torch.randint(1, 80, (2, 12))
    speaker_ids = torch.tensor([0, 1])
    out = model(wav, phon, speaker_ids)
    print(
        "forward OK -- "
        f"kws_score={tuple(out['kws_score'].shape)}, "
        f"kw_emb={tuple(out['kw_emb'].shape)}, "
        f"spk_emb={tuple(out['spk_emb'].shape)}, "
        f"spk_logits={tuple(out['spk_logits'].shape)}"
    )
    loss = out["kws_score"].mean() + out["spk_logits"].mean()
    loss.backward()
    print("backward OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
