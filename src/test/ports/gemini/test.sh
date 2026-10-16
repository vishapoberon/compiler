#!/bin/sh
set -eu
compiler=$1
build=$2
model=$3
flags=$4
source=$(pwd)
mkdir -p "$build"
cd "$build"
OBERON="$build;${OBERON-}"
export OBERON
case "$flags" in
  *[dDP]*) library_flags=-sFl ;;
  *) library_flags=-sF ;;
esac
"$compiler" -O"$model" "$library_flags" "$source/gemini/GeminiTest.Mod"
"$compiler" -O"$model" "$flags" "$source/gemini/RunGeminiTest.Mod"
./RunGeminiTest
python3 - "$build/zq_idents" <<'PY'
from pathlib import Path
import stat
import sys
directory = Path(sys.argv[1])
assert stat.S_IMODE(directory.stat().st_mode) == 0o700
keys = list(directory.glob('*.key'))
assert len(keys) == 2
for key in keys:
    assert stat.S_IMODE(key.stat().st_mode) == 0o600
assert all(path.suffix in {'.crt', '.key'} for path in directory.iterdir())
print('Gemini identity permissions passed')
PY
