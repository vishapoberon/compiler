#!/bin/sh
set -eu
compiler=$1
build=$2
model=$3
flags=$4
source=$(pwd)/Internet
mkdir -p "$build"
cd "$build"
"$compiler" -O"$model" "$flags" "$source/TestAsyncSockets.Mod"
timeout 20 ./TestAsyncSockets
"$compiler" -O"$model" "$flags" "$source/TestAsyncNetSystem.Mod"
python3 "$source/async-netsystem.py" ./TestAsyncNetSystem
