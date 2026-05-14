"""Convert the exported ONNX model to TFLite for on-device deployment.

We delegate ONNX -> TFLite to `onnx2tf` (Apache-2.0). The XNNPACK and
NNAPI delegates are configured at *runtime* by the Flutter / Android
host, so this script only produces the .tflite artifact.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def convert(onnx_path: Path, out_dir: Path, *, int8: bool = True) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    onnx2tf = shutil.which("onnx2tf")
    if onnx2tf is None:
        raise SystemExit(
            "onnx2tf not found. Install with `pip install onnx2tf onnx-graphsurgeon`."
        )
    cmd = [onnx2tf, "-i", str(onnx_path), "-o", str(out_dir), "-osd"]
    if int8:
        cmd.append("--output_integer_quantized_tflite")
    subprocess.run(cmd, check=True)
    candidates = list(out_dir.glob("*.tflite"))
    if not candidates:
        raise SystemExit(f"onnx2tf did not produce a .tflite under {out_dir}")
    return candidates[0]


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--onnx", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--no-int8", action="store_true")
    args = p.parse_args(argv)
    path = convert(args.onnx, args.out, int8=not args.no_int8)
    print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
