#!/usr/bin/env python3
"""Generate Emscripten EXPORTED_FUNCTIONS JSON from a static archive (llvm-nm)."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <archive.a> <out.json>", file=sys.stderr)
        return 2
    archive = Path(sys.argv[1])
    out = Path(sys.argv[2])
    root = Path(__file__).resolve().parents[1]
    llvm_nm = root / "emsdk" / "upstream" / "bin" / "llvm-nm"
    if not llvm_nm.is_file():
        llvm_nm = Path("/workspace/emsdk/upstream/bin/llvm-nm")
    text = subprocess.check_output([str(llvm_nm), str(archive)], text=True)
    funcs: list[str] = []
    for line in text.splitlines():
        m = re.search(r" T ([A-Za-z0-9_]+)$", line)
        if m:
            funcs.append("_" + m.group(1))
    out.write_text(json.dumps(sorted(set(funcs))), encoding="utf-8")
    print(f"Wrote {len(funcs)} exports to {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
