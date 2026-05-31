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

# ── ВСЕ ноды дев-пода (auto-snapshot 31.05.2026, пинованы на коммиты) ──
# Решение юзера: печём ВЕСЬ набор пода, не дельту. nodes.sh install_all_nodes —
# рантайм-fallback (latest); ЭТОТ список = baked primary (пинованный, воспроизводимый).
RUN git clone https://github.com/mercu-lore/-Multiple-Angle-Camera-Control $CNODES/-Multiple-Angle-Camera-Control && cd $CNODES/-Multiple-Angle-Camera-Control && git checkout f10579b4846ff3ff9701d88b37ea0a838ba30025
RUN git clone https://github.com/PGCRT/CRT-Nodes $CNODES/CRT-Nodes && cd $CNODES/CRT-Nodes && git checkout 7abbf87b25e50186cc4927e9f54aad62f18932ea
RUN git clone https://github.com/evanspearman/ComfyMath $CNODES/ComfyMath && cd $CNODES/ComfyMath && git checkout c01177221c31b8e5fbc062778fc8254aeb541638
RUN git clone https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait $CNODES/ComfyUI-AdvancedLivePortrait && cd $CNODES/ComfyUI-AdvancedLivePortrait && git checkout 3bba732915e22f18af0d221b9c5c282990181f1b
RUN git clone https://github.com/wuwukaka/ComfyUI-BodyRatioMapper $CNODES/ComfyUI-BodyRatioMapper && cd $CNODES/ComfyUI-BodyRatioMapper && git checkout 6b3b54c4b9da8408ed44f4d21a57677eafaeb3ad
RUN git clone https://github.com/crystian/ComfyUI-Crystools $CNODES/ComfyUI-Crystools && cd $CNODES/ComfyUI-Crystools && git checkout 2f18256c5b5063937106f29a8e0a7db3ae3869b7
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts $CNODES/ComfyUI-Custom-Scripts && cd $CNODES/ComfyUI-Custom-Scripts && git checkout 609f3afaa74b2f88ef9ce8d939626065e3247469
RUN git clone https://github.com/daxcay/ComfyUI-DataSet $CNODES/ComfyUI-DataSet && cd $CNODES/ComfyUI-DataSet && git checkout 83a3c7254c33effd06482651ea39a141024df5dc
RUN git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon $CNODES/ComfyUI-Detail-Daemon && cd $CNODES/ComfyUI-Detail-Daemon && git checkout 39206d10849584e0b6ded943faca4dcd8747beb7
RUN git clone https://github.com/yolain/ComfyUI-Easy-Sam3 $CNODES/ComfyUI-Easy-Sam3 && cd $CNODES/ComfyUI-Easy-Sam3 && git checkout 88fe578a1a5e03d95281197303d5d3a73fd5a089
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use $CNODES/ComfyUI-Easy-Use && cd $CNODES/ComfyUI-Easy-Use && git checkout 8ba21d0b442002e66389d6e87faf828bfe05b2ad
RUN git clone https://github.com/erosDiffusion/ComfyUI-EulerDiscreteScheduler $CNODES/ComfyUI-EulerDiscreteScheduler && cd $CNODES/ComfyUI-EulerDiscreteScheduler && git checkout eb5bd4dc43ad15becb62e387fa4d07503a4a3737
RUN git clone https://github.com/Saganaki22/ComfyUI-FishAudioS2 $CNODES/ComfyUI-FishAudioS2 && cd $CNODES/ComfyUI-FishAudioS2 && git checkout 521f33fe79c081da314dc905ce399c62edb24749
RUN git clone https://github.com/kijai/ComfyUI-Florence2 $CNODES/ComfyUI-Florence2 && cd $CNODES/ComfyUI-Florence2 && git checkout 40516621740e93df002c68ae78c12025106799fa
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation $CNODES/ComfyUI-Frame-Interpolation && cd $CNODES/ComfyUI-Frame-Interpolation && git checkout 26545cc2dd95bc3d27f056016300673bdeee78f5
RUN git clone https://github.com/city96/ComfyUI-GGUF $CNODES/ComfyUI-GGUF && cd $CNODES/ComfyUI-GGUF && git checkout 6ea2651e7df66d7585f6ffee804b20e92fb38b8a
RUN git clone https://github.com/glifxyz/ComfyUI-GlifNodes $CNODES/ComfyUI-GlifNodes && cd $CNODES/ComfyUI-GlifNodes && git checkout 503d6d55a2d8d49fc976eccb4a9af7238569a7ce
RUN git clone https://github.com/if-ai/ComfyUI-IF_AI_tools $CNODES/ComfyUI-IF_AI_tools && cd $CNODES/ComfyUI-IF_AI_tools && git checkout 93130d80ad90230bccc5c29f63f10a1c95d0eff9 && rm -f requirements.txt
RUN git clone https://github.com/alexopus/ComfyUI-Image-Saver $CNODES/ComfyUI-Image-Saver && cd $CNODES/ComfyUI-Image-Saver && git checkout 3f32da23068ee539840b489d8efa923387c11670
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack $CNODES/ComfyUI-Impact-Pack && cd $CNODES/ComfyUI-Impact-Pack && git checkout 6a517ebe06fea2b74fc41b3bd089c0d7173eeced
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack $CNODES/ComfyUI-Impact-Subpack && cd $CNODES/ComfyUI-Impact-Subpack && git checkout 50c7b71a6a224734cc9b21963c6d1926816a97f1
RUN git clone https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch $CNODES/ComfyUI-Inpaint-CropAndStitch && cd $CNODES/ComfyUI-Inpaint-CropAndStitch && git checkout 3617559bcb9d15ff60b24c6800701402eb2cd478
RUN git clone https://github.com/kijai/ComfyUI-KJNodes $CNODES/ComfyUI-KJNodes && cd $CNODES/ComfyUI-KJNodes && git checkout f0ac4537c0541e034dcd77b5f26d6f0cebfa02c2
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo $CNODES/ComfyUI-LTXVideo && cd $CNODES/ComfyUI-LTXVideo && git checkout 229437c6b65796d6a7a63ae34be2bd5ba31fa543
RUN git clone https://github.com/LevelPixel/ComfyUI-LevelPixel $CNODES/ComfyUI-LevelPixel && cd $CNODES/ComfyUI-LevelPixel && git checkout cea37a918882cd4ca5d22807eaa125a93a76ac7a
RUN git clone https://github.com/aria1th/ComfyUI-LogicUtils $CNODES/ComfyUI-LogicUtils && cd $CNODES/ComfyUI-LogicUtils && git checkout f77c699543b8f9977b24581af66ad026d340b663
RUN git clone https://github.com/kijai/ComfyUI-MelBandRoFormer $CNODES/ComfyUI-MelBandRoFormer && cd $CNODES/ComfyUI-MelBandRoFormer && git checkout 92c86854e6654f4aacc97484471af95c98ea16d4
RUN git clone https://github.com/ChenDarYen/ComfyUI-NAG $CNODES/ComfyUI-NAG && cd $CNODES/ComfyUI-NAG && git checkout ef8a641be08983cf5f06669f70719b6eecce3c7f
RUN git clone https://github.com/skatardude10/ComfyUI-Optical-Realism $CNODES/ComfyUI-Optical-Realism && cd $CNODES/ComfyUI-Optical-Realism && git checkout 8d6c1e0ab1f45851c9d7bd850f7c9023238e338d
RUN git clone https://github.com/kijai/ComfyUI-PromptRelay $CNODES/ComfyUI-PromptRelay && cd $CNODES/ComfyUI-PromptRelay && git checkout ca5d4e3edb6abd9c2a4c68a3a6798eec1980f450
RUN git clone https://github.com/1038lab/ComfyUI-QwenVL $CNODES/ComfyUI-QwenVL && cd $CNODES/ComfyUI-QwenVL && git checkout fcd1ada87a28f922cb887f779db32429f78a022c
RUN git clone https://github.com/kijai/ComfyUI-SCAIL-Pose $CNODES/ComfyUI-SCAIL-Pose && cd $CNODES/ComfyUI-SCAIL-Pose && git checkout 11402b150d728440a4a89964faa58907f84c35e6
RUN git clone https://github.com/judian17/ComfyUI-SDPose-OOD $CNODES/ComfyUI-SDPose-OOD && cd $CNODES/ComfyUI-SDPose-OOD && git checkout 123653f565ca93bcda223ca8c3b03dc4930427fe
RUN git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler $CNODES/ComfyUI-SeedVR2_VideoUpscaler && cd $CNODES/ComfyUI-SeedVR2_VideoUpscaler && git checkout 4490bd1f482e026674543386bb2a4d176da245b9
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite $CNODES/ComfyUI-VideoHelperSuite && cd $CNODES/ComfyUI-VideoHelperSuite && git checkout 449839959f0153fb8a57211a9364c55163935ca9
RUN git clone https://github.com/pythongosssss/ComfyUI-WD14-Tagger $CNODES/ComfyUI-WD14-Tagger && cd $CNODES/ComfyUI-WD14-Tagger && git checkout 9e0a6e700299182fc05c58b62e7ad9f72182a78b
RUN git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess $CNODES/ComfyUI-WanAnimatePreprocess && cd $CNODES/ComfyUI-WanAnimatePreprocess && git checkout 1a35b81a418bbba093356ad19b19bf2a76a24f4e
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper $CNODES/ComfyUI-WanVideoWrapper && cd $CNODES/ComfyUI-WanVideoWrapper && git checkout df8f3e49daaad117cf3090cc916c83f3d001494c
RUN git clone https://github.com/zml-w/ComfyUI-ZML-Image $CNODES/ComfyUI-ZML-Image && cd $CNODES/ComfyUI-ZML-Image && git checkout 97866e26958b130bb82fc8a2c687a27b3486cb86
RUN git clone https://github.com/StableLlama/ComfyUI-basic_data_handling $CNODES/ComfyUI-basic_data_handling && cd $CNODES/ComfyUI-basic_data_handling && git checkout fd37841b70ba0e5cc68eb38b558225b8ad2352c9
RUN git clone https://github.com/Smirnov75/ComfyUI-mxToolkit $CNODES/ComfyUI-mxToolkit && cd $CNODES/ComfyUI-mxToolkit && git checkout 7f7a0e584f12078a1c589645d866ae96bad0cc35
RUN git clone https://github.com/EllangoK/ComfyUI-post-processing-nodes $CNODES/ComfyUI-post-processing-nodes && cd $CNODES/ComfyUI-post-processing-nodes && git checkout c49a05254795403648f2c1774b6f5ea39f96e7d5
RUN git clone https://github.com/jtydhr88/ComfyUI-qwenmultiangle $CNODES/ComfyUI-qwenmultiangle && cd $CNODES/ComfyUI-qwenmultiangle && git checkout 6f93d9b15a50c07c13411734723fe5cae287e7aa
RUN git clone https://github.com/kijai/ComfyUI-segment-anything-2 $CNODES/ComfyUI-segment-anything-2 && cd $CNODES/ComfyUI-segment-anything-2 && git checkout 0c35fff5f382803e2310103357b5e985f5437f32
RUN git clone https://github.com/vslinx/ComfyUI-vslinx-nodes $CNODES/ComfyUI-vslinx-nodes && cd $CNODES/ComfyUI-vslinx-nodes && git checkout 2a6b98a51b2c594a07de3438e6b0cdb157092ab4
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes $CNODES/ComfyUI_Comfyroll_CustomNodes && cd $CNODES/ComfyUI_Comfyroll_CustomNodes && git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca
RUN git clone https://github.com/filliptm/ComfyUI_Fill-Nodes $CNODES/ComfyUI_Fill-Nodes && cd $CNODES/ComfyUI_Fill-Nodes && git checkout 3d71d2cfc197bac4a5f9fa17668c84744b37e945
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus $CNODES/ComfyUI_IPAdapter_plus && cd $CNODES/ComfyUI_IPAdapter_plus && git checkout a0f451a5113cf9becb0847b92884cb10cbdec0ef
RUN git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes $CNODES/ComfyUI_JPS-Nodes && cd $CNODES/ComfyUI_JPS-Nodes && git checkout 0e2a9aca02b17dde91577bfe4b65861df622dcaf
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle $CNODES/ComfyUI_LayerStyle && cd $CNODES/ComfyUI_LayerStyle && git checkout d94bef1ee5ed3656f5ff1bb2830a4ffd94f40935
RUN git clone https://github.com/jeankassio/ComfyUI_MusicTools $CNODES/ComfyUI_MusicTools && cd $CNODES/ComfyUI_MusicTools && git checkout f3d86efce3f6a1b12de2c30605b03d86a12ac76c
RUN git clone https://github.com/SKBv0/ComfyUI_SKBundle $CNODES/ComfyUI_SKBundle && cd $CNODES/ComfyUI_SKBundle && git checkout 1e13687c2c0f63d3842d536814f15ab8db25ca49
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale $CNODES/ComfyUI_UltimateSDUpscale && cd $CNODES/ComfyUI_UltimateSDUpscale && git checkout c164c303c099b9b5d117d15f438604377432e8d2
RUN git clone https://github.com/AHEKOT/ComfyUI_VNCCS_Utils $CNODES/ComfyUI_VNCCS_Utils && cd $CNODES/ComfyUI_VNCCS_Utils && git checkout eed41c48f36b9bc95236caf715cfef7ad3738983
RUN git clone https://github.com/judian17/ComfyUI_YOLO_For_Multi_SDPose_Detection $CNODES/ComfyUI_YOLO_For_Multi_SDPose_Detection && cd $CNODES/ComfyUI_YOLO_For_Multi_SDPose_Detection && git checkout 7f8c09ccec140daaa15feeb6f4d80e379f801021
RUN git clone https://github.com/cubiq/ComfyUI_essentials $CNODES/ComfyUI_essentials && cd $CNODES/ComfyUI_essentials && git checkout 9d9f4bedfc9f0321c19faf71855e228c93bd0dc9
RUN git clone https://github.com/LAOGOU-666/Comfyui-Memory_Cleanup $CNODES/Comfyui-Memory_Cleanup && cd $CNODES/Comfyui-Memory_Cleanup && git checkout 58de13a6090e04408e343501ff8902c034d9f518
RUN git clone https://github.com/princepainter/Comfyui-PainterFLF2V $CNODES/Comfyui-PainterFLF2V && cd $CNODES/Comfyui-PainterFLF2V && git checkout c81a68feceb90b28557a979d6de44eac59c89123
RUN git clone https://github.com/princepainter/Comfyui-PainterVRAM $CNODES/Comfyui-PainterVRAM && cd $CNODES/Comfyui-PainterVRAM && git checkout 64f4d69c097a7946193f8f0773f4373217ed63a8
RUN git clone https://github.com/lrzjason/Comfyui-QwenEditUtils $CNODES/Comfyui-QwenEditUtils && cd $CNODES/Comfyui-QwenEditUtils && git checkout cdd4d028c6491d27a40092d7795158668cec9189
RUN git clone https://github.com/Azornes/Comfyui-Resolution-Master $CNODES/Comfyui-Resolution-Master && cd $CNODES/Comfyui-Resolution-Master && git checkout b47aaf485aff6e3ef0242153212d66af489d763b
RUN git clone https://github.com/FX-FeiHou/Comfyui-Segment-Queue-Runner $CNODES/Comfyui-Segment-Queue-Runner && cd $CNODES/Comfyui-Segment-Queue-Runner && git checkout 49f85c1f534abd86be5c0f897a52b29632200733
RUN git clone https://github.com/LAOGOU-666/Comfyui_LG_Tools $CNODES/Comfyui_LG_Tools && cd $CNODES/Comfyui_LG_Tools && git checkout 8606cd06eae3c407a8fb74f70772602f3aab9ee9
RUN git clone https://github.com/gseth/ControlAltAI-Nodes $CNODES/ControlAltAI-Nodes && cd $CNODES/ControlAltAI-Nodes && git checkout 721492b66c9cede8ae23ae10615462ad80cfd061
RUN git clone https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes $CNODES/Derfuu_ComfyUI_ModdedNodes && cd $CNODES/Derfuu_ComfyUI_ModdedNodes && git checkout d0905bed31249f2bd0814c67585cf4fe3c77c015
RUN git clone https://github.com/ClownsharkBatwing/RES4LYF $CNODES/RES4LYF && cd $CNODES/RES4LYF && git checkout 0dc91c00c4c3fb38e7874fcd7a2a327765e8882c
RUN git clone https://github.com/ChangeTheConstants/SeedVarianceEnhancer $CNODES/SeedVarianceEnhancer && cd $CNODES/SeedVarianceEnhancer && git checkout aa97baee8bacbe0dd702e419eb6c39505b631cc3
RUN git clone https://github.com/giriss/comfy-image-saver $CNODES/comfy-image-saver && cd $CNODES/comfy-image-saver && git checkout 65e6903eff274a50f8b5cd768f0f96baf37baea1
RUN git clone https://github.com/melMass/comfy_mtb $CNODES/comfy_mtb && cd $CNODES/comfy_mtb && git checkout b705a177d3ae93a969068f3ba156f3bc6fbc8a1d
RUN git clone https://github.com/Artificial-Sweetener/comfyui-WhiteRabbit $CNODES/comfyui-WhiteRabbit && cd $CNODES/comfyui-WhiteRabbit && git checkout 607de1b4679b88a09932c1768db633450ace56b9
RUN git clone https://github.com/theUpsider/ComfyUI-Logic $CNODES/comfyui-logic && cd $CNODES/comfyui-logic && git checkout 214cfba933291be224156d37bc30c25742076b44
RUN git clone https://github.com/digitaljohn/comfyui-propost $CNODES/comfyui-propost && cd $CNODES/comfyui-propost && git checkout df6a6d122498f57ad7195d58e07701a501c9dcb6
RUN git clone https://github.com/teskor-hub/comfyui-teskors-utils $CNODES/comfyui-teskors-utils && cd $CNODES/comfyui-teskors-utils && git checkout c4a8cd1b6f8b724b055cbe371d6192e42babe103
RUN git clone https://github.com/jamesWalker55/comfyui-various $CNODES/comfyui-various && cd $CNODES/comfyui-various && git checkout 5bd85aaf7616878471469c4ec7e11bbd0cef3bf2
RUN git clone https://github.com/vrgamegirl19/comfyui-vrgamedevgirl $CNODES/comfyui-vrgamedevgirl && cd $CNODES/comfyui-vrgamedevgirl && git checkout 233bca84a0b819e91909c08143f831821952a548
RUN git clone https://github.com/YaserJaradeh/comfyui-yaser-nodes $CNODES/comfyui-yaser-nodes && cd $CNODES/comfyui-yaser-nodes && git checkout 68225852a11e22e735631aa11ea065e82ea191d4
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux $CNODES/comfyui_controlnet_aux && cd $CNODES/comfyui_controlnet_aux && git checkout 95a13e2e5d8f8ae57583fbebb0be1f670889858b
RUN git clone https://github.com/lenML/comfyui_qwen_image_edit_adv $CNODES/comfyui_qwen_image_edit_adv && cd $CNODES/comfyui_qwen_image_edit_adv && git checkout 6202738e3ab1718acf3e98d20e8c2502ce4cd0ee
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui $CNODES/efficiency-nodes-comfyui && cd $CNODES/efficiency-nodes-comfyui && git checkout 4579b7d6076b2870998a08f5d37883fbc8261ff2
RUN git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui $CNODES/masquerade-nodes-comfyui && cd $CNODES/masquerade-nodes-comfyui && git checkout 432cb4d146a391b387a0cd25ace824328b5b61cf
RUN git clone https://github.com/rgthree/rgthree-comfy $CNODES/rgthree-comfy && cd $CNODES/rgthree-comfy && git checkout 738105af5fb14e96fbecaf406dc356e284797e8c
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui $CNODES/was-node-suite-comfyui && cd $CNODES/was-node-suite-comfyui && git checkout ea935d1044ae5a26efa54ebeb18fe9020af49a45
RUN git clone https://github.com/zhihui6/zhihui_nodes_comfyui $CNODES/zhihui_nodes_comfyui && cd $CNODES/zhihui_nodes_comfyui && git checkout 67f170c3d0e86abad9c7dbdffc96ff0db2ee7e8f

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
