#!/usr/bin/env bash
# OFM Skin Gen3 — Realistic skin/face generation
# GPU: 16GB+ | Models: ~20GB | Time: ~60 min
# Source: 1.Команды JupyterTerminal.txt

models_ofm_skin_gen3() {
    section "Models: OFM Skin Gen3"

    # Checkpoints — mirrored to HF (was CivitAI: 1301668, 1413133, 2593828)
    # Note: 1413133 (ultrarealFineTune_v4) was GGUF on CivitAI but UNETLoader expects safetensors;
    # mirror has the full 23.8GB safetensors version which fixes the existing GGUF→.safetensors rename bug.
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/aidmaRealisticSkin-FLUX-v0.1.safetensors" \
        "$MODELS/loras/aidmaRealisticSkin-FLUX-v0.1.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/unet/ultrarealFineTune_v4.safetensors" \
        "$MODELS/unet/ultrarealFineTune_v4.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/unet/zEpicrealism_turboV1Fp8.safetensors" \
        "$MODELS/unet/zEpicrealism_turboV1Fp8.safetensors"

    # CLIP + T5
    dl_hf "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
        "$MODELS/clip/clip_l.safetensors"
    dl_hf "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors" \
        "$MODELS/clip/t5xxl_fp8_e4m3fn.safetensors"

    # Qwen + ae VAE
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
        "$MODELS/text_encoders/qwen_3_4b.safetensors"
    dl_pub "https://huggingface.co/camenduru/FLUX.1-dev-ungated/resolve/main/ae.safetensors" \
        "$MODELS/vae/ae.safetensors"

    # SeedVR2 (must be in seedvr2/ directory for SeedVR2LoadDiTModel)
    dl_hf "https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors" \
        "$MODELS/seedvr2/ema_vae_fp16.safetensors"
    dl_hf "https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_3b_fp8_e4m3fn.safetensors" \
        "$MODELS/seedvr2/seedvr2_ema_3b_fp8_e4m3fn.safetensors"

    # Upscaler
    dl_pub "https://huggingface.co/LS110824/upscale/resolve/main/4x-ClearRealityV1.pth" \
        "$MODELS/upscale_models/4x-ClearRealityV1.pth"
}
