#!/usr/bin/env bash
# INSTARAW Teleport — character background swap via SAM HQ + GroundingDino
# GPU: 12GB+ | Models: ~4GB | Time: ~3 min
# Uses INSTARAW API nodes (Gemini/Ideogram/Grok) — user provides their own API keys

models_instaraw_teleport() {
    section "Models: INSTARAW Teleport (segmentation-based)"

    mkdir -p "$MODELS/sams" "$MODELS/grounding-dino"

    dl_pub "https://huggingface.co/lkeab/hq-sam/resolve/main/sam_hq_vit_h.pth" \
        "$MODELS/sams/sam_hq_vit_h.pth"
    dl_pub "https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swinb_cogcoor.pth" \
        "$MODELS/grounding-dino/groundingdino_swinb_cogcoor.pth"
    dl_pub "https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinB.cfg.py" \
        "$MODELS/grounding-dino/GroundingDINO_SwinB.cfg.py"
}
