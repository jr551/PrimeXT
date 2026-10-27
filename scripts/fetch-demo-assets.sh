#!/usr/bin/env bash
# Fetch free demo zips for browser testing (not redistributed in git).
# Uplink: https://www.moddb.com/downloads/half-life-uplink — packaged like webXash's uplink.zip.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/web/public/test"
mkdir -p "${DEST}"

UPLINK_URL="${UPLINK_URL:-https://raw.githubusercontent.com/x8BitRain/webXash/main/public/hl/uplink.zip}"

echo "Fetching Uplink demo zip..."
curl -fsSL -o "${DEST}/uplink.zip" "${UPLINK_URL}"
ls -la "${DEST}/uplink.zip"
