#!/usr/bin/env bash
# INSTARAW Booba & Glutes — Flux Kontext dev + Instara breasts/butts LoRA
# GPU: 24GB+ | Models: ~18GB | Time: ~5 min

models_instaraw_booba() {
    section "Models: INSTARAW Booba & Glutes (Flux Kontext dev)"

    # Flux Kontext dev fp8 — main edit model
    dl_hf "https://huggingface.co/Comfy-Org/flux1-kontext-dev_ComfyUI/resolve/main/split_files/diffusion_models/flux1-dev-kontext_fp8_scaled.safetensors" \
        "$MODELS/diffusion_models/flux1-dev-kontext_fp8_scaled.safetensors"

    # Flux text encoders
    dl_pub "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
        "$MODELS/clip/clip_l.safetensors"
    dl_pub "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" \
        "$MODELS/clip/t5xxl_fp16.safetensors"

    # Flux VAE (Lumina repackaged also works — same file)
    dl_hf "https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors" \
        "$MODELS/vae/ae.safetensors"

    # Instara breast/butt enhancement LoRA
    dl_pub "https://huggingface.co/Instara/kontext_big_breasts_and_butts/resolve/main/kontext_big_breasts_and_butts.safetensors" \
        "$MODELS/loras/kontext_big_breasts_and_butts.safetensors"
}
