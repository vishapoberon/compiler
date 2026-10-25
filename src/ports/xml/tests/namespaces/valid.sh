#!/bin/sh

SUBDIR="valid"

err_count=0
for d in $SUBDIR; do
  for i in $d/???.xml; do
    rm -f test-output/$i
    if $TEST_PROG -n -p "$i" >test-output/$i; then
      if $DIFF "$d/out/`basename $i`" test-output/$i; then
	echo "ok: $i"
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i"
      fi
    else
      err_count=`expr $err_count + 1`
      echo "failed: $i (exit code is non-zero)"
    fi
  done
done

test $err_count = "0"
exit $?
