# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Hugging Face Spaces Docker template for this repo.
# Runs BOTH:
# - kimodo_textencoder (Gradio on 9550, internal)
# - kimodo_demo        (Viser UI on 7860, public)
#
FROM nvcr.io/nvidia/pytorch:24.10-py3

# Avoid some interactive prompts + make pip quieter/reproducible-ish
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Persist HF caches on Spaces when /data is enabled.
    HF_HOME=/data/.huggingface \
    XDG_CACHE_HOME=/data/.cache \
    PIP_CACHE_DIR=/data/.cache/pip

# Where your code will live inside the container
WORKDIR /workspace

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates \
      cmake build-essential \
    && rm -rf /var/lib/apt/lists/*

# Some base images ship a broken `/usr/local/bin/cmake` shim (from a partial pip install),
# which shadows `/usr/bin/cmake` and breaks builds that invoke `cmake` (e.g. MotionCorrection).
# Prefer the system cmake.
RUN rm -f /usr/local/bin/cmake || true


# Copy the requirements (which contains, kimodo, viser and SOMA)
COPY requirements.txt /workspace/requirements.txt

# For private GitHub repos in requirements.txt:
# - On Hugging Face Spaces: add a Secret named GITHUB_TOKEN in Space Settings.
#   HF exposes it at build time via Docker secret mount (no build-arg).
# - Local build: docker build --build-arg GITHUB_TOKEN=ghp_xxxx .
ARG GITHUB_TOKEN=

RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=secret,id=GITHUB_TOKEN,mode=0444,required=false \
    python -m pip install --upgrade pip \
 && python -m pip install -r requirements.txt;


COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 7860
ENTRYPOINT ["/start.sh"]
