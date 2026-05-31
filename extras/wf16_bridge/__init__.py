# wf16_bridge — локальные замены проприетарных нод RunningHub.ai (флоу Action_Transfer и др.)
# Слоты точно повторяют оригинал (имена/порядок), чтобы связи и виджеты воркфлоу совпали.
import os


class _Any(str):
    def __ne__(self, o):
        return False


ANY = _Any("*")


# RHHiddenNodes — password-gated passthrough: a_1..a_N -> p0..p(N-1)
class RHHiddenNodes:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {}, "optional": {
            "pwd": ("STRING", {"default": ""}),
            "a_1": (ANY,), "a_2": (ANY,), "a_3": (ANY,), "a_4": (ANY,),
        }}
    RETURN_TYPES = (ANY, ANY, ANY, ANY)
    RETURN_NAMES = ("p0", "p1", "p2", "p3")
    FUNCTION = "f"
    CATEGORY = "wf16_bridge"

    def f(self, pwd="", a_1=None, a_2=None, a_3=None, a_4=None):
        return (a_1, a_2, a_3, a_4)


# Bool — простой проброс булева
class RHBool:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {"value": ("BOOLEAN", {"default": True})}}
    RETURN_TYPES = ("BOOLEAN",)
    RETURN_NAMES = ("BOOLEAN",)
    FUNCTION = "f"
    CATEGORY = "wf16_bridge"

    def f(self, value=True):
        return (value,)


# VideoCombineNode — реальный вывод видео (images -> mp4), плюс last_frames для длинного видео
class VideoCombineNode:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {"images": ("IMAGE",)}, "optional": {
            "audio": ("AUDIO",),
            "frame_rate": ("FLOAT", {"default": 16.0, "min": 1.0, "max": 120.0}),
            "filename": ("STRING", {"default": "wf16_video"}),
            "pix_fmt": ("STRING", {"default": "yuv420p"}),
            "crf": ("INT", {"default": 19, "min": 0, "max": 51}),
            "save_metadata": ("BOOLEAN", {"default": False}),
            "trim_to_audio": ("BOOLEAN", {"default": False}),
            "last_frames_count": ("INT", {"default": 0, "min": 0, "max": 1000}),
            "pingpong": ("BOOLEAN", {"default": False}),
        }}
    RETURN_TYPES = ("STRING", "STRING", "IMAGE")
    RETURN_NAMES = ("video_path", "filename", "last_frames_images")
    FUNCTION = "f"
    CATEGORY = "wf16_bridge"
    OUTPUT_NODE = True

    def f(self, images, audio=None, frame_rate=16.0, filename="wf16_video",
          pix_fmt="yuv420p", crf=19, last_frames_count=0, pingpong=False, **kw):
        import folder_paths
        out_dir = folder_paths.get_output_directory()
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "%s.mp4" % filename)
        try:
            import numpy as np
            import imageio
            arr = (images.cpu().numpy() * 255.0).clip(0, 255).astype("uint8")  # [N,H,W,C]
            if pingpong and len(arr) > 1:
                arr = np.concatenate([arr, arr[-2:0:-1]], axis=0)
            w = imageio.get_writer(path, fps=float(frame_rate), codec="libx264",
                                   quality=8, macro_block_size=1,
                                   ffmpeg_params=["-pix_fmt", str(pix_fmt), "-crf", str(crf)])
            for fr in arr:
                w.append_data(fr)
            w.close()
            print("[wf16] VideoCombineNode saved:", path)
        except Exception as e:
            print("[wf16] VideoCombineNode save failed:", e)
        n = last_frames_count if last_frames_count and last_frames_count > 0 else 1
        last = images[-n:]
        return (path, os.path.basename(path), last)


# CompressImages — упаковка в zip; для прогона достаточно вернуть путь-строку
class CompressImages:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {}, "optional": {
            "images or video_path": (ANY,),
            "filename_prefix": ("STRING", {"default": "wf16"}),
            "image_format": ("STRING", {"default": "PNG"}),
            "password": ("STRING", {"default": ""}),
        }}
    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("zip_filename",)
    FUNCTION = "f"
    CATEGORY = "wf16_bridge"
    OUTPUT_NODE = True

    def f(self, **kw):
        v = kw.get("images or video_path")
        return (v if isinstance(v, str) else "",)


NODE_CLASS_MAPPINGS = {
    "RHHiddenNodes": RHHiddenNodes,
    "Bool": RHBool,
    "VideoCombineNode": VideoCombineNode,
    "CompressImages": CompressImages,
}
NODE_DISPLAY_NAME_MAPPINGS = {k: k for k in NODE_CLASS_MAPPINGS}
