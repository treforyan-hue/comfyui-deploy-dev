import torch

# ═══════════════════════════════════════════════════════
#  OFMTech Prompt Encoder  —  internal use only
#  Do NOT redistribute. Requires matching workflow.
# ═══════════════════════════════════════════════════════

_PROFILES = {
    "superior": (
        "You are an assistant designed to generate superior images "
        "with the superior degree of image-text alignment based on "
        "textual prompts or user prompts."
    ),
    "alignment": (
        "You are an assistant designed to generate high-quality images "
        "with the highest degree of image-text alignment based on "
        "textual prompts."
    ),
}

_PROFILE_KEYS = list(_PROFILES.keys())

_TIP = (
    "Profile controls the internal system instruction sent to the text encoder. "
    "'superior' biases toward visual fidelity; 'alignment' biases toward "
    "prompt adherence."
)


class OFMTechPromptEncode:
    """
    Encodes a user-facing prompt together with an internal system instruction
    through a CLIP text encoder, producing conditioning for diffusion sampling.
    """

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "clip": ("CLIP",),
                "profile": (_PROFILE_KEYS, {"tooltip": _TIP}),
                "prompt_text": ("STRING", {
                    "multiline": True,
                    "dynamicPrompts": True,
                    "tooltip": "Main generation prompt.",
                }),
            }
        }

    RETURN_TYPES = ("CONDITIONING",)
    RETURN_NAMES = ("conditioning",)
    FUNCTION = "process"
    CATEGORY = "OFMTech"
    DESCRIPTION = (
        "OFMTech internal prompt encoder. "
        "Combines system profile with user prompt for conditioned generation."
    )

    def process(self, clip, profile, prompt_text):
        if clip is None:
            raise RuntimeError(
                "[OFMTech] CLIP input is None — check that your model "
                "checkpoint contains a valid text encoder."
            )
        sys_instruction = _PROFILES[profile]
        combined = f"{sys_instruction} <Prompt Start> {prompt_text}"
        tok = clip.tokenize(combined)
        enc = clip.encode_from_tokens_scheduled(tok)
        return (enc,)


# ── mappings ──────────────────────────────────────────
NODE_CLASS_MAPPINGS = {
    "OFMTechPromptEncode": OFMTechPromptEncode,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "OFMTechPromptEncode": "OFMTech Prompt Encoder",
}
