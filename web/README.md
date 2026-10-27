# PrimeXT in the browser

This directory was generated with AI (Cursor). It is an optional experiment on top of PrimeXT, not a supported platform. The Windows, Linux, and Android builds do not use it.

PrimeXT stays the game libraries. The browser page loads them as WebAssembly side modules inside the prebuilt engine package `xash3d-fwgs@1.2.2` (MIT). The page itself follows the loader shape of [webXash](https://github.com/x8BitRain/webXash) (MIT): MEMFS at `/rodir/`, zip or folder mount, and `-ref webgl2`. See [THIRD_PARTY.md](../THIRD_PARTY.md). No webXash source is copied into this tree.

Retail Half-Life assets are not included. Bring your own legal `valve` folder, or use the free Uplink demo, which the build downloads and does not commit.

## Build

Emscripten 3.1.74, CMake, Ninja, and Node are required. PhysX is off for this target.

```bash
git clone --depth 1 https://github.com/emscripten-core/emsdk.git emsdk
./emsdk/emsdk install 3.1.74 && ./emsdk/emsdk activate 3.1.74
./scripts/build-web.sh
cd web && npm run preview
```

Open http://127.0.0.1:43123

```bash
cd web && npm run test:e2e:install && npm run test:e2e
```

The Playwright test checks that the menu stays up and that Escape is received. Screenshot: `web/test-results/primext-engine.png`.

## What works

| Area | Status |
| --- | --- |
| Client and server modules | Release `-O3`. Client is about 78 MB, server about 2.7 MB |
| Menu | Draws with the Uplink demo, launched as `-game valve` (that zip is a `valve/` tree) |
| Menu input | Click the canvas. New Game opens the difficulty list. Escape opens the quit confirm |
| Filesystem | MEMFS, same idea as webXash |
| Audio | The engine's SDL Emscripten driver starts. It is not tuned separately |
| In-game editor | Stubbed. Dear ImGui is not linked |
| PhysX, multiplayer, compilers | Not in this build |

## What still fails

Loading a map reaches the loading plaque and then the engine aborts with `Aborted(OOM)`. `xash3d-fwgs@1.2.2` does not grow its wasm heap past 256 MB, and the PrimeXT client already occupies most of that. In-game movement was not tested because the map never finishes loading. PrimeXT's own OpenGL post-processing is skipped on this target; the engine's WebGL2 renderer draws the menu.

`scripts/build-wasm.sh` has to name the side-module exports explicitly (`GetClientAPI`, `GetEntityAPI`, `GetEntityAPI2`, `GiveFnptrsToDll`, `Server_GetPhysicsInterface`, `Server_GetBlendingInterface`). vcpkg turns the CMake `MODULE` targets into static archives, so a new engine entry point has to be added to that script or `dlsym` returns null.
