#!/usr/bin/env bash
# Optional Emscripten build. Generated with AI (Cursor).
# Build PrimeXT client/server as Xash3D-compatible side modules.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${ROOT}/build-wasm"
OUT_DIR="${ROOT}/web/public/wasm"
VCPKG_TRIPLET="wasm32-emscripten"

if [[ -f "${ROOT}/emsdk/emsdk_env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${ROOT}/emsdk/emsdk_env.sh"
elif [[ -f "${EMSDK}/emsdk_env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${EMSDK}/emsdk_env.sh"
else
  echo "Emscripten SDK not found. Clone emsdk into ${ROOT}/emsdk or set EMSDK." >&2
  exit 1
fi

if [[ ! -x "${ROOT}/external/vcpkg/vcpkg" ]]; then
  "${ROOT}/external/vcpkg/bootstrap-vcpkg.sh" -disableMetrics
fi

cmake -E make_directory "${BUILD_DIR}"
# -fPIC is required so side modules can export game DLL entry points when using EXPORTED_FUNCTIONS.
emcmake cmake -G Ninja -S "${ROOT}" -B "${BUILD_DIR}" \
  -DCMAKE_MAKE_PROGRAM="$(command -v ninja)" \
  -DCMAKE_TOOLCHAIN_FILE="${ROOT}/external/vcpkg/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_TARGET_TRIPLET="${VCPKG_TRIPLET}" \
  -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="${ROOT}/external/vcpkg/scripts/toolchains/emscripten.cmake" \
  -DVCPKG_C_FLAGS=-fPIC \
  -DVCPKG_CXX_FLAGS=-fPIC \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_GAME_LAUNCHER=OFF \
  -DBUILD_UTILS=OFF \
  -DENABLE_PHYSX=OFF \
  -DENABLE_STATIC_CRT_LINKING=OFF

cmake --build "${BUILD_DIR}" -j"$(nproc)"

BIN="${BUILD_DIR}/Release/primext/bin"
VCPKG_LIB="${BUILD_DIR}/vcpkg_installed/${VCPKG_TRIPLET}/lib"
# vcpkg builds MODULE targets as static archives (often named *.wasm by our CMake output rules).
if [[ -f "${BIN}/libclient_emscripten_javascript.a" ]]; then
  CLIENT_A="${BIN}/libclient_emscripten_javascript.a"
elif [[ -f "${BIN}/client_emscripten_wasm32_emscripten_javascript.wasm" ]]; then
  CLIENT_A="${BIN}/client_emscripten_wasm32_emscripten_javascript.wasm"
else
  echo "Client static archive not found under ${BIN}" >&2
  exit 1
fi
if [[ -f "${BIN}/libserver_emscripten_javascript.a" ]]; then
  SERVER_A="${BIN}/libserver_emscripten_javascript.a"
elif [[ -f "${BIN}/server_emscripten_wasm32_emscripten_javascript.wasm" ]]; then
  SERVER_A="${BIN}/server_emscripten_wasm32_emscripten_javascript.wasm"
else
  echo "Server static archive not found under ${BIN}" >&2
  exit 1
fi

EXPORT_DIR="${BUILD_DIR}/wasm-exports"
mkdir -p "${EXPORT_DIR}"

link_side_module() {
  local archive="$1"
  local out="$2"
  shift 2
  local -a libs=()
  local -a export_flags=()
  for arg in "$@"; do
    if [[ "${arg}" == *.a ]]; then
      libs+=("${arg}")
    else
      export_flags+=("-Wl,--export=${arg}")
    fi
  done
  em++ -O3 -g0 -Wl,--whole-archive "${archive}" -Wl,--no-whole-archive \
    "${libs[@]}" \
    "${export_flags[@]}" \
    -o "${out}" \
    -s SIDE_MODULE=2 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s IMPORTED_MEMORY=1 \
    -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
    -s ASSERTIONS=0
}

mkdir -p "${OUT_DIR}/cl_dlls" "${OUT_DIR}/dlls"

# imgui is not linked into the side module (vcpkg static lib is not PIC-safe for EXPORTED_FUNCTIONS).
# PrimeXT ImGui editor UI is disabled in the browser build; core client + fmt only.
link_side_module "${CLIENT_A}" \
  "${OUT_DIR}/cl_dlls/client_emscripten_wasm32.wasm" \
  "${VCPKG_LIB}/libfmt.a" \
  GetClientAPI

# Server_GetPhysicsInterface fills g_physfuncs (file search, traces, entity spawn).
# Without it, GameDLLInit calls a null pfnGetFilesList and the main loop aborts.
link_side_module "${SERVER_A}" \
  "${OUT_DIR}/dlls/server_emscripten_wasm32.wasm" \
  "${VCPKG_LIB}/libfmt.a" \
  GetEntityAPI GetEntityAPI2 GiveFnptrsToDll \
  Server_GetPhysicsInterface Server_GetBlendingInterface

for wasm in "${OUT_DIR}/cl_dlls/client_emscripten_wasm32.wasm" "${OUT_DIR}/dlls/server_emscripten_wasm32.wasm"; do
  size="$(wc -c < "${wasm}")"
  echo "Size $(basename "${wasm}"): ${size} bytes"
done

echo "WASM modules written to ${OUT_DIR}"
