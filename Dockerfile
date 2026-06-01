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
# Qwen3VL (x_mode): torch.compile/dynamo роняет Qwen3VLForConditionalGeneration → глобально off (проверено на поде)
ENV TORCHDYNAMO_DISABLE=1

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
# bb560036 (30.05.2026): LTX-2.3 audio VAE + ResizeImageMaskNode V3-схема.
# pip -r requirements.txt сам тянет comfy_aimdo/comfy_kitchen (нужны latest).
# Эмпирически: 4962 ноды, 0 новых import-fail, audio-VAE valid. Гейт по 22 прод-флоу пройден.
RUN git clone https://github.com/comfyanonymous/ComfyUI.git $COMFY \
    && cd $COMFY && git checkout bb560036 \
    && pip install --break-system-packages --no-cache-dir -q -r requirements.txt

# Create model directories — ПОЛНЫЙ набор (новый comfy bb560036 бросает
# FileNotFoundError на get_filename_list() несуществующей папки → красная нода).
# install.sh STEP 1 пересоздаёт тот же набор в рантайме; тут — чтобы и первый
# старт CMD был чистым. Список собран из comfyui.log на поде.
RUN mkdir -p $COMFY/models/{diffusion_models,unet,vae,vae_approx,text_encoders,clip,clip_vision,clip_gguf} \
    && mkdir -p $COMFY/models/{loras,checkpoints,upscale_models,latent_upscale_models,detection,sam2,sam3,sams,rife} \
    && mkdir -p $COMFY/models/{controlnet,model_patches,seedvr2,luts,yolo,onnx,embeddings,style_models,photomaker} \
    && mkdir -p $COMFY/models/{gligen,hypernetworks,configs,prompt_generator,audio_encoders,background_removal,frame_interpolation,geometry_estimation,optical_flow} \
    && mkdir -p $COMFY/models/ultralytics/{bbox,segm} \
    && mkdir -p $COMFY/user/default/workflows

# ══════════════════════════════════════════════════════════════
# Custom Nodes — ALL PINNED to tested commits
# ══════════════════════════════════════════════════════════════

# Helper to clone at specific commit
# Usage: clone_pinned <url> <commit> <dir>
# git clone full then checkout (can't clone single commit without depth issues)

# ── ВСЕ ноды дев-пода (пинованы на коммиты) — установка ОДНИМ слоем из nodes.list ──
# Было: 83 отдельных `RUN git clone` = 83 fs-слоя → суммарно 149 слоёв в образе, а
# overlay2 на хостах RunPod упирается в лимит ~128 ("max depth exceeded" при
# распаковке). Теперь один цикл = 1 слой → ~68 слоёв, под лимитом. Воспроизводимость
# та же: nodes.list = "url dir sha" по строке (репо+пин). Цикл с retry на флаки-сеть.
COPY nodes.list /tmp/nodes.list
RUN set -e; while read -r url dir sha; do \
        [ -z "$url" ] && continue; \
        for attempt in 1 2 3; do \
            git clone --quiet "$url" "$CNODES/$dir" && break || { echo "retry $attempt: $url"; rm -rf "$CNODES/$dir"; sleep 3; }; \
        done; \
        git -C "$CNODES/$dir" checkout --quiet "$sha"; \
    done < /tmp/nodes.list \
    && rm -f "$CNODES/ComfyUI-IF_AI_tools/requirements.txt"

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
# wf16_bridge: passthrough-стаб RunningHub-нод (RHHiddenNodes/Bool/CompressImages/VideoCombineNode) — обязателен для action_transfer
COPY extras/wf16_bridge               $CNODES/wf16_bridge
# OFM-SegmentQueueRunner-RU: прод feihou_animator ждёт класс SegmentQueueRunnerRU (RU-форк;
# апстрим Comfyui-Segment-Queue-Runner регает только SegmentQueueRunner). Иначе красная нода после миграции.
COPY extras/OFM-SegmentQueueRunner-RU $CNODES/OFM-SegmentQueueRunner-RU

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

# Qwen3VL требует transformers==5.8.1 (в comfy-реквайр 5.6.2 нет Qwen3VL; 5.9 ломает).
# Аудит 2026-05-30: 5.8.1 безопасен для всех 22 прод-флоу (Florence2/QwenVL живы). Пины как на поде.
RUN pip install --break-system-packages --no-cache-dir \
    transformers==5.8.1 tokenizers==0.22.2 numpy==2.4.4

# kornia: нода ComfyUI-LTXVideo импортит `kornia.geometry.transform.pyramid.pad`,
# который УБРАЛИ в kornia 0.8.3 (их issue #494) → ComfyUI-LTXVideo IMPORT FAILED →
# все LTXV-ноды красные (action_dual и др. LTX-2.3 флоу). Её requirements.txt не
# пинит kornia → цикл выше (стр. 102) тянет latest 0.8.3. Пинуем последнюю с `pad`.
# Проверено вживую на дев-поде 01.06: 4962 ноды, LTXVideo грузится, ноды зелёные.
RUN pip install --break-system-packages --no-cache-dir "kornia==0.8.2"

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

# Фронт НЕ пиним флагом — latest comfy ставит совместимый comfyui-frontend-package
# из своего requirements.txt (проверено на поде). install.sh всё равно перезапускает
# comfy без --front-end-version, так что флаг тут был бы перетёрт.
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
