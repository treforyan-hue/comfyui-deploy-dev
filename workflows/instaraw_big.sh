#!/usr/bin/env bash
# INSTARAW BIG — NanoBanana / Gemini API batch image generator
# GPU: 12GB+ (minimal — only ComfyUI overhead) | Models: 0GB | Time: ~3 min
# User provides their own Google Gemini API key in the workflow

models_instaraw_big() {
    section "Models: INSTARAW BIG (no models — Gemini API workflow)"
    log "No model downloads — workflow uses Google Gemini API (user-provided key)"
}
