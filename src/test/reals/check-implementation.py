#!/usr/bin/env python3
"""Keep the audited numeric conversion paths implemented in Oberon."""

from pathlib import Path
import re

root = Path(__file__).resolve().parents[3]
allowed = {
    "src/library/Reals.Mod": set(),
    "src/library/Math.Mod": set(),
    "src/library/MathL.Mod": set(),
    "src/runtime/Texts.Mod": set(),
    "src/compiler/OPS.Mod": set(),
    # This existing primitive measures the C target's alignment.
    "src/compiler/OPM.Mod": {"GetAlignment"},
}
native = re.compile(r"\bPROCEDURE\s+-([A-Za-z][A-Za-z0-9_]*)")
conversion = re.compile(r"\b(?:strtod|strtof|strtold|atof|snprintf|sprintf|sscanf)\s*\(")
for name, permitted in allowed.items():
    source = (root / name).read_text()
    assert set(native.findall(source)) <= permitted, name + ": new native implementation"
    assert not conversion.search(source), name + ": native numeric conversion"

for model in ("unix-44", "unix-48", "unix-88", "windows-48", "windows-88"):
    for module in ("Reals", "Texts", "OPS", "OPM"):
        path = root / "bootstrap" / model / (module + ".c")
        assert not conversion.search(path.read_text()), str(path) + ": stale native conversion"

print("Oberon numeric implementation and bootstrap policy passed")
