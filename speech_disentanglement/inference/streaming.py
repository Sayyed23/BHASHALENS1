"""Real-time streaming runner.

Holds a 1.0 s ring buffer with 200 ms hop, runs the encoder + both heads
per hop, and emits an `accept` event when both scores cross their
thresholds. The runner is deliberately Numpy-friendly so we can swap the
backbone for an ONNX or TFLite session in deployment without touching
this file.
"""

from __future__ import annotations

import argparse
import time
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import torch

from ..models import PVT
from .g2p import pad_phoneme_batch, text_to_phoneme_ids


@dataclass
class StreamingConfig:
    sample_rate: int = 16_000
    window_seconds: float = 1.0
    hop_seconds: float = 0.2
    kws_threshold: float = 0.5
    spk_threshold: float = 0.5
    cooldown_seconds: float = 1.5  # avoid double-firing after an accept


class StreamingDetector:
    def __init__(
        self,
        model: PVT,
        enrollment_npz: Path,
        cfg: StreamingConfig | None = None,
    ) -> None:
        self.cfg = cfg or StreamingConfig()
        self.model = model.eval()

        z = np.load(enrollment_npz, allow_pickle=True)
        self.kw_emb_ref = torch.from_numpy(z["kw_emb"]).float()
        self.spk_emb_ref = torch.from_numpy(z["spk_emb"]).float()
        self.keyword = str(z["keyword"].item() if z["keyword"].shape == () else z["keyword"])

        self._buf = np.zeros(int(self.cfg.window_seconds * self.cfg.sample_rate), dtype=np.float32)
        self._last_accept_ts = -1e9

    # ------------------------------------------------------------------ #
    def feed(self, chunk: np.ndarray, now: float | None = None) -> dict | None:
        """Push `chunk` (mono float32 16 kHz) into the buffer and maybe accept."""
        if chunk.ndim != 1:
            chunk = chunk.reshape(-1)
        n = chunk.shape[0]
        self._buf = np.concatenate([self._buf[n:], chunk])
        now = now if now is not None else time.monotonic()

        if now - self._last_accept_ts < self.cfg.cooldown_seconds:
            return None

        wav = torch.from_numpy(self._buf).unsqueeze(0)
        phon = torch.tensor(
            pad_phoneme_batch([text_to_phoneme_ids(self.keyword)]),
            dtype=torch.long,
        )
        with torch.no_grad():
            out = self.model(wav, phon)
        kw_score = torch.cosine_similarity(out["kw_emb"], self.kw_emb_ref.unsqueeze(0)).item()
        sp_score = torch.cosine_similarity(out["spk_emb"], self.spk_emb_ref.unsqueeze(0)).item()
        decision = (kw_score >= self.cfg.kws_threshold) and (sp_score >= self.cfg.spk_threshold)
        if decision:
            self._last_accept_ts = now
        return {"accept": decision, "kw_score": kw_score, "spk_score": sp_score, "ts": now}


def _iter_file_chunks(path: Path, cfg: StreamingConfig) -> np.ndarray:
    import soundfile as sf  # noqa: WPS433

    wav, sr = sf.read(str(path), dtype="float32", always_2d=False)
    if wav.ndim > 1:
        wav = wav.mean(axis=-1)
    if sr != cfg.sample_rate:
        raise SystemExit(f"{path}: expected {cfg.sample_rate} Hz, got {sr} Hz")
    hop = int(cfg.hop_seconds * cfg.sample_rate)
    for i in range(0, len(wav), hop):
        yield wav[i : i + hop]


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--enrollment", type=Path, required=True)
    p.add_argument("--checkpoint", type=Path, default=None)
    p.add_argument("--source", choices=("file", "mic"), default="file")
    p.add_argument("--audio", type=Path, default=None, help="Required when --source=file")
    p.add_argument("--kws-threshold", type=float, default=0.5)
    p.add_argument("--spk-threshold", type=float, default=0.5)
    args = p.parse_args(argv)

    cfg = StreamingConfig(kws_threshold=args.kws_threshold, spk_threshold=args.spk_threshold)
    model = PVT()
    if args.checkpoint:
        state = torch.load(args.checkpoint, map_location="cpu")
        model.load_state_dict(state.get("model", state), strict=False)
    detector = StreamingDetector(model, args.enrollment, cfg)

    if args.source == "file":
        if args.audio is None:
            raise SystemExit("--audio is required when --source=file")
        for chunk in _iter_file_chunks(args.audio, cfg):
            evt = detector.feed(chunk)
            if evt and evt["accept"]:
                print(f"ACCEPT  kw={evt['kw_score']:.3f}  spk={evt['spk_score']:.3f}")
        return 0

    # --source=mic
    try:
        import sounddevice as sd  # noqa: WPS433
    except ImportError as e:
        raise SystemExit(
            "Microphone capture requires `pip install sounddevice` and a PortAudio backend"
        ) from e
    hop = int(cfg.hop_seconds * cfg.sample_rate)
    print(f"Listening for '{detector.keyword}' (press Ctrl-C to stop)...")
    with sd.InputStream(channels=1, samplerate=cfg.sample_rate, blocksize=hop, dtype="float32") as stream:
        while True:
            block, _ = stream.read(hop)
            evt = detector.feed(block[:, 0])
            if evt and evt["accept"]:
                print(f"ACCEPT  kw={evt['kw_score']:.3f}  spk={evt['spk_score']:.3f}")


if __name__ == "__main__":
    raise SystemExit(main())
