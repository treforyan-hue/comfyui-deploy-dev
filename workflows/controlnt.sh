#!/usr/bin/env bash
# ControllNT v1 + v2 — Z-Image-Turbo ControlNet
# GPU: 12GB+ | Models: ~12GB | Time: ~30 min
# Source: 3.Команды + 4.Команды JupyterTerminal.txt

models_controlnt() {
    section "Models: ControllNT (Z-Image-Turbo ControlNet)"

    # Z-Image-Turbo unet
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
        "$MODELS/unet/z_image_turbo_bf16.safetensors"

    # Text encoder Qwen 3 4B
    dl_hf "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
        "$MODELS/text_encoders/qwen_3_4b.safetensors"

    # VAE (public mirror)
    dl_pub "https://huggingface.co/camenduru/FLUX.1-dev-ungated/resolve/main/ae.safetensors" \
        "$MODELS/vae/ae.safetensors"
    make_link "$MODELS/vae/ae.safetensors" "$MODELS/vae/flux_vae.safetensors"

    # ControlNet Union 2.1 (v1 uses this)
    dl_hf "https://huggingface.co/alibaba-pai/Z-Image-Turbo-Fun-Controlnet-Union-2.1/resolve/main/Z-Image-Turbo-Fun-Controlnet-Union-2.1-2602-8steps.safetensors" \
        "$MODELS/model_patches/Z-Image-Turbo-Fun-Controlnet-Union-2.1-2602-8steps.safetensors"
    # Symlink for JSON compatibility (workflow uses shorter name)
    make_link "$MODELS/model_patches/Z-Image-Turbo-Fun-Controlnet-Union-2.1-2602-8steps.safetensors" \
        "$MODELS/model_patches/Z-Image-Turbo-Fun-Controlnet-Union-2.1.safetensors"

    # ControlNet Union older (v2 uses this)
    dl_hf "https://huggingface.co/alibaba-pai/Z-Image-Turbo-Fun-Controlnet-Union/resolve/main/Z-Image-Turbo-Fun-Controlnet-Union.safetensors" \
        "$MODELS/model_patches/Z-Image-Turbo-Fun-Controlnet-Union.safetensors"
}
