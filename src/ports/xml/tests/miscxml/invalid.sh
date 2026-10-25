#!/bin/sh

SUBDIR="invalid"

err_count=0
for d in $SUBDIR; do
  for i in $d/???.xml; do
    rm -f test-output/$i test-output/$i.err
    if $TEST_PROG -i "$i" >test-output/$i 2>test-output/$i.err; then
	echo "ok: $i [wf]"
    else
	err_count=`expr $err_count + 1`
	echo "failed: $i [wf] (exit code is non-zero)"
    fi
    
    if $TEST_PROG -v "$i" >test-output/$i 2>test-output/$i.err; then
      err_count=`expr $err_count + 1`
      echo "failed: $i [valid] (exit code is zero)"
    else
      if $DIFF "$d/out-err/`basename $i`.err" test-output/$i.err; then
	echo "ok: $i [valid]"
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i [valid]"
      fi
    fi
  done
done

test $err_count = "0"
exit $?
