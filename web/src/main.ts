/**
 * Browser loader for PrimeXT + Xash3D FWGS (WASM).
 * Engine integration patterns adapted from webXash (MIT) — https://github.com/x8BitRain/webXash
 */
import { Xash3D } from 'xash3d-fwgs';
import { unzipSync } from 'fflate';

const RO_DIR = '/rodir/';
const statusEl = document.getElementById('status')!;
const logEl = document.getElementById('log')!;
const canvas = document.getElementById('canvas') as HTMLCanvasElement;

/** Emscripten/SDL listens on #canvas and the window. Keep focus there so keys and pointer lock reach the engine. */
function bindGameInput(): void {
  canvas.addEventListener('contextmenu', (event) => event.preventDefault());
  const focusGame = () => {
    canvas.focus();
  };
  canvas.addEventListener('pointerdown', focusGame);
  window.addEventListener(
    'keydown',
    (event) => {
      if (document.activeElement !== canvas) return;
      const block = [' ', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
      if (block.includes(event.key) || event.key.length === 1) {
        event.preventDefault();
      }
    },
    { capture: true },
  );
}
bindGameInput();

const ENGINE = '/xash';
const PRIMEXT_WASM = '/wasm';
const UPLINK_ZIP = '/test/uplink.zip';

const URLS = {
  xash: `${ENGINE}/xash.wasm`,
  filesystem: `${ENGINE}/filesystem_stdio.wasm`,
  menu: `${ENGINE}/libmenu.wasm`,
  webgl2: `${ENGINE}/libref_webgl2.wasm`,
  extras: `${ENGINE}/valve/extras.pk3`,
  client: `${PRIMEXT_WASM}/cl_dlls/client_emscripten_wasm32.wasm`,
  server: `${PRIMEXT_WASM}/dlls/server_emscripten_wasm32.wasm`,
};

const DYNAMIC_LIBRARIES = [
  'filesystem_stdio.wasm',
  'libref_webgl2.wasm',
  'cl_dlls/client_emscripten_wasm32.wasm',
  'cl_dlls/menu_emscripten_wasm32.wasm',
  'dlls/server_emscripten_wasm32.wasm',
  'dlls/hl_emscripten_wasm32.wasm',
  'bin/client_emscripten_wasm32.wasm',
  'bin/server_emscripten_wasm32.wasm',
];

type LaunchProfile = {
  gameDir: string;
  mountPrimext: boolean;
};

const PROFILE_PRIMEXT: LaunchProfile = { gameDir: 'primext', mountPrimext: true };
/** Half-Life: Uplink demo. The zip is a valve/ tree (same layout as webXash). */
const PROFILE_UPLINK: LaunchProfile = { gameDir: 'valve', mountPrimext: false };

function log(line: string) {
  logEl.textContent += `${line}\n`;
  console.log(line);
}

function setStatus(text: string) {
  statusEl.textContent = text;
}

function locateFile(path: string): string {
  switch (path) {
    case 'xash.wasm':
      return URLS.xash;
    case 'filesystem_stdio.wasm':
      return URLS.filesystem;
    case 'cl_dlls/menu_emscripten_wasm32.wasm':
      return URLS.menu;
    case 'cl_dlls/client_emscripten_wasm32.wasm':
    case 'bin/client_emscripten_wasm32.wasm':
      return URLS.client;
    case 'dlls/server_emscripten_wasm32.wasm':
    case 'dlls/hl_emscripten_wasm32.wasm':
    case 'bin/server_emscripten_wasm32.wasm':
      return URLS.server;
    case 'libref_webgl2.wasm':
      return URLS.webgl2;
    case 'libvgui_support.wasm':
      return URLS.menu;
    default:
      return path.startsWith('/') ? path : `${ENGINE}/${path}`;
  }
}

async function mountFiles(
  xash: Xash3D,
  files: Map<string, Uint8Array>,
): Promise<void> {
  xash.em!.FS.mkdirTree(RO_DIR);
  for (const [relative, data] of files) {
    const full = RO_DIR + relative.replace(/^\/+/, '');
    const dir = full.substring(0, full.lastIndexOf('/'));
    if (dir) xash.em!.FS.mkdirTree(dir);
    if (!full.endsWith('/')) {
      xash.em!.FS.writeFile(full, data);
    }
  }
  xash.em!.FS.chdir(RO_DIR);
}

async function mountZip(xash: Xash3D, buffer: ArrayBuffer): Promise<void> {
  const entries = unzipSync(new Uint8Array(buffer));
  const map = new Map<string, Uint8Array>();
  for (const [name, content] of Object.entries(entries)) {
    map.set(name, content);
  }
  await mountFiles(xash, map);
}

async function mountPrimextAssets(xash: Xash3D): Promise<void> {
  const res = await fetch('/primext/manifest.json');
  if (!res.ok) {
    log('No primext manifest — skipping mod file staging');
    return;
  }
  const manifest = (await res.json()) as { files: string[] };
  const map = new Map<string, Uint8Array>();
  for (const rel of manifest.files) {
    const fileRes = await fetch(`/primext/${rel}`);
    if (!fileRes.ok) continue;
    map.set(`primext/${rel}`, new Uint8Array(await fileRes.arrayBuffer()));
  }
  await mountFiles(xash, map);
}

async function writeExtras(xash: Xash3D): Promise<void> {
  const res = await fetch(URLS.extras);
  const buf = await res.arrayBuffer();
  xash.em!.FS.writeFile(RO_DIR + 'extras.pk3', new Uint8Array(buf));
}

async function startXash(profile: LaunchProfile): Promise<Xash3D> {
  const launchArgs = [
    '-game',
    profile.gameDir,
    '-windowed',
    '-ref',
    'webgl2',
    '+hud_scale',
    '2.5',
    '+volume',
    '0.05',
  ];

  const xash = new Xash3D({
    canvas,
    module: {
      arguments: launchArgs,
      locateFile,
      print: (text: string) => log(text),
      printErr: (text: string) => log(`[err] ${text}`),
    },
    libraries: {
      filesystem: URLS.filesystem,
      xash: URLS.xash,
      menu: URLS.menu,
      client: URLS.client,
      server: URLS.server,
      render: { gles3compat: URLS.webgl2 },
    },
    dynamicLibraries: DYNAMIC_LIBRARIES,
  });

  await xash.init();
  return xash;
}

async function runWithZip(
  zipBuffer: ArrayBuffer,
  profile: LaunchProfile,
): Promise<void> {
  setStatus('Starting engine…');
  const xash = await startXash(profile);
  setStatus('Mounting game data…');
  await mountZip(xash, zipBuffer);
  if (profile.mountPrimext) {
    await mountPrimextAssets(xash);
  }
  await writeExtras(xash);
  setStatus('Running');
  (window as unknown as { __primextXash?: Xash3D }).__primextXash = xash;
  beginPlay(xash, profile.gameDir);
}

function beginPlay(xash: Xash3D, gameDir: string): void {
  log(`Starting Xash main loop (-game ${gameDir})…`);
  xash.main();
  canvas.focus();
  log('Click the view to capture the mouse. WASD moves, mouse looks, Esc opens the menu.');
}

async function runWithFolder(fileList: FileList): Promise<void> {
  const map = new Map<string, Uint8Array>();
  const paths: string[] = [];
  for (const file of fileList) {
    const rel = (file as File & { webkitRelativePath?: string })
      .webkitRelativePath;
    if (!rel) continue;
    paths.push(rel);
  }
  const prefix = paths[0]?.includes('/')
    ? paths[0].slice(0, paths[0].indexOf('/') + 1)
    : '';
  for (const file of fileList) {
    const rel = (file as File & { webkitRelativePath?: string })
      .webkitRelativePath;
    if (!rel) continue;
    const stripped = rel.startsWith(prefix) ? rel.slice(prefix.length) : rel;
    map.set(stripped, new Uint8Array(await file.arrayBuffer()));
  }
  setStatus('Starting engine…');
  const xash = await startXash(PROFILE_PRIMEXT);
  setStatus('Mounting game data…');
  await mountFiles(xash, map);
  await mountPrimextAssets(xash);
  await writeExtras(xash);
  setStatus('Running');
  (window as unknown as { __primextXash?: Xash3D }).__primextXash = xash;
  beginPlay(xash, PROFILE_PRIMEXT.gameDir);
}

async function loadDemoZip(): Promise<ArrayBuffer> {
  const res = await fetch(UPLINK_ZIP);
  if (!res.ok) {
    throw new Error('Uplink demo zip missing (run scripts/fetch-demo-assets.sh)');
  }
  return await res.arrayBuffer();
}

document.getElementById('launch-demo')?.addEventListener('click', async () => {
  try {
    setStatus('Downloading Half-Life: Uplink demo…');
    await runWithZip(await loadDemoZip(), PROFILE_UPLINK);
  } catch (e) {
    setStatus(e instanceof Error ? e.message : 'Demo failed');
  }
});

document.getElementById('folder')?.addEventListener('change', async (ev) => {
  const input = ev.target as HTMLInputElement;
  if (!input.files?.length) return;
  await runWithFolder(input.files);
});

const params = new URLSearchParams(location.search);
if (params.get('autotest') === '1' || params.get('demo') === 'uplink') {
  void (async () => {
    try {
      setStatus('Loading Uplink demo (autotest)…');
      await runWithZip(await loadDemoZip(), PROFILE_UPLINK);
    } catch (e) {
      setStatus(e instanceof Error ? e.message : 'autotest failed');
    }
  })();
}

setStatus('Ready — try the Uplink demo or load your own Half-Life folder');
