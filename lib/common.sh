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

# ── Parallel download pool ──
# Workers run dl_*_worker in background up to DL_POOL_SIZE concurrent.
# Counters DL_OK/SKIP/FAIL cannot be shared across bash subshells, so each
# worker writes a single line to $DL_RESULT_DIR/$BASHPID.result and dl_wait_all
# aggregates them back. Workflows call dl_hf as before — synchronisation
# happens automatically in install.sh after each models_<wf> call.
DL_POOL_SIZE="${DL_POOL_SIZE:-4}"
DL_POOL_PIDS=()
DL_RESULT_DIR="${DL_RESULT_DIR:-/tmp/.cd-dl-results.$$}"
mkdir -p "$DL_RESULT_DIR" 2>/dev/null

_dl_pool_wait_slot() {
    # Block until pool has a free slot (< DL_POOL_SIZE active jobs).
    while [ "${#DL_POOL_PIDS[@]}" -ge "$DL_POOL_SIZE" ]; do
        wait "${DL_POOL_PIDS[0]}" 2>/dev/null
        DL_POOL_PIDS=("${DL_POOL_PIDS[@]:1}")
    done
}

dl_wait_all() {
    # Drain pool and aggregate worker results into parent counters.
    local pid
    for pid in "${DL_POOL_PIDS[@]}"; do
        wait "$pid" 2>/dev/null
    done
    DL_POOL_PIDS=()
    if [ -d "$DL_RESULT_DIR" ]; then
        local ok=0 fail=0 skip=0
        local f
        for f in "$DL_RESULT_DIR"/*.result; do
            [ -f "$f" ] || continue
            local tag; tag=$(head -1 "$f" 2>/dev/null)
            case "$tag" in
                OK*)   ok=$((ok+1)) ;;
                SKIP*) skip=$((skip+1)) ;;
                FAIL*) fail=$((fail+1)) ;;
            esac
        done
        DL_OK=$((DL_OK + ok))
        DL_SKIP=$((DL_SKIP + skip))
        DL_FAIL=$((DL_FAIL + fail))
        rm -f "$DL_RESULT_DIR"/*.result 2>/dev/null
    fi
}

# Return expected file size from HF: prefer X-Linked-Size (1 HEAD request,
# no redirect needed). Fallback to Content-Length after following redirects.
# Returns "0" if unknown.
_hf_get_size() {
    local url="$1" auth="${2:-}"
    local size=""
    local hdrs=(-sI --max-time 15)
    [ -n "$auth" ] && hdrs+=(-H "$auth")
    size=$(curl "${hdrs[@]}" "$url" 2>/dev/null \
        | tr -d '\r' | awk -F': ' 'tolower($1)=="x-linked-size"{print $2; exit}' | tr -d ' \n')
    if [ -z "$size" ] || [ "$size" = "0" ]; then
        size=$(curl "${hdrs[@]/--max-time/-Lr 0-0 --max-time}" "$url" 2>/dev/null \
            | tr -d '\r' | awk -F': ' 'tolower($1)=="content-length"{x=$2}END{print x}' | tr -d ' \n')
    fi
    [ -z "$size" ] && size=0
    printf '%s\n' "$size"
}

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
# Always verify file size after download. Fallback to curl on failure.
#
# Production timeouts (added 2026-05-15):
#   --lowest-speed-limit=10K  → kill zombie connection if <10KB/s for 30s
#   --timeout=60              → response timeout
#   --connect-timeout=30      → TCP handshake timeout
#   --continue=true           → resume via .aria2 control file on retry
#   --max-tries=10            → retry whole URL up to 10 times
#   --retry-wait=10           → 10s pause between retries
# This solves HF Cloudflare R2 rate-limit stalls on last 1-5% of large files
# (aria2 issue #441 + production config from copyprogramming.com 2026 guide).
_fast_dl() {
    local url="$1" dest="$2" header="${3:-}"

    # Remove broken symlinks before download
    [ -L "$dest" ] && [ ! -e "$dest" ] && rm -f "$dest"

    # Try aria2c first (fast, 16 connections)
    if command -v aria2c &>/dev/null; then
        local aria_args=(
            -x16 -s16 -k5M --min-split-size=5M
            -d "$(dirname "$dest")" -o "$(basename "$dest")"
            --console-log-level=warn --summary-interval=10
            --allow-overwrite=true --auto-file-renaming=false
            --file-allocation=none
            --continue=true
            --lowest-speed-limit=10K
            --timeout=60 --connect-timeout=30
            --max-tries=10 --retry-wait=10
            --max-file-not-found=3
        )
        if [ -n "$header" ]; then
            aria_args+=(--header="$header")
        fi
        aria2c "${aria_args[@]}" "$url" 2>&1
        # Verify: aria2c returns 0 even on error, check file size
        if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 100000 ]; then
            return 0
        fi
        # aria2c failed or downloaded junk — remove and try curl
        rm -f "$dest" "$dest.aria2" 2>/dev/null
        warn "aria2c failed, falling back to curl..."
    fi

    # Fallback to curl with resume (-C -) and retry
    local curl_args=(-L -C - --progress-bar --max-time 1800 --retry 5 --retry-delay 10 --retry-max-time 600)
    if [ -n "$header" ]; then
        curl "${curl_args[@]}" -H "$header" "$url" -o "$dest" 2>&1
    else
        curl "${curl_args[@]}" "$url" -o "$dest" 2>&1
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

# ── Download worker (runs in background subshell) ──
# Performs the actual download + size verification. Writes outcome to
# $DL_RESULT_DIR/$BASHPID.result so dl_wait_all can aggregate counters
# (bash subshells cannot mutate parent variables).
_dl_worker() {
    local url="$1" dest="$2" header="${3:-}"
    local name; name=$(basename "$dest")
    local result="$DL_RESULT_DIR/$BASHPID.result"

    mkdir -p "$(dirname "$dest")"

    # Get expected size BEFORE download — needed for verification
    local expected; expected=$(_hf_get_size "$url" "$header")

    if _fast_dl "$url" "$dest" "$header"; then
        local actual; actual=$(stat -c%s "$dest" 2>/dev/null || echo 0)
        # Size verification — if HF gave us a number, file must match EXACTLY.
        # Match = OK at ANY size (diffusers-папки имеют валидные конфиги <1KB,
        # напр. FishAudio quantization_info.json = 985 B — раньше падало по >1000).
        if [ "$expected" -gt 0 ]; then
            if [ "$actual" = "$expected" ]; then
                log "OK: $name ($actual bytes, size verified)"
                echo "OK $name $actual" > "$result"
                return 0
            fi
            err "FAIL: $name — size mismatch ($actual vs expected $expected)"
            rm -f "$dest" "$dest.aria2" 2>/dev/null
            echo "FAIL $name size_mismatch actual=$actual expected=$expected" > "$result"
            return 1
        fi
        # HF размер неизвестен → старая эвристика >1000 байт
        if [ "$actual" -gt 1000 ]; then
            log "OK: $name ($actual bytes)"
            echo "OK $name $actual" > "$result"
            return 0
        fi
    fi
    err "FAIL: $name (download failed)"
    rm -f "$dest" "$dest.aria2" 2>/dev/null
    echo "FAIL $name download_failed" > "$result"
    return 1
}

# ── Download: HuggingFace (with token from $HF_TOKEN env) ──
# Idempotent: if file already on disk with correct size → SKIP without re-download.
# Otherwise: queue in parallel pool (up to DL_POOL_SIZE concurrent). The actual
# wait happens automatically in install.sh via dl_wait_all after each models_<wf>.
dl_hf() {
    local url="$1" dest="$2"
    local name; name=$(basename "$dest")
    local auth="Authorization: Bearer ${HF_TOKEN:-}"
    local result="$DL_RESULT_DIR/skip_$$_$RANDOM.result"

    if [ "$DRY_RUN" = "1" ]; then
        _check_url "$url" "$name" "$auth"
        return 0
    fi

    # Skip if already present AND size matches HF (and no .aria2 partial file).
    # SKIP path is synchronous: increments DL_SKIP in parent shell directly,
    # no result file needed (those are only for async workers).
    if [ -f "$dest" ] && [ ! -f "${dest}.aria2" ]; then
        local actual; actual=$(stat -c%s "$dest" 2>/dev/null || echo 0)
        local expected; expected=$(_hf_get_size "$url" "$auth")
        if [ "$expected" -gt 0 ] && [ "$actual" = "$expected" ]; then
            log "SKIP: $name (size $actual verified)"
            DL_SKIP=$((DL_SKIP + 1))
            return 0
        fi
        if [ "$expected" = "0" ] && [ "$actual" -gt 1000000 ]; then
            # HF didn't give size, fall back to legacy >1MB heuristic
            log "SKIP: $name (no size info, fallback heuristic)"
            DL_SKIP=$((DL_SKIP + 1))
            return 0
        fi
        warn "Re-downloading $name: size mismatch ($actual vs $expected)"
        rm -f "$dest" "${dest}.aria2"
    fi

    log "Queue: $name (pool: ${#DL_POOL_PIDS[@]}/$DL_POOL_SIZE)"
    _dl_pool_wait_slot
    _dl_worker "$url" "$dest" "$auth" &
    DL_POOL_PIDS+=($!)
}

# ── Download: HuggingFace (public, no auth) ──
dl_pub() {
    local url="$1" dest="$2"
    local name; name=$(basename "$dest")

    if [ "$DRY_RUN" = "1" ]; then
        _check_url "$url" "$name"
        return 0
    fi

    if [ -f "$dest" ] && [ ! -f "${dest}.aria2" ]; then
        local actual; actual=$(stat -c%s "$dest" 2>/dev/null || echo 0)
        local expected; expected=$(_hf_get_size "$url" "")
        if [ "$expected" -gt 0 ] && [ "$actual" = "$expected" ]; then
            log "SKIP: $name (size $actual verified)"
            DL_SKIP=$((DL_SKIP + 1))
            return 0
        fi
        if [ "$expected" = "0" ] && [ "$actual" -gt 1000000 ]; then
            log "SKIP: $name (no size info, fallback heuristic)"
            DL_SKIP=$((DL_SKIP + 1))
            return 0
        fi
        warn "Re-downloading $name: size mismatch ($actual vs $expected)"
        rm -f "$dest" "${dest}.aria2"
    fi

    log "Queue: $name (pool: ${#DL_POOL_PIDS[@]}/$DL_POOL_SIZE)"
    _dl_pool_wait_slot
    _dl_worker "$url" "$dest" "" &
    DL_POOL_PIDS+=($!)
}

# ── Download: CivitAI (with $CIVITAI_TOKEN) ──
# CivitAI does not provide X-Linked-Size, so falls back to >1MB heuristic.
dl_civitai() {
    local model_id="$1" dest="$2"
    local name; name=$(basename "$dest")
    local tok="${CIVITAI_TOKEN:-}"
    local url="https://civitai.com/api/download/models/${model_id}?type=Model&format=SafeTensor&token=$tok"

    if [ "$DRY_RUN" = "1" ]; then
        if [ -z "$tok" ]; then
            warn "CIVITAI_TOKEN not set — cannot verify $name"
            DL_FAIL=$((DL_FAIL + 1))
        else
            _check_url "$url" "$name"
        fi
        return 0
    fi

    if [ -f "$dest" ] && [ ! -f "${dest}.aria2" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 1000000 ]; then
        log "SKIP: $name (exists)"
        DL_SKIP=$((DL_SKIP + 1))
        return 0
    fi

    if [ -z "$tok" ]; then
        warn "CIVITAI_TOKEN not set, skipping $name"
        DL_FAIL=$((DL_FAIL + 1))
        return 1
    fi

    log "Queue: $name (CivitAI, pool: ${#DL_POOL_PIDS[@]}/$DL_POOL_SIZE)"
    _dl_pool_wait_slot
    _dl_worker "$url" "$dest" "" &
    DL_POOL_PIDS+=($!)
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
            mkdir -p "$(dirname "$link")"   # линк может вести в несуществующую подпапку (напр. diffusion_models/MelBandRoformer/)
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
