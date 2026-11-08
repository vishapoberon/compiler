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
VOC_MODULE_PATH="$build${VOC_MODULE_PATH:+:$VOC_MODULE_PATH}"
export OBERON VOC_MODULE_PATH
"$compiler" -O"$model" "$flags" "$source/irc/TestIRC.Mod"
./TestIRC
"$compiler" -O"$model" "$flags" "$source/irc/IRCProbe.Mod"
sh "$source/../../tools/make/python.sh" "$source/irc/network.py" "$build/IRCProbe"
