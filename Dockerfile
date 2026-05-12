# ══════════════════════════════════════════════════════════════
# ComfyUI Ready Image v3 — PINNED VERSIONS
#
# ALL components pinned to specific commits for stability.
# PyTorch 2.11 + CUDA 13 + torchaudio
# Does NOT contain models (downloaded at runtime per workflow)
# ══════════════════════════════════════════════════════════════

FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV COMFY=/workspace/ComfyUI
ENV CNODES=/workspace/ComfyUI/custom_nodes

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ffmpeg libgl1 libglib2.0-0 aria2 \
    && rm -rf /var/lib/apt/lists/*

# ── PyTorch 2.11 + torchaudio + CUDA 13 ──
RUN pip install --break-system-packages --no-cache-dir \
    torch==2.11.0 torchaudio torchvision \
    --index-url https://download.pytorch.org/whl/cu130

# Symlink nvrtc-builtins
RUN NVRTC_PATH=$(find /usr/local/lib/python3.11 -name "libnvrtc-builtins.so.13*" -not -name "*.alt.*" 2>/dev/null | head -1) \
    && if [ -n "$NVRTC_PATH" ]; then \
         ln -sf "$NVRTC_PATH" /usr/lib/x86_64-linux-gnu/libnvrtc-builtins.so.13.0; \
       fi

RUN python3 -c "import torch; print('PyTorch:', torch.__version__); import torchaudio; print('torchaudio:', torchaudio.__version__)"

# ── ComfyUI (PINNED) ──
RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFY \
    && cd $COMFY && git checkout 4b1444f \
    && pip install --break-system-packages --no-cache-dir -q -r requirements.txt

# Create model directories
RUN mkdir -p $COMFY/models/{diffusion_models,unet,vae,text_encoders,clip,clip_vision} \
    && mkdir -p $COMFY/models/{loras,checkpoints,upscale_models,detection,sam2,sams,rife} \
    && mkdir -p $COMFY/models/{controlnet,model_patches,seedvr2} \
    && mkdir -p $COMFY/models/ultralytics/{bbox,segm} \
    && mkdir -p $COMFY/user/default/workflows

# ══════════════════════════════════════════════════════════════
# Custom Nodes — ALL PINNED to tested commits
# ══════════════════════════════════════════════════════════════

# Helper to clone at specific commit
# Usage: clone_pinned <url> <commit> <dir>
# git clone full then checkout (can't clone single commit without depth issues)

# Core nodes
RUN git clone https://github.com/kijai/ComfyUI-KJNodes $CNODES/ComfyUI-KJNodes && cd $CNODES/ComfyUI-KJNodes && git checkout 068d4fe
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper $CNODES/ComfyUI-WanVideoWrapper && cd $CNODES/ComfyUI-WanVideoWrapper && git checkout df8f3e4
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite $CNODES/ComfyUI-VideoHelperSuite && cd $CNODES/ComfyUI-VideoHelperSuite && git checkout 4498399
RUN git clone https://github.com/rgthree/rgthree-comfy $CNODES/rgthree-comfy && cd $CNODES/rgthree-comfy && git checkout 8ff50e4
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use $CNODES/ComfyUI-Easy-Use && cd $CNODES/ComfyUI-Easy-Use && git checkout 8ba21d0
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts $CNODES/ComfyUI-Custom-Scripts && cd $CNODES/ComfyUI-Custom-Scripts && git checkout 609f3af
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack $CNODES/ComfyUI-Impact-Pack && cd $CNODES/ComfyUI-Impact-Pack && git checkout 6a517eb

# Video / Animation
RUN git clone https://github.com/kijai/ComfyUI-segment-anything-2 $CNODES/ComfyUI-segment-anything-2 && cd $CNODES/ComfyUI-segment-anything-2 && git checkout 0c35fff
RUN git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess $CNODES/ComfyUI-WanAnimatePreprocess && cd $CNODES/ComfyUI-WanAnimatePreprocess && git checkout 1a35b81
RUN git clone https://github.com/kijai/ComfyUI-SCAIL-Pose $CNODES/ComfyUI-SCAIL-Pose && cd $CNODES/ComfyUI-SCAIL-Pose && git checkout 11402b1
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation $CNODES/ComfyUI-Frame-Interpolation && cd $CNODES/ComfyUI-Frame-Interpolation && git checkout 26545cc
RUN git clone https://github.com/vrgamegirl19/comfyui-vrgamedevgirl $CNODES/comfyui-vrgamedevgirl && cd $CNODES/comfyui-vrgamedevgirl && git checkout 233bca8

# ControlNet / Image
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux $CNODES/comfyui_controlnet_aux && cd $CNODES/comfyui_controlnet_aux && git checkout 95a13e2
RUN git clone https://github.com/ClownsharkBatwing/RES4LYF $CNODES/RES4LYF && cd $CNODES/RES4LYF && git checkout 0dc91c0
RUN git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler $CNODES/ComfyUI-SeedVR2_VideoUpscaler && cd $CNODES/ComfyUI-SeedVR2_VideoUpscaler && git checkout 4490bd1
RUN git clone https://github.com/cubiq/ComfyUI_essentials $CNODES/ComfyUI_essentials && cd $CNODES/ComfyUI_essentials && git checkout 9d9f4be
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus $CNODES/ComfyUI_IPAdapter_plus && cd $CNODES/ComfyUI_IPAdapter_plus && git checkout a0f451a
RUN git clone https://github.com/erosDiffusion/ComfyUI-EulerDiscreteScheduler $CNODES/ComfyUI-EulerDiscreteScheduler && cd $CNODES/ComfyUI-EulerDiscreteScheduler && git checkout eb5bd4d

# Utility
RUN git clone https://github.com/city96/ComfyUI-GGUF $CNODES/ComfyUI-GGUF && cd $CNODES/ComfyUI-GGUF && git checkout 6ea2651
RUN git clone https://github.com/kijai/ComfyUI-Florence2 $CNODES/ComfyUI-Florence2 && cd $CNODES/ComfyUI-Florence2 && git checkout 4051662
RUN git clone https://github.com/pythongosssss/ComfyUI-WD14-Tagger $CNODES/ComfyUI-WD14-Tagger && cd $CNODES/ComfyUI-WD14-Tagger && git checkout 9e0a6e7
RUN git clone https://github.com/digitaljohn/comfyui-propost $CNODES/comfyui-propost && cd $CNODES/comfyui-propost && git checkout df6a6d1
RUN git clone https://github.com/PGCRT/CRT-Nodes $CNODES/CRT-Nodes && cd $CNODES/CRT-Nodes && git checkout 7abbf87
RUN git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon $CNODES/ComfyUI-Detail-Daemon && cd $CNODES/ComfyUI-Detail-Daemon && git checkout 39206d1
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes $CNODES/ComfyUI_Comfyroll_CustomNodes && cd $CNODES/ComfyUI_Comfyroll_CustomNodes && git checkout d78b780
RUN git clone https://github.com/evanspearman/ComfyMath $CNODES/ComfyMath && cd $CNODES/ComfyMath && git checkout c011772
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui $CNODES/efficiency-nodes-comfyui && cd $CNODES/efficiency-nodes-comfyui && git checkout 4579b7d
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale $CNODES/ComfyUI_UltimateSDUpscale && cd $CNODES/ComfyUI_UltimateSDUpscale && git checkout c164c30
RUN git clone https://github.com/Smirnov75/ComfyUI-mxToolkit $CNODES/ComfyUI-mxToolkit && cd $CNODES/ComfyUI-mxToolkit && git checkout 7f7a0e5
RUN git clone https://github.com/daxcay/ComfyUI-DataSet $CNODES/ComfyUI-DataSet && cd $CNODES/ComfyUI-DataSet && git checkout 83a3c72
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle $CNODES/ComfyUI_LayerStyle && cd $CNODES/ComfyUI_LayerStyle && git checkout d94bef1

# Sub-packages
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack $CNODES/ComfyUI-Impact-Subpack && cd $CNODES/ComfyUI-Impact-Subpack && git checkout 50c7b71
RUN git clone https://github.com/filliptm/ComfyUI_Fill-Nodes $CNODES/ComfyUI_Fill-Nodes && cd $CNODES/ComfyUI_Fill-Nodes && git checkout 3d71d2c
RUN git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes $CNODES/ComfyUI_JPS-Nodes && cd $CNODES/ComfyUI_JPS-Nodes && git checkout 0e2a9ac
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui $CNODES/was-node-suite-comfyui && cd $CNODES/was-node-suite-comfyui && git checkout ea935d1
RUN git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui $CNODES/masquerade-nodes-comfyui && cd $CNODES/masquerade-nodes-comfyui && git checkout 432cb4d
RUN git clone https://github.com/jamesWalker55/comfyui-various $CNODES/comfyui-various && cd $CNODES/comfyui-various && git checkout 5bd85aa
RUN git clone https://github.com/SKBv0/ComfyUI_SKBundle $CNODES/ComfyUI_SKBundle && cd $CNODES/ComfyUI_SKBundle && git checkout 1e13687
RUN git clone https://github.com/teskor-hub/comfyui-teskors-utils $CNODES/comfyui-teskors-utils && cd $CNODES/comfyui-teskors-utils && git checkout c4a8cd1

# I2V Gen3
RUN git clone https://github.com/princepainter/Comfyui-PainterFLF2V $CNODES/Comfyui-PainterFLF2V && cd $CNODES/Comfyui-PainterFLF2V && git checkout c81a68f

# I2V Gen3 upscaler (UpscaleWithModelAdvanced)
RUN git clone https://github.com/Artificial-Sweetener/comfyui-WhiteRabbit $CNODES/comfyui-WhiteRabbit && cd $CNODES/comfyui-WhiteRabbit && git checkout 1781562
# Skin Gen3 Float literal
RUN git clone https://github.com/YaserJaradeh/comfyui-yaser-nodes $CNODES/comfyui-yaser-nodes && cd $CNODES/comfyui-yaser-nodes && git checkout 6822585
# FeiHou Animator: SAM3 video segmentation
RUN git clone https://github.com/yolain/ComfyUI-Easy-Sam3 $CNODES/ComfyUI-Easy-Sam3 && cd $CNODES/ComfyUI-Easy-Sam3 && git checkout 88fe578
# FeiHou Animator: Batch segment queue runner
RUN git clone https://github.com/FX-FeiHou/Comfyui-Segment-Queue-Runner $CNODES/Comfyui-Segment-Queue-Runner && cd $CNODES/Comfyui-Segment-Queue-Runner && git checkout 49f85c1
# FeiHou Animator: VRAM cleanup
RUN git clone https://github.com/LAOGOU-666/Comfyui-Memory_Cleanup $CNODES/Comfyui-Memory_Cleanup && cd $CNODES/Comfyui-Memory_Cleanup && git checkout 58de13a
# Kiara Sasat: ImageComparer (bypassed but needed for no red nodes)
# NOTE: requirements.txt removed — it pulls 23 heavy deps (anthropic/groq/mistral etc)
# that are NOT needed for ImageComparer node. The node itself has no special deps.
RUN git clone https://github.com/if-ai/ComfyUI-IF_AI_tools $CNODES/ComfyUI-IF_AI_tools && cd $CNODES/ComfyUI-IF_AI_tools && git checkout 93130d8 && rm -f requirements.txt

# ── Bundled extras ──
COPY extras/ComfyUI_INSTARAW $CNODES/ComfyUI_INSTARAW
COPY extras/KiaraPanels $CNODES/KiaraPanels
COPY extras/ofm-preload $CNODES/ofm-preload
RUN mkdir -p $CNODES/ComfyUI_INSTARAW/js

# ── Bundled extras for 9 new WFs (tokyo_sage, ofmtech_identity_swap, instaraw_*) ──
# Mirrored to treforyan-hue/ofm-nodes-mirror at pinned commits — fully independent
# from upstream authors. Kept in extras/ instead of git clone so a deleted
# upstream repo can't break our build.
COPY extras/a-person-mask-generator   $CNODES/a-person-mask-generator
COPY extras/cg-use-everywhere         $CNODES/cg-use-everywhere
COPY extras/ComfyUI_Swwan             $CNODES/ComfyUI_Swwan
COPY extras/ComfyUI-Batch-Process     $CNODES/ComfyUI-Batch-Process
COPY extras/ComfyUI-RMBG              $CNODES/ComfyUI-RMBG
COPY extras/comfyui_segment_anything  $CNODES/comfyui_segment_anything
COPY extras/LanPaint                  $CNODES/LanPaint
COPY extras/ofmtechclip               $CNODES/ofmtechclip

# ── Install ALL pip requirements ──
RUN for d in $CNODES/*/; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --break-system-packages --no-cache-dir -q -r "$d/requirements.txt" 2>/dev/null || true; \
        fi; \
    done

# ── Post-install fixes ──
RUN cd $CNODES/ComfyUI-Impact-Pack && python install.py 2>/dev/null || true
RUN mkdir -p $CNODES/ComfyUI_UltimateSDUpscale/repositories \
    && git clone --depth 1 https://github.com/Coyote-A/ultimate-upscale-for-automatic1111.git \
       $CNODES/ComfyUI_UltimateSDUpscale/repositories/ultimate_sd_upscale 2>/dev/null || true
RUN mkdir -p $CNODES/ComfyUI-Frame-Interpolation/ckpts/rife

# Extra pip packages
RUN pip install --break-system-packages --no-cache-dir -q \
    sageattention mediapipe==0.10.14 lpips pyexiftool \
    segment_anything imageio-ffmpeg insightface onnxruntime-gpu \
    2>/dev/null || true

# ══════════════════════════════════════════════════════════════
# PATCHES — fix incompatibilities between nodes
# ══════════════════════════════════════════════════════════════

# Fix: ComfyUI_LayerStyle filmgrainer expects PIL but gets numpy from comfyui-propost
# Restore the numpy→PIL conversion that was commented out
RUN sed -i 's/^    img = image$/    img = Image.fromarray((image * 255).astype(np.uint8)).convert("RGB") if isinstance(image, np.ndarray) else image/' \
    $CNODES/ComfyUI_LayerStyle/py/filmgrainer/filmgrainer.py
# Add numpy import if missing
RUN grep -q "import numpy" $CNODES/ComfyUI_LayerStyle/py/filmgrainer/filmgrainer.py || \
    sed -i '1s/^/import numpy as np\n/' $CNODES/ComfyUI_LayerStyle/py/filmgrainer/filmgrainer.py

# ══════════════════════════════════════════════════════════════

# Verify
RUN cd $COMFY && python3 -c "\
import torch; print('torch', torch.__version__); \
import torchaudio; print('torchaudio', torchaudio.__version__); \
print('CUDA build:', torch.version.cuda); \
" && echo "=== ALL CHECKS PASSED ==="

# Cleanup
RUN pip cache purge 2>/dev/null || true \
    && rm -rf /tmp/* /root/.cache/pip

# Copy install scripts
COPY install.sh /workspace/install.sh
COPY lib/ /workspace/lib/
COPY workflows/ /workspace/workflows/

WORKDIR /workspace/ComfyUI

CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--front-end-version", "Comfy-Org/ComfyUI_frontend@1.42.6"]
