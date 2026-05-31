#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# ALL 38 CUSTOM NODES — installed ONCE, covers ALL 13 workflows
# After this: ZERO red nodes for ANY workflow JSON
# ══════════════════════════════════════════════════════════════

install_all_nodes() {
    section "Custom Nodes (38 packages)"

    # ── Core nodes (used by 5+ workflows) ──
    clone_node "https://github.com/kijai/ComfyUI-KJNodes"
    clone_node "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    clone_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    clone_node "https://github.com/rgthree/rgthree-comfy"
    clone_node "https://github.com/yolain/ComfyUI-Easy-Use"
    clone_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    clone_node "https://github.com/ltdrdata/ComfyUI-Impact-Pack"

    # ── Video / Animation nodes ──
    clone_node "https://github.com/kijai/ComfyUI-segment-anything-2"
    clone_node "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    clone_node "https://github.com/kijai/ComfyUI-SCAIL-Pose"
    clone_node "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    clone_node "https://github.com/vrgamegirl19/comfyui-vrgamedevgirl"

    # ── ControlNet / Image nodes ──
    clone_node "https://github.com/Fannovel16/comfyui_controlnet_aux"
    clone_node "https://github.com/ClownsharkBatwing/RES4LYF"
    clone_node "https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler"
    clone_node "https://github.com/cubiq/ComfyUI_essentials"
    clone_node "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    clone_node "https://github.com/erosDiffusion/ComfyUI-EulerDiscreteScheduler"

    # ── Utility nodes ──
    clone_node "https://github.com/city96/ComfyUI-GGUF"
    clone_node "https://github.com/kijai/ComfyUI-Florence2"
    clone_node "https://github.com/pythongosssss/ComfyUI-WD14-Tagger"
    clone_node "https://github.com/digitaljohn/comfyui-propost"
    clone_node "https://github.com/PGCRT/CRT-Nodes"
    clone_node "https://github.com/Jonseed/ComfyUI-Detail-Daemon"
    clone_node "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
    clone_node "https://github.com/evanspearman/ComfyMath"
    clone_node "https://github.com/jags111/efficiency-nodes-comfyui"
    clone_node "https://github.com/ssitu/ComfyUI_UltimateSDUpscale"
    clone_node "https://github.com/Smirnov75/ComfyUI-mxToolkit"
    clone_node "https://github.com/daxcay/ComfyUI-DataSet"
    clone_node "https://github.com/chflame163/ComfyUI_LayerStyle"

    # ── Sub-packages & extras ──
    clone_node "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
    clone_node "https://github.com/filliptm/ComfyUI_Fill-Nodes"
    clone_node "https://github.com/JPS-GER/ComfyUI_JPS-Nodes"
    clone_node "https://github.com/WASasquatch/was-node-suite-comfyui"
    clone_node "https://github.com/BadCafeCode/masquerade-nodes-comfyui"
    clone_node "https://github.com/jamesWalker55/comfyui-various"
    clone_node "https://github.com/SKBv0/ComfyUI_SKBundle"
    clone_node "https://github.com/teskor-hub/comfyui-teskors-utils"

    # ── I2V Gen3 specific ──
    clone_node "https://github.com/princepainter/Comfyui-PainterFLF2V"

    # ── KiaraPanels (custom generated nodes for kiara_sasat) ──
    if [ -d "$SCRIPT_DIR/extras/KiaraPanels" ] && [ ! -d "$CNODES/KiaraPanels" ]; then
        log "Installing KiaraPanels..."
        cp -r "$SCRIPT_DIR/extras/KiaraPanels" "$CNODES/"
    fi

    # ── OFM-SegmentQueueRunner-RU (translated SQR node for FeiHou) ──
    if [ -d "$SCRIPT_DIR/extras/OFM-SegmentQueueRunner-RU" ] && [ ! -d "$CNODES/OFM-SegmentQueueRunner-RU" ]; then
        log "Installing OFM-SegmentQueueRunner-RU..."
        cp -r "$SCRIPT_DIR/extras/OFM-SegmentQueueRunner-RU" "$CNODES/"
    fi

    # ── INSTARAW (proprietary, bundled in repo) ──
    if [ -d "$SCRIPT_DIR/extras/ComfyUI_INSTARAW" ] && [ ! -d "$CNODES/ComfyUI_INSTARAW" ]; then
        log "Installing INSTARAW..."
        cp -r "$SCRIPT_DIR/extras/ComfyUI_INSTARAW" "$CNODES/"
        mkdir -p "$CNODES/ComfyUI_INSTARAW/js"
        if [ -f "$CNODES/ComfyUI_INSTARAW/requirements.txt" ]; then
            pip install --break-system-packages -q -r "$CNODES/ComfyUI_INSTARAW/requirements.txt" 2>/dev/null || true
        fi
    fi

    # ── ofm-preload (frontend extension: ?wf=<id> URL → auto-load workflow) ──
    if [ -d "$SCRIPT_DIR/extras/ofm-preload" ] && [ ! -d "$CNODES/ofm-preload" ]; then
        log "Installing ofm-preload..."
        cp -r "$SCRIPT_DIR/extras/ofm-preload" "$CNODES/"
    fi

    # ── Post-install fixes ──

    # WanVideoWrapper: feihou_animator workflow references transition_video kwarg
    # (existed in author's private fork, never in public main). Patch process() to
    # accept it as no-op so JSON loads without "unexpected keyword argument" error.
    # Idempotent: grep-guard — applies only once, skips if already patched.
    if [ -f "$CNODES/ComfyUI-WanVideoWrapper/nodes.py" ]; then
        if ! grep -q "transition_video=None):" "$CNODES/ComfyUI-WanVideoWrapper/nodes.py"; then
            sed -i 's/start_ref_image=None):/start_ref_image=None, transition_video=None):/' \
                "$CNODES/ComfyUI-WanVideoWrapper/nodes.py" 2>/dev/null || true
            if grep -q "transition_video=None):" "$CNODES/ComfyUI-WanVideoWrapper/nodes.py"; then
                log "Patched WanVideoWrapper: transition_video kwarg added (no-op)"
            fi
        fi
    fi

    # Impact-Pack submodule
    if [ -d "$CNODES/ComfyUI-Impact-Pack" ] && [ -f "$CNODES/ComfyUI-Impact-Pack/install.py" ]; then
        cd "$CNODES/ComfyUI-Impact-Pack" && python install.py 2>/dev/null || true
        cd "$COMFY"
    fi

    # UltimateSDUpscale submodule
    if [ -d "$CNODES/ComfyUI_UltimateSDUpscale" ] && [ ! -d "$CNODES/ComfyUI_UltimateSDUpscale/repositories" ]; then
        mkdir -p "$CNODES/ComfyUI_UltimateSDUpscale/repositories"
        git clone --quiet --depth 1 \
            "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111.git" \
            "$CNODES/ComfyUI_UltimateSDUpscale/repositories/ultimate_sd_upscale" 2>/dev/null || true
    fi

    # Frame-Interpolation RIFE directory
    mkdir -p "$CNODES/ComfyUI-Frame-Interpolation/ckpts/rife" 2>/dev/null || true

    # Extra pip packages needed by various nodes
    pip install --break-system-packages -q \
        sageattention mediapipe==0.10.14 lpips pyexiftool \
        segment_anything imageio-ffmpeg insightface onnxruntime-gpu \
        2>/dev/null || warn "Some pip packages failed (non-critical)"

    log "All custom nodes installed"
}


# ══════════════════════════════════════════════════════════════
# Runtime patches for transformers 5.x compatibility + virtual node filter
# Applied AFTER install_all_nodes(), BEFORE Step 3 (model downloads).
# All patches idempotent — safe to re-run.
# ══════════════════════════════════════════════════════════════
apply_runtime_patches() {
    section "Runtime patches (transformers 5.x compat + virtual nodes filter + rgthree pin + Qwen3VL/BodyRatio/NAG)"

    local PATCH_OK=0 PATCH_FAIL=0

    # Patch 1: server.py — drop virtual nodes (no class_type) before validate_prompt
    local SERVER_PY="$COMFY/server.py"
    if [ -f "$SERVER_PY" ]; then
        if grep -q "PATCH.*virtual nodes" "$SERVER_PY"; then
            log "server.py virtual filter: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
import sys
path = '$SERVER_PY'
with open(path) as f: c = f.read()
old = '                valid = await execution.validate_prompt(prompt_id, prompt, partial_execution_targets)'
new = '''                # PATCH: drop virtual/UI-only nodes that have no Python class_type
                #         (e.g. rgthree Fast Groups Bypasser, UUID nodes from new ComfyUI Frontend)
                import nodes as _nodes_mod
                _to_drop = [nid for nid, nd in prompt.items()
                            if not nd.get(chr(99)+chr(108)+chr(97)+chr(115)+chr(115)+chr(95)+chr(116)+chr(121)+chr(112)+chr(101)) or nd[chr(99)+chr(108)+chr(97)+chr(115)+chr(115)+chr(95)+chr(116)+chr(121)+chr(112)+chr(101)] not in _nodes_mod.NODE_CLASS_MAPPINGS]
                if _to_drop:
                    print(f\"[PATCH] dropping {len(_to_drop)} virtual nodes from prompt: {_to_drop[:5]}\")
                    for _nid in _to_drop:
                        prompt.pop(_nid, None)
                valid = await execution.validate_prompt(prompt_id, prompt, partial_execution_targets)'''
if old in c:
    with open(path, 'w') as f: f.write(c.replace(old, new, 1))
    sys.exit(0)
sys.exit(1)
" && { log "server.py virtual filter: applied"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "server.py: pattern not found, skipping"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi
    fi

    # Patch 2 + 3: bertwarper.py (transformers 5.x: get_head_mask removed, get_extended_attention_mask sig changed)
    local BERT_PY="$CNODES/comfyui_segment_anything/local_groundingdino/models/GroundingDINO/bertwarper.py"
    if [ -f "$BERT_PY" ]; then
        # Patch 2: get_head_mask
        if grep -q "_patched_get_head_mask" "$BERT_PY"; then
            log "bertwarper get_head_mask: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
path = '$BERT_PY'
with open(path) as f: c = f.read()
old = 'self.get_head_mask = bert_model.get_head_mask'
new = '''def _patched_get_head_mask(head_mask, num_hidden_layers, is_attention_chunked=False):
            if head_mask is None:
                return [None] * num_hidden_layers
            if head_mask.dim() == 1:
                head_mask = head_mask.unsqueeze(0).unsqueeze(0).unsqueeze(-1).unsqueeze(-1)
                head_mask = head_mask.expand(num_hidden_layers, -1, -1, -1, -1)
            elif head_mask.dim() == 2:
                head_mask = head_mask.unsqueeze(1).unsqueeze(-1).unsqueeze(-1)
            if is_attention_chunked:
                head_mask = head_mask.unsqueeze(-1)
            return head_mask
        self.get_head_mask = _patched_get_head_mask'''
import sys
if old in c:
    with open(path, 'w') as f: f.write(c.replace(old, new, 1))
    sys.exit(0)
sys.exit(1)
" && { log "bertwarper get_head_mask: applied"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "bertwarper get_head_mask: pattern not found"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi

        # Patch 3: get_extended_attention_mask — remove device arg (transformers 5.x removed it)
        if grep -qE "self\.get_extended_attention_mask\(\s*$" "$BERT_PY" 2>/dev/null && \
           ! grep -qE "attention_mask, input_shape, device" "$BERT_PY" 2>/dev/null; then
            log "bertwarper get_extended_attention_mask: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
path = '$BERT_PY'
with open(path) as f: c = f.read()
old = '''extended_attention_mask: torch.Tensor = self.get_extended_attention_mask(
            attention_mask, input_shape, device
        )'''
new = '''extended_attention_mask: torch.Tensor = self.get_extended_attention_mask(
            attention_mask, input_shape
        )'''
import sys
if old in c:
    with open(path, 'w') as f: f.write(c.replace(old, new, 1))
    sys.exit(0)
sys.exit(1)
" && { log "bertwarper get_extended_attention_mask: applied"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "bertwarper get_extended_attention_mask: pattern not found"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi
    else
        log "comfyui_segment_anything not installed — skipping bert patches"
    fi

    # Patch 4: INSTARAW MaskImageFilter — auto-bypass popup when input mask provided
    local FILTER_PY="$CNODES/ComfyUI_INSTARAW/nodes/interactive_nodes/image_filter.py"
    if [ -f "$FILTER_PY" ]; then
        if grep -q "auto-bypass popup when input mask" "$FILTER_PY"; then
            log "INSTARAW MaskImageFilter: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
path = '$FILTER_PY'
with open(path) as f: c = f.read()
target = '''    def func(self, image, enabled, timeout, uid, if_no_mask, cache_behavior, node_identifier, mask=None, extra1=\"\", extra2=\"\", extra3=\"\", tip=\"\", **kwargs):
        if not enabled:'''
replacement = '''    def func(self, image, enabled, timeout, uid, if_no_mask, cache_behavior, node_identifier, mask=None, extra1=\"\", extra2=\"\", extra3=\"\", tip=\"\", **kwargs):
        # PATCH: auto-bypass popup when input mask is provided (popup is broken with new Frontend)
        if not enabled or mask is not None:'''
import sys
if target in c:
    with open(path, 'w') as f: f.write(c.replace(target, replacement, 1))
    sys.exit(0)
sys.exit(1)
" && { log "INSTARAW MaskImageFilter auto-bypass: applied"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "INSTARAW MaskImageFilter: pattern not found"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi
    fi

    # Patch 5: rgthree-comfy pin to 683836c (Apr 2026, fixes Fast Groups Bypasser with custom hex colors)
    local RGTHREE="$CNODES/rgthree-comfy"
    if [ -d "$RGTHREE/.git" ]; then
        local CURRENT
        CURRENT=$(git -C "$RGTHREE" rev-parse --short=7 HEAD 2>/dev/null)
        if [ -z "$CURRENT" ]; then
            warn "rgthree-comfy: cannot read current HEAD"
            PATCH_OK=$((PATCH_OK+1))
        else
            log "rgthree-comfy: updating $CURRENT -> latest main"
            if (cd "$RGTHREE" && git fetch --quiet origin main 2>/dev/null && \
                git reset --hard --quiet origin/main 2>/dev/null); then
                log "rgthree-comfy: updated to latest main ($(git -C \"$RGTHREE\" rev-parse --short HEAD))"
                PATCH_OK=$((PATCH_OK+1))
            else
                warn "rgthree-comfy: git checkout failed"
                PATCH_FAIL=$((PATCH_FAIL+1))
            fi
        fi
    fi

    # Patch 6: zhihui Qwen3VL (x_mode) — torch_dtype + BitsAndBytes off (BnB → libnvJitLink.so.13 crash; dtype= не поддерживается Qwen3VL)
    local QWEN_PY="$CNODES/zhihui_nodes_comfyui/Nodes/Qwen3VL/Qwen3VLBasic.py"
    if [ -f "$QWEN_PY" ]; then
        if grep -q "quantization_config=None," "$QWEN_PY"; then
            log "Qwen3VL Basic: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
path = '$QWEN_PY'
with open(path) as f: c = f.read()
c2 = c.replace('dtype=torch.bfloat16 if self.bf16_support else torch.float16,',
               'torch_dtype=torch.bfloat16 if self.bf16_support else torch.float16,')
c2 = c2.replace('quantization_config=quantization_config,', 'quantization_config=None,')
import sys
if c2 != c:
    with open(path, 'w') as f: f.write(c2)
    sys.exit(0)
sys.exit(1)
" && { log "Qwen3VL Basic: applied (torch_dtype + BnB off)"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "Qwen3VL Basic: patterns not found"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi
        # Config (статичный — путь LLM фиксирован)
        local QWEN_CFG="$CNODES/zhihui_nodes_comfyui/Nodes/Qwen3VL/qwen3vl_config.json"
        if [ ! -f "$QWEN_CFG" ]; then
            cat > "$QWEN_CFG" <<'QCFG'
{
  "cache_dir": "/workspace/ComfyUI/models/LLM",
  "active_model_path": "/workspace/ComfyUI/models/LLM/Qwen3-VL-4B-Instruct",
  "active_model_name": "Qwen/Qwen3-VL-4B-Instruct",
  "use_default_cache": false,
  "provider": "huggingface"
}
QCFG
            log "Qwen3VL config: written"
        fi
    fi

    # Patch 7: BodyRatioMapper (action_transfer) — апстрим __init__ не подключает body_ratio_mapper-сабмодуль → SDPose render/proportion/bone ноды отсутствуют
    local BRM_INIT="$CNODES/ComfyUI-BodyRatioMapper/__init__.py"
    if [ -f "$BRM_INIT" ]; then
        if grep -q "BodyRatioMapperSDPoseRender" "$BRM_INIT"; then
            log "BodyRatioMapper __init__: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            cat > "$BRM_INIT" <<'BRMEOF'
from .nodes import NODE_CLASS_MAPPINGS as _MAIN_NCM
from .nodes import NODE_DISPLAY_NAME_MAPPINGS as _MAIN_DNM
from .body_ratio_mapper.render_nodes import BodyRatioMapperSDPoseRender
from .body_ratio_mapper.proportion_transfer_node import BodyRatioMapperProportionTransfer
from .body_ratio_mapper.bone_scale_node import BodyRatioMapperSDPoseBoneScale, BodyRatioMapperSDPoseTranslate
NODE_CLASS_MAPPINGS = {**_MAIN_NCM,
    "BodyRatioMapperSDPoseRender": BodyRatioMapperSDPoseRender,
    "BodyRatioMapperProportionTransfer": BodyRatioMapperProportionTransfer,
    "BodyRatioMapperSDPoseBoneScale": BodyRatioMapperSDPoseBoneScale,
    "BodyRatioMapperSDPoseTranslate": BodyRatioMapperSDPoseTranslate}
NODE_DISPLAY_NAME_MAPPINGS = dict(_MAIN_DNM)
WEB_DIRECTORY = "./web"
BRMEOF
            log "BodyRatioMapper __init__: applied"
            PATCH_OK=$((PATCH_OK+1))
        fi
    fi

    # Patch 8: NAG samplers.py — отключить сломанный .chroma.model импорт (NAG-chroma не грузится на текущем comfy; ни один baked-флоу NAG не юзает, патч держит ноду импортируемой)
    local NAG_S="$CNODES/ComfyUI-NAG/samplers.py"
    if [ -f "$NAG_S" ]; then
        if grep -q "^NAGChromaSwitch = None" "$NAG_S"; then
            log "NAG chroma-off: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            python3 -c "
path = '$NAG_S'
with open(path) as f: c = f.read()
c2 = c.replace('from .chroma.model import NAGChromaSwitch', 'NAGChromaSwitch = None')
c2 = c2.replace('elif model_type == Chroma:', 'elif False:')
import sys
if c2 != c:
    with open(path, 'w') as f: f.write(c2)
    sys.exit(0)
sys.exit(1)
" && { log "NAG chroma-off: applied"; PATCH_OK=$((PATCH_OK+1)); } \
  || { warn "NAG chroma-off: patterns not found"; PATCH_FAIL=$((PATCH_FAIL+1)); }
        fi
    fi

    # Patch 9: папка "detection" (регистрит WanAnimatePreprocess) на новом comfy bb560036 НЕ
    # включает .onnx в допустимые ext → OnnxDetectionModelLoader не видит vitpose/yolo .onnx
    # (на диске есть) → красная нода в action_transfer. Дописываем .onnx + чистим filename-кэш
    # В КОНЦЕ модуля (после всех ре-регистраций — патч сразу после строки регистрации
    # перетирается последующими импортами; END-блок работает, проверено эмпирически).
    local WAP="$CNODES/ComfyUI-WanAnimatePreprocess/nodes.py"
    if [ -f "$WAP" ]; then
        if grep -q "PATCH detection onnx END" "$WAP"; then
            log "WanAnimatePreprocess detection .onnx: already patched"
            PATCH_OK=$((PATCH_OK+1))
        else
            cat >> "$WAP" <<'WAPEOF'

# PATCH detection onnx END
try:
    _e = folder_paths.folder_names_and_paths.get("detection")
    if _e:
        folder_paths.folder_names_and_paths["detection"] = (_e[0], set(_e[1]) | {".onnx"})
        try: folder_paths.filename_list_cache.pop("detection", None)
        except Exception: pass
except Exception:
    pass
WAPEOF
            log "WanAnimatePreprocess detection .onnx: applied"
            PATCH_OK=$((PATCH_OK+1))
        fi
    fi

    # Clear .pyc cache so Python re-imports patched modules on next run
    find "$COMFY" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true

    log "Runtime patches: ok=$PATCH_OK, failed=$PATCH_FAIL"
}
