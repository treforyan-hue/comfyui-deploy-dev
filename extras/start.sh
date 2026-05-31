#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Custom container start.sh for jkhlk/comfyui-ready:runpod
#
# Replaces runpod/pytorch base's /start.sh which had two bugs:
#   1. `set -e` on line 2 — a single non-zero exit anywhere kills
#      the script before sshd starts.
#   2. `ssh-keygen -t dsa` — DSA was removed in OpenSSH 9.8+, so
#      on newer openssh binaries this fails under set -e and aborts
#      the whole script. Result: publicIp allocated but port 22
#      dead (ConnectionRefused).
#
# Our version:
#   - NO `set -e` (each step has its own error handling)
#   - NO DSA (only rsa + ecdsa + ed25519 host keys)
#   - Same logical flow: nginx → PUBLIC_KEY → sshd → env export
#     → /post_start.sh → sleep infinity
#   - Same env export to /etc/rp_environment so SSH sessions see
#     HF_TOKEN / CIVITAI_TOKEN / WORKFLOW_ID
# ══════════════════════════════════════════════════════════════
set +e  # explicitly disable strict mode

echo "[start.sh] === ComfyUI Ready :runpod ==="
date

# 1. nginx (inherited from runpod base image — provides internal proxy)
if command -v nginx >/dev/null 2>&1; then
    echo "[start.sh] starting nginx"
    service nginx start 2>/dev/null || nginx 2>/dev/null || true
fi

# 2. pre_start hook (optional)
if [ -f /pre_start.sh ]; then
    echo "[start.sh] running /pre_start.sh"
    bash /pre_start.sh || echo "[start.sh] pre_start.sh exit non-zero (continuing)"
fi

# 3. SSH setup — the CRITICAL part we fixed
if [ -n "$PUBLIC_KEY" ]; then
    echo "[start.sh] setting up SSH from PUBLIC_KEY"
    mkdir -p /root/.ssh
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys

    # Generate host keys if missing — MODERN TYPES ONLY (no DSA)
    for keytype in rsa ecdsa ed25519; do
        key_file="/etc/ssh/ssh_host_${keytype}_key"
        if [ ! -f "$key_file" ]; then
            echo "[start.sh] generating $keytype host key"
            ssh-keygen -t "$keytype" -f "$key_file" -q -N "" 2>/dev/null || \
                echo "[start.sh] WARN: ssh-keygen $keytype failed (continuing)"
        fi
    done

    # Make sure sshd runtime dir exists (required by some openssh builds)
    mkdir -p /run/sshd

    # Start sshd — try `service` first, fall back to direct invocation
    echo "[start.sh] starting sshd"
    if service ssh start 2>/dev/null; then
        echo "[start.sh] sshd started via service"
    elif /usr/sbin/sshd 2>/dev/null; then
        echo "[start.sh] sshd started directly"
    else
        # Last resort: background daemon mode
        /usr/sbin/sshd -D &
        echo "[start.sh] sshd started in background (-D)"
    fi

    # Verify sshd is actually listening on :22
    sleep 1
    if ss -tln 2>/dev/null | grep -q ':22 ' || netstat -tln 2>/dev/null | grep -q ':22 '; then
        echo "[start.sh] ✓ sshd is listening on :22"
    else
        echo "[start.sh] ✗ WARN: sshd not listening on :22 after start attempts"
    fi
else
    echo "[start.sh] WARN: PUBLIC_KEY not set — skipping sshd setup"
fi

# 4. Export env vars so interactive SSH sessions inherit them
echo "[start.sh] exporting env vars to /etc/rp_environment"
printenv | grep -E '^[A-Z_][A-Z0-9_]*=' | grep -v '^PUBLIC_KEY' | \
    awk -F = '{val=$0; sub(/^[^=]*=/, "", val); print "export " $1 "=\"" val "\""}' \
    > /etc/rp_environment 2>/dev/null || true
if ! grep -q 'source /etc/rp_environment' /root/.bashrc 2>/dev/null; then
    echo 'source /etc/rp_environment' >> /root/.bashrc
fi

# 5. post_start hook — where ComfyUI + install.sh are kicked
if [ -f /post_start.sh ]; then
    echo "[start.sh] running /post_start.sh"
    bash /post_start.sh || echo "[start.sh] post_start.sh exit non-zero (continuing)"
else
    echo "[start.sh] WARN: /post_start.sh not found"
fi

echo "[start.sh] === init done — entering sleep infinity ==="
sleep infinity
