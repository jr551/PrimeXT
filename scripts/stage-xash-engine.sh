#!/usr/bin/env bash
# Copy prebuilt Xash3D FWGS web engine assets from npm (same approach as webXash).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="${ROOT}/web"
DEST="${WEB}/public/xash"

cd "${WEB}"
npm install --no-fund --no-audit
rm -rf "${DEST}"
mkdir -p "${DEST}"
cp -r node_modules/xash3d-fwgs/dist/* "${DEST}/"

echo "Xash engine staged at ${DEST}"
