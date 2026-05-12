#!/usr/bin/env bash
# OFM ZIT-Gen — Z-Image-Turbo + SeedVR2 image generation
# GPU: 12GB+ | Models: ~15GB | Time: ~45 min
# Source: 9.Команды JupyterTerminal.txt

models_ofm_zit_gen() {
    section "Models: ZIT-Gen (Z-Image-Turbo + SeedVR2)"

    # Z-Image-Turbo
    dl_pub "https://huggingface.co/camenduru/FLUX.1-dev-ungated/resolve/main/ae.safetensors" \
        "$MODELS/vae/ae.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
        "$MODELS/unet/z_image_turbo_bf16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
        "$MODELS/text_encoders/qwen_3_4b.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

    # Upscaler
    dl_pub "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x2.pth" \
        "$MODELS/upscale_models/RealESRGAN_x2.pth"

    # SAM + SeedVR2
    dl_pub "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" \
        "$MODELS/sams/sam_vit_b_01ec64.pth"
    dl_hf "https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b_fp16.safetensors" \
        "$MODELS/seedvr2/seedvr2_ema_7b_fp16.safetensors"
    dl_hf "https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors" \
        "$MODELS/seedvr2/ema_vae_fp16.safetensors"

    # Impact Pack detection (for FaceDetailer)
    dl_pub "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
        "$MODELS/ultralytics/bbox/face_yolov8m.pt"

    # LoRAs — mirrored to HF (was CivitAI: 2617751, 2529031, 2466153)
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/Realistic_Snapshot_v5.safetensors" \
        "$MODELS/loras/Realistic_Snapshot_v5.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/Creating_Realistic_v1.safetensors" \
        "$MODELS/loras/Creating_Realistic_v1.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/Z-TURBO_Photography_35mmPhoto_1536.safetensors" \
        "$MODELS/loras/Z-TURBO_Photography_35mmPhoto_1536.safetensors"
}
