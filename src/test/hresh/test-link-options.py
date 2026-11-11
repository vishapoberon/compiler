"""Check module-library option parsing without invoking the C compiler."""

from pathlib import Path
import subprocess
import sys

voc = str(Path(sys.argv[1]).resolve())
work = Path(sys.argv[2]).resolve()
work.mkdir(parents=True, exist_ok=True)
for name in ("LinkOptionsA", "LinkOptionsB"):
    (work / (name + ".Mod")).write_text("MODULE " + name + "; END " + name + ".\n")


def compile(*args, diagnostic=None):
    result = subprocess.run([voc, *args], cwd=work, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if diagnostic is None:
        assert result.returncode == 0, result.stdout
    else:
        assert result.returncode != 0 and diagnostic in result.stdout, result.stdout
    return result.stdout


def options(name):
    return (work / (name + ".c")).read_text().splitlines()[0].split()[-2]


compile("-sSmL", "LinkOptionsA.Mod")
assert "L" in options("LinkOptionsA")
compile("-sSLL", "LinkOptionsA.Mod")
assert "L" not in options("LinkOptionsA")
compile("-sS", "LinkOptionsA.Mod", "-mL", "LinkOptionsB.Mod")
assert "L" in options("LinkOptionsA")
assert "L" not in options("LinkOptionsB")
compile("-sS", "LinkOptionsA.Mod", "-L", diagnostic="-L requires")
compile("-sSML", "LinkOptionsA.Mod", diagnostic="-ML is not supported")
compile("-sSl", "LinkOptionsA.Mod")
assert "L" in options("LinkOptionsA")
help_text = subprocess.run([voc], text=True, stdout=subprocess.PIPE).stdout
assert "-mL" in help_text and "-mP" not in help_text
print("module-library option tests passed")
