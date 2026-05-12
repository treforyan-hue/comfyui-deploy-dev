#!/usr/bin/env bash
# Tokyo Sage — Wan 2.2 Animate (alternate I2V workflow, same models as ofm_tech_v2)
# GPU: 80GB+ | Models: ~50GB | Time: ~30 min
# Note: shares the entire model set with ofm_tech_v2 (same WAN 2.2 Animate base + LoRAs)

models_tokyo_sage() {
    section "Models: Tokyo Sage (Wan 2.2 Animate bf16)"

    # Wan 2.2 Animate 14B bf16 (LARGE: 28GB)
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_animate_14B_bf16.safetensors" \
        "$MODELS/diffusion_models/wan2.2_animate_14B_bf16.safetensors"

    # VAE
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
        "$MODELS/vae/Wan2_1_VAE_bf16.safetensors"

    # Text encoders
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp16.safetensors"

    # CLIP vision
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        "$MODELS/clip_vision/clip_vision_h.safetensors"

    # Detection + SAM
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx" \
        "$MODELS/detection/vitpose_h_wholebody_model.onnx"
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin" \
        "$MODELS/detection/vitpose_h_wholebody_data.bin"
    dl_hf "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODELS/detection/yolov10m.onnx"
    dl_hf "https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2.1_hiera_base_plus.safetensors" \
        "$MODELS/sam2/sam2.1_hiera_base_plus.safetensors"

    # RIFE (public mirror — Fannovel16 repo requires auth)
    dl_pub "https://huggingface.co/VMTamashii/rife49/resolve/main/rife49.pth" \
        "$MODELS/rife/rife49.pth"
    make_link "$MODELS/rife/rife49.pth" "$CNODES/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth"

    # LoRAs
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors" \
        "$MODELS/loras/wan2.2_animate14B_relight_lora_bf16.safetensors"
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank256_bf16.safetensors" \
        "$MODELS/loras/lightx2vT2V14B_cfg_step_distillv2_lora_rank256_bf16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
        "$MODELS/loras/wan2.2_iv_lightx2v_4steps_lora_v1_low_noise.safetensors"
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
        "$MODELS/loras/Wan2.1PusaLoRA14B_rank512_bf16.safetensors"
    dl_hf "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-MPS.safetensors" \
        "$MODELS/loras/Wan2.2-Fun-A14B-Inp-low-noise-MPS.safetensors"
}
