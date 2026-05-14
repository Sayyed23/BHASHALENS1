#!/usr/bin/env bash
# Best-effort dataset downloader. Each step is independent and idempotent.
# Total ~50 GB after all extractions -- DO NOT run on the Devin VM.

set -euo pipefail
DATA_ROOT="${DATA_ROOT:-$HOME/pvt_data}"
mkdir -p "$DATA_ROOT"

echo ">> downloading Google Speech Commands v2 (~2.4 GB) into $DATA_ROOT/speech_commands"
mkdir -p "$DATA_ROOT/speech_commands"
if [[ ! -f "$DATA_ROOT/speech_commands/.ok" ]]; then
  curl -L --fail \
    "http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz" \
    -o "$DATA_ROOT/sc_v2.tar.gz"
  tar -xzf "$DATA_ROOT/sc_v2.tar.gz" -C "$DATA_ROOT/speech_commands"
  rm "$DATA_ROOT/sc_v2.tar.gz"
  touch "$DATA_ROOT/speech_commands/.ok"
fi

echo ">> downloading MUSAN (~11 GB) into $DATA_ROOT/musan"
if [[ ! -d "$DATA_ROOT/musan/musan" ]]; then
  curl -L --fail "https://www.openslr.org/resources/17/musan.tar.gz" -o "$DATA_ROOT/musan.tar.gz"
  mkdir -p "$DATA_ROOT/musan"
  tar -xzf "$DATA_ROOT/musan.tar.gz" -C "$DATA_ROOT/musan"
  rm "$DATA_ROOT/musan.tar.gz"
fi

echo
echo "VoxCeleb 1/2 and LibriPhrase require registration; follow:"
echo "  VoxCeleb : https://www.robots.ox.ac.uk/~vgg/data/voxceleb/"
echo "  LibriPhrase : https://github.com/gusrb3164/LibriPhrase"
echo
echo "Once downloaded, point the prepare_*.py scripts at the extracted roots:"
echo "  python -m speech_disentanglement.data.prepare_speech_commands \\"
echo "         --root $DATA_ROOT/speech_commands --out speech_disentanglement/data/manifests/speech_commands"
