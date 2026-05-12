#!/usr/bin/env bash
# ICY SCAIL 2 — Wan 2.1 SCAIL + Flux 2 Klein (pose control I2V)
# GPU: 48GB+ | Models: ~50GB | Time: ~120 min

models_icy_scail_2() {
    section "Models: ICY SCAIL 2 (Wan 2.1 SCAIL + Flux 2)"

    # SCAIL model
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/SCAIL/Wan21-14B-SCAIL-preview_fp8_scaled_mixed.safetensors" \
        "$MODELS/diffusion_models/Wan21-14B-SCAIL-preview_fp8_scaled_mixed.safetensors"

    # VAE + text encoders
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
        "$MODELS/vae/Wan2_1_VAE_bf16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        "$MODELS/clip_vision/clip_vision_h.safetensors"

    # Flux 2 Klein 9B fp8 (for ref frame)
    dl_hf "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" \
        "$MODELS/unet/flux-2-klein-9b-fp8.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
        "$MODELS/vae/flux2-vae.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
        "$MODELS/text_encoders/qwen_3_8b_fp8mixed.safetensors"

    # Detection (ViTPose H — needs both model + data files)
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx" \
        "$MODELS/detection/vitpose_h_wholebody_model.onnx"
    dl_pub "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin" \
        "$MODELS/detection/vitpose_h_wholebody_data.bin"
    dl_hf "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODELS/detection/yolov10m.onnx"
    # Symlink for JSON compatibility (some workflows reference as model.onnx)
    make_link "$MODELS/detection/yolov10m.onnx" "$MODELS/detection/model.onnx"

    # Symlinks for JSON compatibility
    make_link "$MODELS/vae/Wan2_1_VAE_bf16.safetensors" "$MODELS/vae/wan_2.1_vae.safetensors"
    make_link "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"

    # LightX2V LoRA
    dl_hf "https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64_fixed.safetensors" \
        "$MODELS/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64_fixed.safetensors"

    # DWPose models (used by DWPreprocessor node)
    dl_pub "https://huggingface.co/yzd-v/DWPose/resolve/main/yolox_l.torchscript.pt" \
        "$COMFY/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v--DWPose/yolox_l.torchscript.pt"
    dl_pub "https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384_bs5.torchscript.pt" \
        "$COMFY/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v--DWPose/dw-ll_ucoco_384_bs5.torchscript.pt"
}
