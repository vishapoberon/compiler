#!/bin/sh
set -eu
compiler=$1
build=$2
model=$3
flags=$4
source=$(pwd)
certs="$source/tls/certs"
mkdir -p "$build"
cd "$build"
OBERON="$build;${OBERON-}"
export OBERON
"$compiler" -O"$model" "$flags" "$source/Internet/TestServerInit.Mod"
./TestServerInit
count=0
for path in "$source"/tls/TLSTest*.Mod; do
  name=${path##*/}
  name=${name%.Mod}
  "$compiler" -O"$model" "$flags" "$path"
  if ! TLS_TEST_CERTS="$certs" "./$name" >"$name.log" 2>&1; then
    cat "$name.log"
    exit 1
  fi
  if grep -E 'FAIL| [1-9][0-9]* failed' "$name.log"; then
    cat "$name.log"
    exit 1
  fi
  count=$((count + 1))
done
test "$count" -eq 36
echo "$count TLS test programs passed"
"$compiler" -O"$model" "$flags" "$source/Internet/TestNetworkClient.Mod"
"$compiler" -O"$model" "$flags" "$source/tls/TestTLSListener.Mod"
python3 "$source/tls/loopback.py" "$build"
