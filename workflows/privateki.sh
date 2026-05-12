#!/usr/bin/env bash
# PrivateKI — Wan 2.2 Animate dance/pose animation
# GPU: 24GB+ | Models: ~27GB | Time: ~60 min

models_privateki() {
    section "Models: PrivateKI (Wan 2.2 Animate)"

    # Wan 2.2 Animate 14B fp8
    dl_hf "https://huggingface.co/GerbyHorty76/videoloras/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
        "$MODELS/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"

    # VAE
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
        "$MODELS/vae/Wan2_1_VAE_bf16.safetensors"
    make_link "$MODELS/vae/Wan2_1_VAE_bf16.safetensors" "$MODELS/vae/wan_2.1_vae.safetensors"

    # Text encoders
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

    # CLIP vision
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        "$MODELS/clip_vision/clip_vision_h.safetensors"

    # Detection
    dl_pub "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" \
        "$MODELS/detection/vitpose-l-wholebody.onnx"
    dl_hf "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODELS/detection/yolov10m.onnx"

    # LoRAs
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
        "$MODELS/loras/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors"
    dl_hf "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" \
        "$MODELS/loras/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
        "$MODELS/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
        "$MODELS/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"

    # SAM2 (used by DownloadAndLoadSAM2Model node)
    dl_hf "https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2.1_hiera_large.safetensors" \
        "$MODELS/sam2/sam2.1_hiera_large.safetensors"
}
