#!/bin/sh

SUBDIR="valid"

err_count=0
for d in $SUBDIR; do
  for i in $d/*.xml; do
    rm -f test-output/$i
    #echo $TEST_PROG "$i"
    if $TEST_PROG "$i" >test-output/$i; then
      if $DIFF "$d/out/`basename $i`" test-output/$i; then
	echo "ok: $i"
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i"
        exit 1
      fi
    else
      err_count=`expr $err_count + 1`
      echo "failed: $i (exit code is non-zero)"
      exit 1
    fi
  done
done

test $err_count = "0"
exit $?
