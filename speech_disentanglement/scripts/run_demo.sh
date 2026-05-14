#!/usr/bin/env bash
# Quick end-to-end demo: instantiate model, run smoke forward+backward.
set -euo pipefail
cd "$(dirname "$0")/../.."
python -m speech_disentanglement.scripts.smoke
