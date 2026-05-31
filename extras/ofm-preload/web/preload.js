/*
 * OFM Workflow Preload (frontend extension)
 *
 * Авто-загрузка workflow в ComfyUI при открытии URL вида:
 *   https://<pod>:<port>/?wf=<workflow_id>            (один WF)
 *   https://<pod>:<port>/?wfs=<id1,id2,id3>&active=N  (bundle, активная вкладка N)
 *
 * Принцип:
 *   ComfyUI frontend (v1.42+) при boot читает sessionStorage:
 *     `Comfy.Workflow.ActivePath:<clientId>`  → активный workflow
 *     `Comfy.Workflow.OpenPaths:<clientId>`   → массив открытых вкладок
 *   Затем persistence composable вызывает workflowService.openWorkflow().
 *   Мы pre-seed-им эти ключи ДО того как persistence их прочитает.
 *
 * Условие для работы:
 *   - Файлы <id>.json должны лежать в /workspace/ComfyUI/user/default/workflows/
 *     (бот SSH-аплоадит после ready и после add_wf).
 *   - Setting "Comfy.Workflow.Persist" должен быть включён (default true).
 *   - Frontend version: pinned 1.42.6 (см. comfyui-deploy/Dockerfile).
 *
 * Graceful degradation:
 *   - Нет query params → ничего не делаем (текущее поведение, пустой canvas).
 *   - Файла нет на диске → frontend isValidPath отфильтрует, fallback на пустой.
 *   - Persist отключён → seed игнорируется, workflows доступны в сайдбаре (1 клик).
 */
(function () {
    "use strict";
    try {
        const params = new URLSearchParams(window.location.search);
        const single = params.get("wf");
        const bundle = params.get("wfs");
        if (!single && !bundle) return;  // обычное поведение

        const ids = (bundle || single).split(",")
            .map(function (s) { return s.trim(); })
            .filter(function (s) { return s.length > 0; });
        if (ids.length === 0) return;

        // Активная вкладка из ?active=<idx>, default 0 (первая в bundle).
        let active = parseInt(params.get("active") || "0", 10);
        if (isNaN(active) || active < 0 || active >= ids.length) active = 0;

        const paths = ids.map(function (id) { return "workflows/" + id + ".json"; });
        const workspaceId = "personal";

        // КРИТИЧНО: ComfyUI frontend кеширует current workflow state в
        // localStorage (ключи Comfy.Workflow.Draft.*, Comfy.Workflow.Open*,
        // и т.д.). При F5/повторном открытии эти кеши имеют приоритет над
        // нашим sessionStorage seed → юзер видит СТАРЫЙ workflow вместо
        // выбранного в URL. Очищаем всё workflow-related ДО seed, чтобы
        // каждое открытие URL с ?wf=/?wfs= давало чистый старт.
        // ClientId сохраняем (нужен для persistence ключей).
        var _preserve = { "Comfy.ClientId": true };
        var _toRemove = [];
        for (var i = 0; i < localStorage.length; i++) {
            var k = localStorage.key(i);
            if (!k || _preserve[k]) continue;
            var lk = k.toLowerCase();
            if (lk.indexOf("workflow") >= 0 || lk.indexOf("graph") >= 0
                || lk.indexOf("canvas") >= 0) {
                _toRemove.push(k);
            }
        }
        for (var j = 0; j < _toRemove.length; j++) {
            try { localStorage.removeItem(_toRemove[j]); } catch (_) {}
        }
        // Также чистим sessionStorage полностью — sessionStorage per-tab,
        // но в браузере с keep-alive вкладок старые ключи с прошлого деплоя
        // могут висеть и конфликтовать с новым clientId.
        try {
            var _sRemove = [];
            for (var i2 = 0; i2 < sessionStorage.length; i2++) {
                var sk = sessionStorage.key(i2);
                if (sk && sk.indexOf("Comfy.Workflow.") === 0) _sRemove.push(sk);
            }
            for (var j2 = 0; j2 < _sRemove.length; j2++) {
                sessionStorage.removeItem(_sRemove[j2]);
            }
        } catch (_) {}

        // ClientId: должен совпадать с тем что api.ts использует.
        var CID_KEY = "Comfy.ClientId";
        var clientId = localStorage.getItem(CID_KEY);
        if (!clientId) {
            clientId = (window.crypto && window.crypto.randomUUID)
                ? window.crypto.randomUUID()
                : "ofm-" + Date.now() + "-" + Math.random().toString(36).slice(2);
            localStorage.setItem(CID_KEY, clientId);
        }

        sessionStorage.setItem(
            "Comfy.Workflow.ActivePath:" + clientId,
            JSON.stringify({ workspaceId: workspaceId, path: paths[active] })
        );
        sessionStorage.setItem(
            "Comfy.Workflow.OpenPaths:" + clientId,
            JSON.stringify({ workspaceId: workspaceId, paths: paths, activeIndex: active })
        );

        // Чистим query params чтобы reload не переигрывал то же самое
        // (ComfyUI template-loader так же делает после загрузки темплейта).
        if (window.history && window.history.replaceState) {
            try {
                window.history.replaceState(null, "", window.location.pathname);
            } catch (_) { /* ignore */ }
        }

        console.log(
            "[ofm-preload] seeded:", paths, "active:", active,
            "(cleared", _toRemove.length, "localStorage keys)"
        );
    } catch (e) {
        console.warn("[ofm-preload] failed (graceful, falls back to empty canvas):", e);
    }
})();
