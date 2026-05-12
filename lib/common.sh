#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# COMMON FUNCTIONS — sourced by install.sh
# Supports: --dry-run mode (verifies URLs without downloading)
# Supports: RunPod + Vast.ai (auto-detects platform)
# Downloads via aria2c (16 connections) with curl fallback
# ══════════════════════════════════════════════════════════════
set -uo pipefail
# NOTE: no -e (errexit) — we handle errors in each function

COMFY=/workspace/ComfyUI
MODELS="$COMFY/models"
CNODES="$COMFY/custom_nodes"

DL_OK=0; DL_SKIP=0; DL_FAIL=0
DRY_RUN="${DRY_RUN:-0}"

# ── Logging ──
log()  { echo -e "\033[32m[+]\033[0m $*"; }
warn() { echo -e "\033[33m[!]\033[0m $*"; }
err()  { echo -e "\033[31m[x]\033[0m $*"; }
section() { echo -e "\n\033[36m═══ $* ═══\033[0m\n"; }

# ── Install aria2c if missing ──
_ensure_aria2() {
    if ! command -v aria2c &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq aria2 >/dev/null 2>&1 || true
    fi
}

# ── Fast download with aria2c (16 connections), curl fallback ──
# aria2c returns exit 0 even on errors and may download HTML error pages.
# Always verify file size > 100KB after download. Fallback to curl on failure.
_fast_dl() {
    local url="$1" dest="$2" header="${3:-}"

    # Remove broken symlinks before download
    [ -L "$dest" ] && [ ! -e "$dest" ] && rm -f "$dest"

    # Try aria2c first (fast, 16 connections)
    if command -v aria2c &>/dev/null; then
        local aria_args=(-x16 -s16 -k5M --min-split-size=5M -d "$(dirname "$dest")" -o "$(basename "$dest")" --console-log-level=warn --summary-interval=5 --allow-overwrite=true)
        if [ -n "$header" ]; then
            aria_args+=(--header="$header")
        fi
        aria2c "${aria_args[@]}" "$url" 2>&1
        # Verify: aria2c returns 0 even on error, check file size
        if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 100000 ]; then
            return 0
        fi
        # aria2c failed or downloaded junk — remove and try curl
        rm -f "$dest" 2>/dev/null
        warn "aria2c failed, falling back to curl..."
    fi

    # Fallback to curl
    if [ -n "$header" ]; then
        curl -L --progress-bar -H "$header" "$url" -o "$dest" 2>&1
    else
        curl -L --progress-bar "$url" -o "$dest" 2>&1
    fi
}

# ── Dry-run: verify URL returns 200 ──
_check_url() {
    local url="$1" name="$2" auth_header="${3:-}"
    local http_code
    if [ -n "$auth_header" ]; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -L -H "$auth_header" --head "$url" 2>/dev/null || echo "000")
    else
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -L --head "$url" 2>/dev/null || echo "000")
    fi
    if [ "$http_code" = "200" ] || [ "$http_code" = "302" ] || [ "$http_code" = "301" ]; then
        log "URL OK ($http_code): $name"
        DL_OK=$((DL_OK + 1))
    else
        err "URL FAIL ($http_code): $name → $url"
        DL_FAIL=$((DL_FAIL + 1))
    fi
}

# ── Download: HuggingFace (with token from $HF_TOKEN env) ──
dl_hf() {
    local url="$1" dest="$2"
    local name; name=$(basename "$dest")

    if [ "$DRY_RUN" = "1" ]; then
        _check_url "$url" "$name" "Authorization: Bearer ${HF_TOKEN:-}"
        return 0
    fi

    if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000000 ]; then
        log "SKIP: $name (exists)"
        DL_SKIP=$((DL_SKIP + 1))
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    log "Downloading: $name ..."
    if _fast_dl "$url" "$dest" "Authorization: Bearer ${HF_TOKEN:-}"; then
        if [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000 ]; then
            DL_OK=$((DL_OK + 1))
            return 0
        fi
    fi
    err "FAIL: $name"
    rm -f "$dest"
    DL_FAIL=$((DL_FAIL + 1))
}

# ── Download: HuggingFace (public, no auth) ──
dl_pub() {
    local url="$1" dest="$2"
    local name; name=$(basename "$dest")

    if [ "$DRY_RUN" = "1" ]; then
        _check_url "$url" "$name"
        return 0
    fi

    if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000000 ]; then
        log "SKIP: $name (exists)"
        DL_SKIP=$((DL_SKIP + 1))
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    log "Downloading: $name ..."
    if _fast_dl "$url" "$dest"; then
        if [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000 ]; then
            DL_OK=$((DL_OK + 1))
            return 0
        fi
    fi
    err "FAIL: $name"
    rm -f "$dest"
    DL_FAIL=$((DL_FAIL + 1))
}

# ── Download: CivitAI (with $CIVITAI_TOKEN) ──
dl_civitai() {
    local model_id="$1" dest="$2"
    local name; name=$(basename "$dest")

    if [ "$DRY_RUN" = "1" ]; then
        local tok="${CIVITAI_TOKEN:-}"
        if [ -z "$tok" ]; then
            warn "CIVITAI_TOKEN not set — cannot verify $name"
            DL_FAIL=$((DL_FAIL + 1))
        else
            _check_url "https://civitai.com/api/download/models/${model_id}?type=Model&format=SafeTensor&token=$tok" \
                "$name"
        fi
        return 0
    fi

    if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000000 ]; then
        log "SKIP: $name (exists)"
        DL_SKIP=$((DL_SKIP + 1))
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    log "Downloading from CivitAI: $name ..."
    local tok="${CIVITAI_TOKEN:-}"
    if [ -z "$tok" ]; then
        warn "CIVITAI_TOKEN not set, skipping $name"
        DL_FAIL=$((DL_FAIL + 1))
        return 1
    fi
    if _fast_dl "https://civitai.com/api/download/models/${model_id}?type=Model&format=SafeTensor&token=$tok" "$dest"; then
        if [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000 ]; then
            DL_OK=$((DL_OK + 1))
            return 0
        fi
    fi
    err "FAIL: $name"
    rm -f "$dest"
    DL_FAIL=$((DL_FAIL + 1))
}

# ── Clone custom node (idempotent) ──
clone_node() {
    local url="$1"
    local name; name=$(basename "$url" .git)

    if [ "$DRY_RUN" = "1" ]; then
        log "CHECK node: $name → $url"
        DL_OK=$((DL_OK + 1))
        return 0
    fi

    if [ -d "$CNODES/$name" ]; then
        log "SKIP node: $name (exists)"
        return 0
    fi
    log "Cloning: $name"
    git clone --quiet --depth 1 "$url" "$CNODES/$name" 2>/dev/null || {
        warn "Clone failed: $name"
        DL_FAIL=$((DL_FAIL + 1))
        return 1
    }
    if [ -f "$CNODES/$name/requirements.txt" ]; then
        pip install --break-system-packages -q -r "$CNODES/$name/requirements.txt" 2>/dev/null || true
    fi
}

# ── Create symlink (safe, no circular) ──
make_link() {
    local target="$1" link="$2"
    [ "$DRY_RUN" = "1" ] && return 0
    # Only create symlink if target is a real file (not another symlink to us)
    if [ -f "$target" ] && [ ! -L "$target" -o -e "$target" ]; then
        if [ ! -f "$link" ] || [ -L "$link" ]; then
            ln -sf "$target" "$link"
            log "Symlink: $(basename "$link") -> $(basename "$target")"
        fi
    fi
}

# ── Detect platform & generate ComfyUI URL ──
detect_platform() {
    RPID="${RUNPOD_POD_ID:-}"
    if [ -n "$RPID" ]; then
        PLATFORM="runpod"
        COMFYUI_URL="https://${RPID}-8188.proxy.runpod.net"
        return
    fi

    # Vast.ai: check for VAST_CONTAINERLABEL or direct port
    if [ -n "${VAST_CONTAINERLABEL:-}" ] || [ -n "${CONTAINER_ID:-}" ]; then
        PLATFORM="vastai"
        local ip; ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        COMFYUI_URL="http://${ip:-localhost}:8188"
        return
    fi

    # Local/generic
    PLATFORM="local"
    local ip; ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    COMFYUI_URL="http://${ip:-localhost}:8188"
}
