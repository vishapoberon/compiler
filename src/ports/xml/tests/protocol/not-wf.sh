#!/bin/sh

SUBDIR="not-wf"

err_count=0
for d in $SUBDIR; do
  for i in $d/???.xml; do
    rm -f test-output/$i test-output/$i.err
    if $TEST_PROG -p "$i" >test-output/$i 2>test-output/$i.err; then
      err_count=`expr $err_count + 1`
      echo "failed: $i (exit code is zero)"
    else
      if $DIFF "$d/out-err/`basename $i`.err" test-output/$i.err; then
	if $DIFF "$d/out/`basename $i`" test-output/$i; then
	  echo "ok: $i"
	else
	  err_count=`expr $err_count + 1`
	  echo "failed: $i"
	fi
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i"
      fi
    fi
  done
done

test $err_count = "0"
exit $?
