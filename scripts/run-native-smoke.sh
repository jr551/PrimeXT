#!/usr/bin/env bash
# PrimeXT ships no C++ unit test suite; this smoke check validates the wasm link step output.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT="${ROOT}/web/public/wasm/cl_dlls/client_emscripten_wasm32.wasm"
SERVER="${ROOT}/web/public/wasm/dlls/server_emscripten_wasm32.wasm"

for f in "${CLIENT}" "${SERVER}"; do
  if [[ ! -f "${f}" ]]; then
    echo "Missing ${f} — run scripts/build-wasm.sh first" >&2
    exit 1
  fi
  size="$(wc -c < "${f}")"
  if [[ "${size}" -lt 1000000 ]]; then
    echo "Suspiciously small wasm module: ${f} (${size} bytes)" >&2
    exit 1
  fi
done

echo "Native smoke: wasm artifacts OK (${CLIENT}, ${SERVER})"
