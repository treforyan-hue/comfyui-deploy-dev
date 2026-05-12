#!/usr/bin/env bash
# INSTARAW Z-Image — Z-Image Turbo + SDXL FaceDetailer + Upscale
# GPU: 24GB+ | Models: ~12GB | Time: ~12 min

models_instaraw_zimage() {
    section "Models: INSTARAW Z-Image"

    # Z-Image Turbo base
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
        "$MODELS/diffusion_models/z_image_turbo_bf16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
        "$MODELS/text_encoders/qwen_3_4b.safetensors"
    dl_pub "https://huggingface.co/camenduru/FLUX.1-dev-ungated/resolve/main/ae.safetensors" \
        "$MODELS/vae/flux_ae.safetensors"

    # SDXL checkpoint for FaceDetailer
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/checkpoints/lustifySDXLNSFW_ggwpV7.safetensors" \
        "$MODELS/checkpoints/SDXL/lustifySDXLNSFW_ggwpV7.safetensors"

    # SDXL LoRAs (DMD2 + body details)
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

    # Instara NSFW bbox detectors
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
