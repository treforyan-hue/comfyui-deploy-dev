#!/usr/bin/env bash
# OFM Dataset-Gen — Florence2 + WD14 captioning
# GPU: 8GB+ | Models: ~2GB (auto-downloaded by nodes) | Time: ~15 min

models_ofm_dataset_gen() {
    section "Models: Dataset-Gen (Florence2 + WD14)"
    # Florence2 and WD14 models are auto-downloaded by their nodes on first use
    # No manual downloads needed
    log "Florence2 and WD14 models will auto-download on first use"
}
