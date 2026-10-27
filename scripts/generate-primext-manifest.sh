#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${ROOT}/web/public/primext"
cd "${TARGET}"
python3 - <<'PY'
import json
import os
files = []
for dirpath, _, names in os.walk('.'):
    for name in names:
        if name == 'manifest.json':
            continue
        rel = os.path.join(dirpath, name).replace('./', '').replace('\\', '/')
        files.append(rel)
files.sort()
with open('manifest.json', 'w', encoding='utf-8') as f:
    json.dump({'files': files}, f)
print(f'Wrote manifest with {len(files)} files')
PY
