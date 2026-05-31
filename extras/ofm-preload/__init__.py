"""OFM workflow preload — ComfyUI custom_node-расширение.

Смысл: фронтенд ComfyUI (1.42.x) при старте читает sessionStorage ключи
`Comfy.Workflow.ActivePath:<clientId>` / `Comfy.Workflow.OpenPaths:<clientId>`
и вызывает workflowService.openWorkflow() — авто-загрузка graph'а на canvas.

Это extension просто инжектит preload.js в фронтенд (ComfyUI автоматом
подхватывает любой JS из custom_nodes/*/web/ через /extensions endpoint).
preload.js читает ?wf=<id> или ?wfs=<id1,id2> из URL и seed-ит sessionStorage
ДО того как persistence-логика её прочитает → юзер открыл URL → workflow
уже загружен на canvas, без drag-n-drop.

Ноды в Python не объявляем — это pure-frontend extension.
"""
WEB_DIRECTORY = "./web"
NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}
__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS", "WEB_DIRECTORY"]
