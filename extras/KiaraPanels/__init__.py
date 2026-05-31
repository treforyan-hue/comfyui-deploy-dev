\
"""
KiaraPanels - Control Panel nodes for Stage I (SD) and Stage II (Flux) workflows.
Drop this folder into ComfyUI/custom_nodes/ to use.
"""

# ============================================================
# Stage I - SD Control Panel
# ============================================================
class ControlPanelSD:
    CATEGORY = "KiaraPanels"
    FUNCTION = "execute"
    RETURN_TYPES = ("INT", "INT", "INT", "FLOAT")
    RETURN_NAMES = ("width", "height", "steps", "cfg")

    SD_PRESETS = {
        "1:1 Square 512x512": (512, 512),
        "1:1 Square 768x768": (768, 768),
        "1:1 Square 1024x1024": (1024, 1024),
        "2:3 Portrait 512x768": (512, 768),
        "2:3 Portrait 768x1152": (768, 1152),
        "3:2 Landscape 768x512": (768, 512),
        "3:2 Landscape 1152x768": (1152, 768),
        "9:16 Tall 576x1024": (576, 1024),
        "16:9 Wide 1024x576": (1024, 576),
        "9:16 Tall 720x1280": (720, 1280),
        "16:9 Wide 1280x720": (1280, 720),
        "4:7 Tall 576x1008": (576, 1008),
        "9:16 Tall 896x1536": (896, 1536),
    }

    QUALITY_PRESETS = {
        "Draft 4 steps": 4,
        "Fast 8 steps": 8,
        "Normal 12 steps": 12,
        "High Quality 20 steps": 20,
        "Ultra 30 steps": 30,
        "Maximum 50 steps": 50,
    }

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "resolution": (list(cls.SD_PRESETS.keys()), {"default": "9:16 Tall 896x1536"}),
                "quality": (list(cls.QUALITY_PRESETS.keys()), {"default": "Fast 8 steps"}),
                "cfg": ("FLOAT", {"default": 1.0, "min": 1.0, "max": 30.0, "step": 0.5}),
            }
        }

    def execute(self, resolution, quality, cfg):
        w, h = self.SD_PRESETS[resolution]
        steps = self.QUALITY_PRESETS[quality]
        return (w, h, steps, cfg)


# ============================================================
# Stage II - Flux Control Panel
# ============================================================
class ControlPanelFlux:
    CATEGORY = "KiaraPanels"
    FUNCTION = "execute"
    RETURN_TYPES = ("INT", "INT", "INT")
    RETURN_NAMES = ("width", "height", "steps")

    FLUX_PRESETS = {
        "1:1 Square 1024x1024": (1024, 1024),
        "3:4 Portrait 896x1152": (896, 1152),
        "4:3 Landscape 1152x896": (1152, 896),
        "9:16 Tall 768x1344": (768, 1344),
        "9:16 Tall 896x1536": (896, 1536),
        "16:9 Wide 1344x768": (1344, 768),
        "2:3 Portrait 832x1216": (832, 1216),
        "3:2 Landscape 1216x832": (1216, 832),
    }

    QUALITY_PRESETS = {
        "Fast 4 steps": 4,
        "Normal 8 steps": 8,
        "High Quality 16 steps": 16,
        "Ultra 28 steps": 28,
    }

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "resolution": (list(cls.FLUX_PRESETS.keys()), {"default": "9:16 Tall 896x1536"}),
                "quality": (list(cls.QUALITY_PRESETS.keys()), {"default": "Fast 4 steps"}),
            }
        }

    def execute(self, resolution, quality):
        w, h = self.FLUX_PRESETS[resolution]
        steps = self.QUALITY_PRESETS[quality]
        return (w, h, steps)


# ============================================================
# Stage II - Reference Latent for FLUX Klein
# ============================================================
class KiaraReferenceLatent:
    """
    Injects VAE-encoded reference latent into conditioning for FLUX Klein.
    Replicates kx7_cb243e9c ("Reference Latent").
    Uses the native FLUX reference_latents mechanism.
    """
    CATEGORY = "KiaraPanels"
    FUNCTION = "execute"
    RETURN_TYPES = ("CONDITIONING",)

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "conditioning": ("CONDITIONING",),
            },
            "optional": {
                "latent": ("LATENT",),
            }
        }

    def execute(self, conditioning, latent=None):
        if latent is None:
            return (conditioning,)
        import copy
        c = []
        for t in conditioning:
            d = copy.deepcopy(t[1])
            ref = latent["samples"]
            if "reference_latents" in d:
                d["reference_latents"] = d["reference_latents"] + [ref]
            else:
                d["reference_latents"] = [ref]
            c.append([t[0], d])
        return (c,)


# ============================================================
# Registration
# ============================================================
NODE_CLASS_MAPPINGS = {
    "ControlPanelSD": ControlPanelSD,
    "ControlPanelFlux": ControlPanelFlux,
    "KiaraReferenceLatent": KiaraReferenceLatent,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "ControlPanelSD": "Control Panel - SD",
    "ControlPanelFlux": "Control Panel - Flux",
    "KiaraReferenceLatent": "Reference Latent (FLUX)",
}
