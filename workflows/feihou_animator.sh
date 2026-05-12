#!/usr/bin/env bash
# FeiHou Animator — Wan 2.2 Animate 14B + SDPose + SAM3 + Batch
# GPU: 24GB+ | Models: ~35GB | Time: ~90 min
# Source: workflow_By_FeiHou.json (三层楼的小肥猴)

models_feihou_animator() {
    section "Models: FeiHou Animator (Wan 2.2 Animate + SDPose + SAM3)"

    # Wan 2.2 Animate 14B fp8
    dl_hf "https://huggingface.co/GerbyHorty76/videoloras/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
        "$MODELS/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
    # Symlink for FeiHou JSON compatibility (uses dot instead of underscore)
    make_link "$MODELS/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
        "$MODELS/diffusion_models/Wan2.2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"

    # VAE
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
        "$MODELS/vae/Wan2_1_VAE_bf16.safetensors"
    make_link "$MODELS/vae/Wan2_1_VAE_bf16.safetensors" "$MODELS/vae/wan_2.1_vae.safetensors"

    # Text encoder
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    make_link "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"

    # Text encoder non-scaled (WanVideoWrapper не поддерживает scaled_fp8, перезаписывает симлинк)
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-fp8_e4m3fn.safetensors" \
        "$MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"

    # CLIP vision
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        "$MODELS/clip_vision/clip_vision_h.safetensors"

    # SDPose model (comfy-core 0.17+ SDPoseKeypointExtractor, checkpoints/ subdir on HF repo)
    dl_hf "https://huggingface.co/Comfy-Org/SDPose/resolve/main/checkpoints/sdpose_wholebody_fp16.safetensors" \
        "$MODELS/checkpoints/sdpose_wholebody_fp16.safetensors"

    # Detection (ViTPose L + YOLOv10m)
    dl_pub "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" \
        "$MODELS/detection/vitpose-l-wholebody.onnx"
    dl_hf "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODELS/detection/yolov10m.onnx"

    # Uni3C ControlNet (bypassed by default but available)
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors" \
        "$MODELS/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors"

    # SAM2 (for masking)
    dl_hf "https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2.1_hiera_base_plus.safetensors" \
        "$MODELS/sam2/sam2.1_hiera_base_plus.safetensors"

    # SAM3 (Meta) — reupload on fwwrsd/feihou-assets with LICENSE alongside (SAM License §1.b.i)
    dl_pub "https://huggingface.co/fwwrsd/feihou-assets/resolve/main/sam3/sam3.pt" \
        "$MODELS/sam3/sam3.pt"
    dl_pub "https://huggingface.co/fwwrsd/feihou-assets/resolve/main/sam3/LICENSE" \
        "$MODELS/sam3/LICENSE"

    # LoRAs (subfolder structure as FeiHou expects)
    mkdir -p "$MODELS/loras/Wan-Enhance" "$MODELS/loras/Wan-Lighting" "$MODELS/loras/Wan-Action"

    # Relight LoRA
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors" \
        "$MODELS/loras/Wan-Enhance/Wan2.1 - WanAnimate_relight_lora_fp16.safetensors"

    # LightX2V distillation LoRA (speed)
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
        "$MODELS/loras/Wan-Lighting/Wan2.1 - lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"

    # Pusa quality LoRA
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
        "$MODELS/loras/Wan-Enhance/Wan2.1 - PusaV1_LoRA_14B_rank512_bf16.safetensors"

    # HPS 2.1 aesthetic LoRA
    dl_hf "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" \
        "$MODELS/loras/Wan-Enhance/Wan2.1 - Fun-14B-InP-HPS2.1.safetensors"

    # Bounce / Jiggling LoRAs (Wan-Action subfolder)
    dl_pub "https://huggingface.co/fwwrsd/feihou-assets/resolve/main/Wan-Action/Wan2.2%20-%20I2V%20-%20Slop-Bounce-Low.safetensors" \
        "$MODELS/loras/Wan-Action/Wan2.2 - I2V - Slop-Bounce-Low.safetensors"
    # JSON references "Bounce-Test - Low" — symlink so the workflow resolves it
    make_link "$MODELS/loras/Wan-Action/Wan2.2 - I2V - Slop-Bounce-Low.safetensors" \
        "$MODELS/loras/Wan-Action/Wan2.2 - I2V - Bounce-Test - Low.safetensors"

    dl_pub "https://huggingface.co/fwwrsd/feihou-assets/resolve/main/Wan-Action/Wan2.1%20-%20I2V%20-%20Bouncing-Jiggling.safetensors" \
        "$MODELS/loras/Wan-Action/Wan2.1 - I2V - Bouncing-Jiggling.safetensors"
}
