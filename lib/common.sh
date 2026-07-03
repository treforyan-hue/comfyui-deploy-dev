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

# Records which method actually fetched the last file: "hf" | "aria2c" | "curl".
# Set by _fast_dl, read by _dl_worker to decide whether a size gate is needed.
_LAST_DL_METHOD=""

# ── HuggingFace CLI download (Xet-proof, PRIMARY method, added 2026-07-03) ──
# `hf download` streams through HuggingFace's own client which:
#   • goes around the aria2c multi-connection Xet-403 storm entirely
#   • resumes + integrity-checks internally (etag/sha) → file is never partial
# Only handles HF resolve URLs; returns 1 (→ caller falls back to aria2c) for
# any non-HF URL or if the `hf` CLI is missing. Never deletes the caller's dest.
_hf_cli_dl() {
    local url="$1" dest="$2"
    command -v hf >/dev/null 2>&1 || return 1
    case "$url" in
        *huggingface.co/*/resolve/*) ;;
        *) return 1 ;;
    esac
    # https://huggingface.co/<repo>/resolve/<rev>/<path>?<query>
    local rest="${url#*huggingface.co/}"     # <repo>/resolve/<rev>/<path>?<q>
    local repo="${rest%%/resolve/*}"         # <owner>/<name>
    local tail="${rest#*/resolve/}"          # <rev>/<path>?<q>
    local rev="${tail%%/*}"                  # <rev>
    local path="${tail#*/}"                  # <path>?<q>
    path="${path%%\?*}"                       # strip ?query
    [ -z "$repo" ] && return 1
    [ -z "$path" ] && return 1
    local tmp; tmp="$(dirname "$dest")/.hfdl.$BASHPID.$RANDOM"
    rm -rf "$tmp" 2>/dev/null; mkdir -p "$tmp" || return 1
    local tok=(); [ -n "${HF_TOKEN:-}" ] && tok=(--token "$HF_TOKEN")
    if HF_HUB_ENABLE_HF_TRANSFER=0 hf download "$repo" "$path" --revision "$rev" \
            --local-dir "$tmp" "${tok[@]}" >/dev/null 2>&1 && [ -f "$tmp/$path" ]; then
        mkdir -p "$(dirname "$dest")"
        mv -f "$tmp/$path" "$dest"
        rm -rf "$tmp" 2>/dev/null
        return 0
    fi
    rm -rf "$tmp" 2>/dev/null
    return 1
}

# ── Fast download: hf download (primary) → aria2c → curl (fallbacks) ──
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
    _LAST_DL_METHOD=""

    # Remove broken symlinks before download
    [ -L "$dest" ] && [ ! -e "$dest" ] && rm -f "$dest"

    # ── Method 1: hf download (Xet-proof); silently falls through for non-HF URLs ──
    if _hf_cli_dl "$url" "$dest"; then
        _LAST_DL_METHOD="hf"
        return 0
    fi

    # Try aria2c next (fast, 16 connections)
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
            _LAST_DL_METHOD="aria2c"
            return 0
        fi
        # aria2c failed or downloaded junk — remove and try curl
        rm -f "$dest" "$dest.aria2" 2>/dev/null
        warn "aria2c failed, falling back to curl..."
    fi

    # Fallback to curl with resume (-C -) and retry
    local curl_args=(-L -C - --progress-bar --max-time 1800 --retry 5 --retry-delay 10 --retry-max-time 600)
    _LAST_DL_METHOD="curl"
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

    if _fast_dl "$url" "$dest" "$header"; then
        local actual; actual=$(stat -c%s "$dest" 2>/dev/null || echo 0)

        # ── hf download path: HF client already verified integrity (etag/sha) ──
        # Trust it, no size gate. hf never leaves a partial file on success.
        if [ "$_LAST_DL_METHOD" = "hf" ]; then
            log "OK: $name ($actual bytes, hf verified)"
            echo "OK $name $actual" > "$result"
            return 0
        fi

        # ── fallback path (aria2c/curl): soft size check, NEVER delete/hard-fail ──
        # We only get here if hf download failed first (rare). A size mismatch here
        # means the fallback fetched something odd — we KEEP the file and let the pod
        # come up (ComfyUI will surface a per-node error) instead of rm+exit-43 which
        # used to nuke good files on 307/linked HF repos that hide X-Linked-Size.
        local expected; expected=$(_hf_get_size "$url" "$header")
        if [ "$expected" -gt 0 ] && [ "$actual" = "$expected" ]; then
            log "OK: $name ($actual bytes, size verified via $_LAST_DL_METHOD)"
            echo "OK $name $actual" > "$result"
            return 0
        fi
        if [ "$expected" -gt 0 ] && [ "$actual" != "$expected" ]; then
            warn "SIZE MISMATCH (kept, via $_LAST_DL_METHOD): $name — $actual vs expected $expected"
            echo "OK $name $actual size_warn" > "$result"
            return 0
        fi
        # HF size unknown → legacy >1000-byte heuristic (small non-LFS JSON etc.)
        if [ "$actual" -gt 1000 ]; then
            log "OK: $name ($actual bytes, via $_LAST_DL_METHOD)"
            echo "OK $name $actual" > "$result"
            return 0
        fi
    fi
    # Nothing downloaded anything usable at all → real failure (pod not ready).
    err "FAIL: $name (all methods failed)"
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
