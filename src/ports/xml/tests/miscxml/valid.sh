#!/bin/sh

SUBDIR="valid/sa valid/not-sa"

err_count=0
for d in $SUBDIR; do
  for i in $d/???.xml; do
    rm -f test-output/$i
    if $TEST_PROG "$i" >test-output/$i; then
      if $DIFF "$d/out/`basename $i`" test-output/$i; then
	echo "ok: $i [wf]"
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i [wf]"
      fi
    else
      err_count=`expr $err_count + 1`
      echo "failed: $i [wf] (exit code is non-zero)"
    fi
    
    rm -f test-output/$i
    if $TEST_PROG -v "$i" >test-output/$i; then
      if $DIFF "$d/out/`basename $i`" test-output/$i; then
	echo "ok: $i [valid]"
      else
	err_count=`expr $err_count + 1`
	echo "failed: $i [valid]"
      fi
    else
      err_count=`expr $err_count + 1`
      echo "failed: $i [valid] (exit code is non-zero)"
    fi
  done
done

test $err_count = "0"
exit $?
