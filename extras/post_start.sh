#!/bin/bash
# ══════════════════════════════════════════════════════════════
# RunPod post_start hook — runs AFTER sshd, BEFORE sleep infinity.
#
# Invoked by /start.sh (inherited from runpod/pytorch base) at
# container boot, automatically. We never invoke this script via
# SSH from the bot; it runs as part of container startup so the
# bot doesn't need to babysit install kickoff timing.
#
# Architecture: PARALLEL — ComfyUI binds :8188 immediately AND
# install.sh starts downloading models in parallel.
#
# Why parallel (not sequential install→ComfyUI):
#   RunPod's networking layer allocates the pod's publicIp + port 22
#   mapping based on the container actually listening on declared
#   ports. Empirically: with sequential post_start.sh, pods get stuck
#   on specific machines never receiving publicIp (tested 3x on
#   machine k9tyafceeokz — all failed). With parallel post_start.sh
#   (ComfyUI binds 8188 on boot), publicIp arrives in 60-180s.
#
# The "bot marks ready too early" race (which originally pushed me
# toward sequential) is now fixed in bot/services/install_monitor.py:
# the monitor only marks status=ready when install.log shows
# phase >= 7 (DONE markers). Until then, bot stays on the install
# progress screen even if ComfyUI probe says ready.
#
# install.sh's own ComfyUI start at the end does `pkill python3
# main.py` first, so there's no port conflict — old PID dies, new
# one binds.
#
# Detached pattern: explicit `< /dev/null > log 2>&1 &` so the
# parent /start.sh can return and let `sleep infinity` keep the
# container alive.
# ══════════════════════════════════════════════════════════════
set -u  # no -e — install.sh handles its own errors

echo "[post_start] === ComfyUI Ready RunPod hook ==="
date

# 1. Source RunPod-exported env vars (HF_TOKEN, CIVITAI_TOKEN, WORKFLOW_ID)
if [ -f /etc/rp_environment ]; then
    # shellcheck disable=SC1091
    source /etc/rp_environment
    echo "[post_start] sourced /etc/rp_environment"
else
    echo "[post_start] WARN: /etc/rp_environment not found"
fi

mkdir -p /workspace

# ─────────────────────────────────────────────────────────────────────────────
# Bootstrap /workspace from /opt/comfy-seed on first boot.
#
# Why: RunPod mounts /workspace as a MooseFS network volume. On the FIRST boot
# of a brand-new pod that mount is empty and shadows whatever the base image
# baked at /workspace/*. We need to restore the bake from an un-shadowed path.
#
# The seed was put at /opt/comfy-seed during image build (Dockerfile.runpod).
# On subsequent boots /workspace is persistent (the volume survives stop/start)
# so main.py will already exist and this block is a no-op.
#
# rsync is in the base image (installed by Dockerfile apt-get). If for any
# reason it's missing we fall back to cp -a.
# ─────────────────────────────────────────────────────────────────────────────
if [ ! -f /workspace/ComfyUI/main.py ] && [ -d /opt/comfy-seed ]; then
    echo "[post_start] /workspace empty → seeding from /opt/comfy-seed (first boot)"
    t0=$(date +%s)
    if command -v rsync >/dev/null 2>&1; then
        rsync -a /opt/comfy-seed/ /workspace/
    else
        cp -a /opt/comfy-seed/. /workspace/
    fi
    echo "[post_start] seed done in $(( $(date +%s) - t0 ))s, size: $(du -sh /workspace 2>/dev/null | awk '{print $1}')"
fi

cd /workspace/ComfyUI || {
    echo "[post_start] FATAL: /workspace/ComfyUI missing"
    exit 1
}

# 2. Start ComfyUI on :8188 IMMEDIATELY — RunPod's networking sees
#    port bound → allocates publicIp + portMappings without delay.
echo "[post_start] starting ComfyUI on 0.0.0.0:8188"
nohup python3 main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --front-end-version Comfy-Org/ComfyUI_frontend@1.42.6 \
    > /workspace/comfyui.log 2>&1 < /dev/null &
echo $! > /workspace/comfyui.pid
echo "[post_start] ComfyUI pid=$(cat /workspace/comfyui.pid)"

# 3. If WORKFLOW_ID is set, kick install.sh in parallel. install.sh
#    downloads models and pkill+restarts ComfyUI at the end. Bot
#    tails install.log; bot will only mark pod "ready" when log shows
#    phase >= 7 (DONE). So the parallel ComfyUI start won't cause
#    the earlier "ready too early → user clicks add_wf" race.
if [ -n "${WORKFLOW_ID:-}" ]; then
    if [ -f /workspace/install.sh ]; then
        echo "[post_start] launching install.sh for WORKFLOW_ID=$WORKFLOW_ID"
        nohup bash /workspace/install.sh "$WORKFLOW_ID" \
            > /workspace/install.log 2>&1 < /dev/null &
        echo $! > /workspace/install.pid
        echo "[post_start] install.sh pid=$(cat /workspace/install.pid)"
    else
        echo "[post_start] WARN: /workspace/install.sh missing"
    fi
else
    echo "[post_start] WORKFLOW_ID not set — ComfyUI only, no model download"
fi

echo "[post_start] === hook done ==="
