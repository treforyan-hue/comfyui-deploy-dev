#!/usr/bin/env bash
# Animator V2.5 — Wan 2.2 Animate 14B + Uni3C ControlNet + SAM2
# GPU: 24GB+ | Models: ~30GB | Time: ~60 min
# Based on ANIMATOR+V2.5.json

models_animator_v25() {
    section "Models: Animator V2.5 (Wan 2.2 Animate + Uni3C)"

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

    # Uni3C ControlNet
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors" \
        "$MODELS/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors"

    # Detection (ViTPose H + YOLOv10m)
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx" \
        "$MODELS/detection/vitpose_h_wholebody_model.onnx"
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin" \
        "$MODELS/detection/vitpose_h_wholebody_data.bin"
    dl_hf "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODELS/detection/yolov10m.onnx"

    # SAM2
    dl_hf "https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2.1_hiera_base_plus.safetensors" \
        "$MODELS/sam2/sam2.1_hiera_base_plus.safetensors"

    # LoRAs
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
        "$MODELS/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"
    dl_hf "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors" \
        "$MODELS/loras/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1-low_noise_model.safetensors"
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
        "$MODELS/loras/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors"
    dl_hf "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" \
        "$MODELS/loras/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors"
}
