#!/usr/bin/env bash
# OFM NSFW++ — INSTARAW photorealism pipeline
# GPU: 16GB+ | Models: ~30GB | Time: ~90 min
# Source: 10.Команды для JupyterTerminal.txt + universal install.sh

models_ofm_nsfw() {
    section "Models: NSFW++ (INSTARAW pipeline)"

    # Z-Image-Turbo base
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
        "$MODELS/unet/z_image_turbo_bf16.safetensors"
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
        "$MODELS/text_encoders/qwen_3_4b.safetensors"
    dl_pub "https://huggingface.co/camenduru/FLUX.1-dev-ungated/resolve/main/ae.safetensors" \
        "$MODELS/vae/ae.safetensors"

    # SDXL checkpoint — mirrored to HF (was CivitAI 2155386)
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/checkpoints/lustifySDXLNSFW_ggwpV7.safetensors" \
        "$MODELS/checkpoints/lustifySDXLNSFW_ggwpV7.safetensors"

    # ControlNet SDXL Union
    dl_hf "https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors" \
        "$MODELS/controlnet/controlnet-union-sdxl-promax.safetensors"

    # DMD2 LoRA
    dl_hf "https://huggingface.co/tianweiy/DMD2/resolve/main/dmd2_sdxl_4step_lora_fp16.safetensors" \
        "$MODELS/loras/dmd2_sdxl_4step_lora_fp16.safetensors"

    # LoRA — mirrored to HF (was CivitAI 368603). Mirror filename uses underscores;
    # target keeps spaces to match JSON exactly.
    dl_pub "https://huggingface.co/fwwrsd/ofm-models/resolve/main/loras/Detailed_Nipples_XL_v1.0.safetensors" \
        "$MODELS/loras/Detailed Nipples XL v1.0.safetensors"

    # Upscalers (filenames match JSON exactly)
    dl_pub "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2.pth" \
        "$MODELS/upscale_models/4x-UltraSharpV2.pth"
    dl_pub "https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/1x-ITF-SkinDiffDetail-Lite-v1.pth" \
        "$MODELS/upscale_models/1x-ITF-SkinDiffDetail-Lite-v1.pth"
    # Symlink for JSON compatibility (workflow uses x1_ prefix)
    make_link "$MODELS/upscale_models/1x-ITF-SkinDiffDetail-Lite-v1.pth" \
        "$MODELS/upscale_models/x1_ITF_SkinDiffDetail_Lite_v1.pth"
    dl_pub "https://huggingface.co/gemasai/4x_NMKD-Superscale-SP_178000_G/resolve/main/4x_NMKD-Superscale-SP_178000_G.pth" \
        "$MODELS/upscale_models/4x_NMKD-Superscale-SP_178000_G.pth"

    # Depth Anything V2
    dl_hf "https://huggingface.co/depth-anything/Depth-Anything-V2-Large/resolve/main/depth_anything_v2_vitl.pth" \
        "$MODELS/checkpoints/depth_anything_v2_vitl.pth"

    # SAM
    dl_pub "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" \
        "$MODELS/sams/sam_vit_b_01ec64.pth"

    # Impact Pack detection models (explicit — not relying on auto-download)
    dl_pub "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
        "$MODELS/ultralytics/bbox/face_yolov8m.pt"
    dl_pub "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8s.pt" \
        "$MODELS/ultralytics/bbox/hand_yolov8s.pt"

    # IPAdapter CLIP vision (for PLUS FACE preset)
    dl_pub "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors" \
        "$MODELS/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors"
    dl_pub "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors" \
        "$MODELS/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"

    # NSFW detection models (nipple, pussy, lips)
    dl_pub "https://huggingface.co/Kentus/Adetailer/resolve/main/nipple.pt" \
        "$MODELS/ultralytics/bbox/nipple.pt"
    dl_pub "https://huggingface.co/art0123/Models_collection/resolve/main/bbox/pussyV2.pt" \
        "$MODELS/ultralytics/bbox/pussyV2.pt"
    dl_pub "https://huggingface.co/Kentus/Adetailer/resolve/main/lips_v1.pt" \
        "$MODELS/ultralytics/bbox/lips_v1.pt"
}
