#!/usr/bin/env bash
# OFM FaceSWP+ — Face swap with Flux 2 Klein 9B (bf16)
# GPU: 24GB+ | Models: ~20GB | Time: ~60 min
# Source: 7.Команды JupyterTerminal.txt

models_ofm_faceswp() {
    section "Models: FaceSWP+ (Flux 2 Klein 9B bf16)"

    dl_hf "https://huggingface.co/black-forest-labs/FLUX.2-klein-9B/resolve/main/flux-2-klein-9b.safetensors" \
        "$MODELS/unet/flux-2-klein-9b.safetensors"

    dl_hf "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
        "$MODELS/vae/flux2-vae.safetensors"

    dl_hf "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b.safetensors" \
        "$MODELS/text_encoders/qwen_3_8b.safetensors"
}
