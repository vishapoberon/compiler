"""Verify the preserved publisher sources against their pinned manifest."""

import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "upstream"
manifest = json.loads((root / "manifest.json").read_text())
assert manifest["revision"] == "dd8a9ca481366bfc3f04d5719837dd0a1940fff5"
assert len(manifest["files"]) == 9
for name, expected in manifest["files"].items():
    data = (root / name).read_bytes()
    assert len(data) == expected["size"] and hashlib.sha256(data).hexdigest() == expected["sha256"], name
print("Preserved XMPP publisher snapshot checks passed: 9 files")
