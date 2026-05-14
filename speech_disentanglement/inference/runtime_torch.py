"""Reference Torch runtime (used for training, evaluation, and CPU demos)."""

from __future__ import annotations

from pathlib import Path

import torch

from ..models import PVT


def load(checkpoint: Path | None = None, device: str = "cpu") -> PVT:
    model = PVT().to(device)
    if checkpoint is not None:
        state = torch.load(checkpoint, map_location=device)
        model.load_state_dict(state.get("model", state), strict=False)
    model.eval()
    return model
