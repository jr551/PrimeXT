#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

export CMAKE_BUILD_TYPE=Release
"${ROOT}/scripts/build-wasm.sh"
"${ROOT}/scripts/verify-optimization.sh"
"${ROOT}/scripts/stage-xash-engine.sh"

# PrimeXT mod assets (no proprietary Valve content)
rm -rf "${ROOT}/web/public/primext"
mkdir -p "${ROOT}/web/public/primext"
cp -a "${ROOT}/game_dir/." "${ROOT}/web/public/primext/"
"${ROOT}/scripts/generate-primext-manifest.sh"
"${ROOT}/scripts/fetch-demo-assets.sh"

cd "${ROOT}/web"
npm run build
echo "Web bundle: ${ROOT}/web/dist"
