#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# ComfyUI Universal Installer
#
# Usage:
#   bash install.sh <workflow_id>[,workflow_id2,...]
#   bash install.sh --dry-run <workflow_id>    # verify URLs only
#   bash install.sh ALL                         # install everything
#
# IDEMPOTENT: safe to re-run. Skips existing files/nodes.
# INCREMENTAL: adding workflows only downloads missing models.
# PLATFORM: auto-detects RunPod / Vast.ai / local
#
# Required env vars:
#   HF_TOKEN      — HuggingFace access token
#   CIVITAI_TOKEN — CivitAI API key (optional, for some workflows)
# ══════════════════════════════════════════════════════════════
set -uo pipefail
# NOTE: no -e — errors handled per-function, script continues on failures

START_TIME=$(date +%s)

# ── Remove broken JS extensions from Swwan vendor ──
# Swwan/web/js/*.js имеет битые импорты `../../rgthree/common/...`
# которые резолвятся в 404 и вызывают "Loading Error" в ComfyUI frontend.
# Все 22 наших workflow используют ноды Swwan через NODE_CLASS_MAPPINGS (Python),
# виджеты для них берутся из настоящих ComfyUI-KJNodes/LayerStyle/rgthree-comfy.
# Удаляем `web/` чтобы убрать конфликт без потери функционала.
rm -rf /workspace/ComfyUI/custom_nodes/ComfyUI_Swwan/web 2>/dev/null || true

# Parse --dry-run flag
export DRY_RUN=0
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --dry-run) export DRY_RUN=1 ;;
        *) ARGS+=("$arg") ;;
    esac
done
set -- "${ARGS[@]:-}"

# Resolve script directory
if [ -f "$0" ] && [ "$0" != "bash" ] && [ "$0" != "/dev/stdin" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    SCRIPT_DIR="/tmp/comfyui-deploy"
    if [ ! -d "$SCRIPT_DIR" ]; then
        echo "Downloading installer..."
        git clone --quiet --depth 1 "https://github.com/treforyan-hue/comfyui-deploy.git" "$SCRIPT_DIR" 2>/dev/null || {
            echo "ERROR: Cannot download installer. Check internet connection."
            exit 1
        }
    else
        cd "$SCRIPT_DIR" && git pull --quiet 2>/dev/null || true
    fi
fi
export SCRIPT_DIR

# Source libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/nodes.sh"

# Parse workflow IDs
WORKFLOW_IDS="${1:-}"
if [ -z "$WORKFLOW_IDS" ]; then
    echo "ComfyUI Universal Installer"
    echo ""
    echo "Usage: bash install.sh <workflow_id>[,id2,...]"
    echo "       bash install.sh --dry-run <workflow_id>  # verify URLs"
    echo ""
    echo "Available workflows:"
    echo "  privateki      — Wan 2.2 dance/animation (24GB)"
    echo "  ofm_tech_v2    — Best quality Wan animation (48GB)"
    echo "  icy_scail_2    — SCAIL + Flux pose I2V (48GB)"
    echo "  ofm_i2v_gen3   — Dasiwa image-to-video (24GB)"
    echo "  ofm_faceswp    — Flux 2 face swap (24GB)"
    echo "  controlnt      — Z-Image-Turbo ControlNet (12GB)"
    echo "  ofm_skin_gen3  — Realistic skin SDXL (16GB)"
    echo "  ofm_dt_gen3    — Flux 2 Klein image gen (16GB)"
    echo "  ofm_zit_gen    — Z-Image-Turbo fast gen (12GB)"
    echo "  kiara_sasat    — SDXL reference gen (16GB)"
    echo "  ofm_dataset_gen — Florence2 captioning (8GB)"
    echo "  ofm_nsfw       — INSTARAW pipeline (16GB)"
    echo "  animator_v25   — Animator V2.5 Wan 2.2 + Uni3C (24GB)"
    echo "  feihou_animator — FeiHou Animator Wan 2.2 + SDPose + SAM3 (24GB)"
    echo "  tokyo_sage     — Tokyo Sage Wan 2.2 Animate alt (80GB)"
    echo "  ofmtech_identity_swap — Flux 2 Klein 9b identity swap (24GB)"
    echo "  instaraw_wan22 — INSTARAW WAN 2.2 T2I + FaceDetailer (48GB)"
    echo "  instaraw_zimage — INSTARAW Z-Image Pro (24GB)"
    echo "  instaraw_faceswap — INSTARAW outfit/hair/character swap (12GB)"
    echo "  instaraw_teleport — INSTARAW background teleport (12GB)"
    echo "  instaraw_booba — INSTARAW Flux Kontext body enhance (24GB)"
    echo "  instaraw_big   — INSTARAW NanoBanana/Gemini API (12GB, no models)"
    echo "  instaraw_bypass_max — INSTARAW anti-detection (12GB, no models)"
    echo "  ALL            — Everything (~250GB)"
    exit 1
fi

if [ "$WORKFLOW_IDS" = "ALL" ]; then
    WORKFLOW_IDS="privateki,ofm_tech_v2,icy_scail_2,ofm_i2v_gen3,ofm_faceswp,controlnt,ofm_skin_gen3,ofm_dt_gen3,ofm_zit_gen,kiara_sasat,ofm_dataset_gen,ofm_nsfw,animator_v25,feihou_animator"
fi

IFS=',' read -ra WF_ARRAY <<< "$WORKFLOW_IDS"

if [ "$DRY_RUN" = "1" ]; then
    section "DRY RUN — verifying URLs for: ${WF_ARRAY[*]}"
else
    log "Workflows: ${WF_ARRAY[*]}"
    detect_platform
    log "Platform: $PLATFORM"
fi

# ══════════════════════════════════════
# STEP 0: Checks
# ══════════════════════════════════════
section "Pre-flight checks"

# Install aria2c for fast parallel downloads (if not in Docker image)
_ensure_aria2

if [ -z "${HF_TOKEN:-}" ]; then
    warn "HF_TOKEN not set. Some model downloads will fail."
fi

if [ "$DRY_RUN" = "0" ]; then
    AVAIL_GB=$(df --output=avail -BG /workspace 2>/dev/null | tail -1 | tr -d ' G' || echo 999)
    log "Disk available: ${AVAIL_GB}GB"
fi

# ══════════════════════════════════════
# STEP 1: ComfyUI (skip in dry-run)
# ══════════════════════════════════════
if [ "$DRY_RUN" = "0" ]; then
    section "ComfyUI installation"

    if [ ! -f "$COMFY/main.py" ]; then
        log "Cloning ComfyUI..."
        git clone --quiet "https://github.com/comfyanonymous/ComfyUI.git" "$COMFY"
        pip install --break-system-packages -q -r "$COMFY/requirements.txt"
    else
        log "ComfyUI already installed"
    fi

    python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null || {
        warn "PyTorch/CUDA not detected — Docker image should have it, skipping reinstall"
    }

    mkdir -p "$MODELS"/{diffusion_models,unet,vae,text_encoders,clip,clip_vision,loras,checkpoints}
    mkdir -p "$MODELS"/{upscale_models,detection,sam2,sams,rife,controlnet,model_patches,seedvr2}
    mkdir -p "$MODELS"/ultralytics/{bbox,segm}
    mkdir -p "$COMFY/user/default/workflows"
fi

# ══════════════════════════════════════
# STEP 2: Custom Nodes
# ══════════════════════════════════════
install_all_nodes

# ══════════════════════════════════════
# STEP 2.5: Runtime patches (idempotent)
# ══════════════════════════════════════
apply_runtime_patches


# ══════════════════════════════════════
# STEP 3: Models (per workflow)
# ══════════════════════════════════════
section "Model downloads"

for wf_file in "$SCRIPT_DIR"/workflows/*.sh; do
    source "$wf_file"
done

for wf_id in "${WF_ARRAY[@]}"; do
    wf_id=$(echo "$wf_id" | tr -d ' ')
    func_name="models_${wf_id}"
    if type "$func_name" &>/dev/null; then
        "$func_name"
    else
        warn "Unknown workflow: $wf_id (no function $func_name)"
    fi
done

# ══════════════════════════════════════
# STEP 4: Post-install (skip in dry-run)
# ══════════════════════════════════════
if [ "$DRY_RUN" = "0" ]; then
    section "Post-install fixes"

    make_link "$MODELS/vae/ae.safetensors" "$MODELS/vae/flux_vae.safetensors"
    make_link "$MODELS/vae/Wan2_1_VAE_bf16.safetensors" "$MODELS/vae/wan_2.1_vae.safetensors"
    make_link "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"
    make_link "$MODELS/text_encoders/qwen_3_4b.safetensors" "$MODELS/clip/qwen_3_4b.safetensors"
    make_link "$MODELS/text_encoders/qwen_3_8b_fp8mixed.safetensors" "$MODELS/clip/qwen_3_8b_fp8mixed.safetensors"
    make_link "$MODELS/text_encoders/qwen_3_8b.safetensors" "$MODELS/clip/qwen_3_8b.safetensors"

    # t5xxl + clip_l: one-directional only (avoid circular symlinks)
    # Real file location depends on which workflow downloaded it
    if [ -f "$MODELS/text_encoders/t5xxl_fp8_e4m3fn.safetensors" ] && [ ! -L "$MODELS/text_encoders/t5xxl_fp8_e4m3fn.safetensors" ]; then
        make_link "$MODELS/text_encoders/t5xxl_fp8_e4m3fn.safetensors" "$MODELS/clip/t5xxl_fp8_e4m3fn.safetensors"
    elif [ -f "$MODELS/clip/t5xxl_fp8_e4m3fn.safetensors" ] && [ ! -L "$MODELS/clip/t5xxl_fp8_e4m3fn.safetensors" ]; then
        make_link "$MODELS/clip/t5xxl_fp8_e4m3fn.safetensors" "$MODELS/text_encoders/t5xxl_fp8_e4m3fn.safetensors"
    fi
    if [ -f "$MODELS/text_encoders/clip_l.safetensors" ] && [ ! -L "$MODELS/text_encoders/clip_l.safetensors" ]; then
        make_link "$MODELS/text_encoders/clip_l.safetensors" "$MODELS/clip/clip_l.safetensors"
    elif [ -f "$MODELS/clip/clip_l.safetensors" ] && [ ! -L "$MODELS/clip/clip_l.safetensors" ]; then
        make_link "$MODELS/clip/clip_l.safetensors" "$MODELS/text_encoders/clip_l.safetensors"
    fi

    if [ -f "$MODELS/rife/rife49.pth" ]; then
        make_link "$MODELS/rife/rife49.pth" "$CNODES/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth"
    fi

    # imageio-ffmpeg already in Docker image, skip pip
    rm -rf /tmp/pip* /tmp/torch* 2>/dev/null || true
fi

# ══════════════════════════════════════
# STEP 5: Start ComfyUI (skip in dry-run)
# ══════════════════════════════════════
if [ "$DRY_RUN" = "0" ]; then
    section "Starting ComfyUI"

    pkill -f "python.*main.py" 2>/dev/null || true
    sleep 2

    cd "$COMFY"
    nohup python3 main.py --listen 0.0.0.0 --port 8188 > /workspace/comfyui.log 2>&1 &
    CPID=$!

    log "PID: $CPID — waiting for startup (max 5 min)..."

    READY=0
    for i in $(seq 1 60); do
        if curl -s http://localhost:8188/system_stats > /dev/null 2>&1; then
            READY=1
            break
        fi
        sleep 5
    done

    if [ "$READY" = "1" ]; then
        NC=$(curl -s http://localhost:8188/object_info | python3 -c "import json,sys;print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
        GP=$(curl -s http://localhost:8188/system_stats | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['devices'][0]['name'])" 2>/dev/null || echo "?")

        detect_platform

        ELAPSED=$(( $(date +%s) - START_TIME ))
        section "DONE"
        log "Platform:  $PLATFORM"
        log "GPU:       $GP"
        log "Nodes:     $NC loaded"
        log "Time:      $((ELAPSED / 60))m $((ELAPSED % 60))s"
        log "Downloads: $DL_OK ok, $DL_SKIP skipped, $DL_FAIL failed"
        log "URL:       $COMFYUI_URL"
        log "Log:       /workspace/comfyui.log"
    else
        err "ComfyUI did not start in 5 min"
        err "Check: tail -50 /workspace/comfyui.log"
    fi
else
    # Dry-run summary
    ELAPSED=$(( $(date +%s) - START_TIME ))
    section "DRY RUN RESULTS"
    log "URLs checked: $((DL_OK + DL_FAIL))"
    log "OK:     $DL_OK"
    log "FAILED: $DL_FAIL"
    log "Time:   ${ELAPSED}s"
    if [ "$DL_FAIL" -gt 0 ]; then
        err "Some URLs failed! Fix before deploying."
        exit 1
    else
        log "All URLs verified — ready to deploy!"
    fi
fi
