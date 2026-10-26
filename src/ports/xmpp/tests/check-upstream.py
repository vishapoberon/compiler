#!/usr/bin/env python3
"""Verify the preserved Component Pascal XMPP source snapshot."""

import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "upstream"
manifest = json.loads((root / "manifest.json").read_text())
for entry in manifest["files"]:
    data = (root / entry["path"]).read_bytes()
    assert len(data) == entry["bytes"], entry["path"]
    assert hashlib.sha256(data).hexdigest() == entry["sha256"], entry["path"]
assert len(list((root / "Mod").glob("*.odc"))) == 31
assert len(list((root / "Mod").glob("*.txt"))) == 31
print(f"Preserved XMPP snapshot checks passed: {len(manifest['files'])} files")
