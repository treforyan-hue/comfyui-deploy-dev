#!/usr/bin/env bash
# INSTARAW WAN 2.2 — T2I via WAN 2.2 T2V high/low noise + SDXL FaceDetailer
# GPU: 48GB+ | Models: ~70GB | Time: ~40 min
# Image-only output despite WAN T2V base (no VHS_VideoCombine in workflow)

models_instaraw_wan22() {
    section "Models: INSTARAW WAN 2.2 (T2I)"

    # WAN 2.2 T2V 14B fp16 (LARGE: 28GB each — high + low noise variants)
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp16.safetensors" \
        "$MODELS/diffusion_models/wan2.2_t2v_high_noise_14B_fp16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors" \
        "$MODELS/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors"

    # SDXL checkpoint for FaceDetailer (mirrored to fwwrsd HF)
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/checkpoints/lustifySDXLNSFW_ggwpV7.safetensors" \
        "$MODELS/checkpoints/SDXL/lustifySDXLNSFW_ggwpV7.safetensors"

    # WAN VAE + text encoder
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
        "$MODELS/vae/wan_2.1_vae.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODELS/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

    # Instara realism LoRAs
    dl_pub "https://huggingface.co/Instara/instareal-wan-2.2/resolve/main/Instareal_high.safetensors" \
        "$MODELS/loras/Instareal_high.safetensors"
    dl_pub "https://huggingface.co/Instara/instareal-wan-2.2/resolve/main/Instareal_low.safetensors" \
        "$MODELS/loras/Instareal_low.safetensors"

    # Lightx2v rank32 distill LoRA
    dl_hf "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors" \
        "$MODELS/loras/Wan/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors"

    # Lenovo UltraReal LoRA (Danrisi mirror)
    dl_pub "https://huggingface.co/Danrisi/LenovoWan/resolve/main/Lenovo.safetensors" \
        "$MODELS/loras/Wan/2.2/Wan2.2Lenovo.safetensors"

    # SDXL DMD2 + detail LoRAs
    dl_hf "https://huggingface.co/tianweiy/DMD2/resolve/main/dmd2_sdxl_4step_lora_fp16.safetensors" \
        "$MODELS/loras/SDXL/dmd2_sdxl_4step_lora_fp16.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/Detailed_Nipples_XL_v1.0.safetensors" \
        "$MODELS/loras/detailed_nipples.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/lady_hand.safetensors" \
        "$MODELS/loras/lady_hand.safetensors"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/real_feet.safetensors" \
        "$MODELS/loras/real_feet.safetensors"

    # SAM + Bbox detectors
    dl_pub "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" \
        "$MODELS/sams/sam_vit_b_01ec64.pth"
    dl_pub "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
        "$MODELS/ultralytics/bbox/face_yolov8m.pt"
    dl_pub "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8s.pt" \
        "$MODELS/ultralytics/bbox/hand_yolov8s.pt"
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/ultralytics/bbox/feet.pt" \
        "$MODELS/ultralytics/bbox/feet.pt"

    # Instara NSFW bbox detectors (rename to lowercase to match JSON)
    dl_pub "https://huggingface.co/Instara/bboxs/resolve/main/Nipples.pt" \
        "$MODELS/ultralytics/bbox/nipples.pt"
    dl_pub "https://huggingface.co/Instara/bboxs/resolve/main/Pussy.pt" \
        "$MODELS/ultralytics/bbox/pussy.pt"
    dl_pub "https://huggingface.co/Kentus/Adetailer/resolve/main/lips_v1.pt" \
        "$MODELS/ultralytics/bbox/lips_v1.pt"

    # Upscaler
    dl_pub "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2.pth" \
        "$MODELS/upscale_models/4x-UltraSharpV2.pth"
}
