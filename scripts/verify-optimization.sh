#!/usr/bin/env bash
# Release-build and WASM size/export smoke checks (run after build-wasm.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT="${ROOT}/web/public/wasm/cl_dlls/client_emscripten_wasm32.wasm"
SERVER="${ROOT}/web/public/wasm/dlls/server_emscripten_wasm32.wasm"

for f in "${CLIENT}" "${SERVER}"; do
  [[ -f "${f}" ]] || { echo "Missing ${f}; run scripts/build-wasm.sh" >&2; exit 1; }
done

if [[ "${CMAKE_BUILD_TYPE:-Release}" != "Release" ]]; then
  echo "WARN: CMAKE_BUILD_TYPE is not Release (${CMAKE_BUILD_TYPE:-unset})" >&2
fi

client_size="$(wc -c < "${CLIENT}")"
server_size="$(wc -c < "${SERVER}")"
echo "client wasm: ${client_size} bytes"
echo "server wasm: ${server_size} bytes"

# PrimeXT client renderer is large; catch accidental debug/unstripped blowups.
max_client=$((95 * 1024 * 1024))
max_server=$((12 * 1024 * 1024))
if (( client_size > max_client )); then
  echo "Client WASM larger than ${max_client} bytes — check -O3/-g0 link flags" >&2
  exit 1
fi
if (( server_size > max_server )); then
  echo "Server WASM larger than ${max_server} bytes" >&2
  exit 1
fi

node --input-type=module -e "
import fs from 'fs';
const client = new WebAssembly.Module(fs.readFileSync('${CLIENT}'));
const server = new WebAssembly.Module(fs.readFileSync('${SERVER}'));
const ce = WebAssembly.Module.exports(client).map((e) => e.name);
const se = WebAssembly.Module.exports(server).map((e) => e.name);
if (!ce.includes('GetClientAPI')) {
  console.error('client missing GetClientAPI export');
  process.exit(1);
}
if (!se.includes('GetEntityAPI')) {
  console.error('server missing GetEntityAPI export');
  process.exit(1);
}
if (ce.length > 64) {
  console.error('client export table too large:', ce.length, '(trim EXPORTED_FUNCTIONS)');
  process.exit(1);
}
if (se.length > 32) {
  console.error('server export table too large:', se.length);
  process.exit(1);
}
console.log('exports ok — client', ce.length, 'server', se.length);
"

"${ROOT}/scripts/run-native-smoke.sh"
echo "Optimization checks passed."
