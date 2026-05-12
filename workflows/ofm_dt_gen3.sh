#!/usr/bin/env bash
# OFM DT-Gen3 — Flux 2 Klein image generation
# GPU: 16GB+ | Models: ~15GB | Time: ~45 min
# Source: 6.Команды JupyterTerminal.txt

models_ofm_dt_gen3() {
    section "Models: DT-Gen3 (Flux 2 Klein 9B fp8)"

    dl_hf "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" \
        "$MODELS/unet/flux-2-klein-9b-fp8.safetensors"

    dl_hf "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
        "$MODELS/vae/flux2-vae.safetensors"

    dl_hf "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
        "$MODELS/text_encoders/qwen_3_8b_fp8mixed.safetensors"
}
