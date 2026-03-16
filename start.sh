#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

cd /workspace

# pre download ckpts
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("nvidia/Kimodo-SOMA-RP-v1")
snapshot_download("nvidia/Kimodo-G1-RP-v1")
print("Checkpoint download complete.")
PY

# lauching text encoder
echo "Starting text-encoder on :9550 ..."
kimodo_textencoder &
TEXT_ENCODER_PID=$!

# make sure to kill it if the demo really crash
cleanup() {
  echo "Shutting down text-encoder (pid=${TEXT_ENCODER_PID}) ..."
  kill "${TEXT_ENCODER_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# waiting for the text encoder to be fully loaded
echo "Waiting for text-encoder health ..."
for i in $(seq 1 1200); do
  if curl -fsS "http://127.0.0.1:9550/" >/dev/null 2>&1; then
    echo "Text-encoder is up."
    break
  fi
  sleep 1
  if [[ $i -eq 1200 ]]; then
    echo "ERROR: text-encoder did not become healthy on http://127.0.0.1:9550/ within 1800" >&2
    exit 1
  fi
done


# launching the demo
echo "Starting demo on :7860 ..."
exec kimodo_demo
