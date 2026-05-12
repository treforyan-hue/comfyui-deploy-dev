#!/usr/bin/env bash
# OFMTech Identity Swap — Flux 2 Klein 9b multi-reference identity swap
# GPU: 24GB+ | Models: ~18GB | Time: ~5 min
# License: Flux 2 is gated — user's HF token must be Classic Read + accept BFL license
# at https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8

models_ofmtech_identity_swap() {
    section "Models: OFMTech Identity Swap (Flux 2 Klein 9b)"

    # Flux 2 Klein 9b fp8 (gated — needs Classic HF token + license accept)
    dl_hf "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" \
        "$MODELS/diffusion_models/Flux-2-Klein-9b-fp8.safetensors"

    # Qwen 3 8B text encoder (Comfy-Org repackaged single-file)
    dl_hf "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b.safetensors" \
        "$MODELS/text_encoders/qwen_3_8b.safetensors"

    # Flux 2 VAE
    dl_hf "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
        "$MODELS/vae/flux2-vae.safetensors"
}
