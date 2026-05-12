#!/usr/bin/env bash
# INSTARAW Bypass MAX — anti-AI-detection post-processing pipeline
# GPU: 12GB+ (minimal) | Models: 0GB | Time: ~3 min
# Pure image processing (Pixel Perturb + GLCM Normalize + Camera Simulation)

models_instaraw_bypass_max() {
    section "Models: INSTARAW Bypass MAX (no models — pure post-processing)"
    log "No model downloads — workflow is pixel-level post-processing only"
}
