#!/usr/bin/env bash
# ── ORT-GPU invariant (2026-07-19, выровнено с сайтовой доктриной A4) ──
# Проблема — ДВЕ половины, обе доказаны вживую (сайт: session 43, бот: под
# 6z4votatyu5nvy 19.07; см. ofmflow-api app/animator_engine/runpod.py и
# app/services/flow_automation.py "A4"):
#   (1) ноды тянут CPU-пакет `onnxruntime`, он затирает файлы onnxruntime-gpu
#       (одна import-папка, побеждает поставленный последним);
#   (2) даже чистый cu13-билд 1.27 НЕ создаёт CUDA-сессию на этом образе:
#       dlopen провайдера не находит libnvrtc.so.13 — системный toolkit
#       образа только CUDA 12.8, а pip-либы cu13 вне путей загрузчика.
# Итог: ViTPose/yolo/insightface/nudenet молча считают на CPU пода
# (vitpose 967мс/кадр CPU vs 7мс GPU — x138, живой замер 19.07).
# Доказанный фикс = ПИН cu12-билда onnxruntime-gpu==1.22.0: он линкуется
# на системный toolkit 12.8 + cudnn9 образа, никакого ldconfig не нужно.
# Скрипт: (а) сносит ОБА пакета и ставит пиннутый gpu-билд ПЛОСКИМ
# install'ом — уже стоящие numpy/protobuf/flatbuffers удовлетворяют deps и
# НЕ трогаются (--force-reinstall тащил protobuf 7.x и ломал ноды —
# проверено); (б) пишет фейковую dist-info `onnxruntime`, чтобы БУДУЩИЕ
# `pip install -r requirements.txt` нод никогда снова не притащили
# CPU-колесо; (в) проверяет providers. Идемпотентен; exit 1 = провал.
set -uo pipefail
ORT_PIN="${ORT_PIN:-1.22.0}"
SP="$(python3 -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])')"

pip uninstall -y --break-system-packages onnxruntime onnxruntime-gpu >/dev/null 2>&1 \
    || pip uninstall -y onnxruntime onnxruntime-gpu >/dev/null 2>&1 || true

pip install --break-system-packages --no-cache-dir -q "onnxruntime-gpu==${ORT_PIN}" \
    || pip install --break-system-packages --no-cache-dir -q "onnxruntime-gpu<1.23" \
    || pip install --no-cache-dir -q "onnxruntime-gpu==${ORT_PIN}" \
    || exit 1

# (б) шим: pip навсегда считает дистрибутив `onnxruntime` установленным
# (версия = реально стоящий gpu-билд, чтобы `>=`-проверки нод были честными;
# имя не конфликтует с onnxruntime_gpu-*.dist-info самого gpu-пакета).
ORT_VER="$(python3 -c 'import onnxruntime as o;print(o.__version__)' 2>/dev/null)"
[ -z "$ORT_VER" ] && exit 1
SHIM="$SP/onnxruntime-${ORT_VER}.dist-info"
mkdir -p "$SHIM"
printf 'Metadata-Version: 2.1\nName: onnxruntime\nVersion: %s\n' "$ORT_VER" > "$SHIM/METADATA"
printf 'pip\n' > "$SHIM/INSTALLER"
: > "$SHIM/RECORD"

# (в) verify: работает и в GPU-less билд-контейнере CI (список провайдеров,
# не сессия; реальный session-смоук делает страж в install.sh на живом поде)
python3 -c "import onnxruntime as o,sys;sys.exit(0 if 'CUDAExecutionProvider' in o.get_available_providers() else 1)" || exit 1
echo "[ort_gpu_fix] OK: onnxruntime-gpu ${ORT_VER}, CUDA EP available"
