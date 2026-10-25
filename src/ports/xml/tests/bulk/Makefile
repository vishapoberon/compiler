TEST_PROG=../../TestParser
scripts=./valid.sh

.PHONY: all clean test ${TEST_PROG} nortc

test-output:
	mkdir test-output test-output/valid

${TEST_PROG}:
	cd `dirname ${TEST_PROG}` && ${OOC} -MOv `basename ${TEST_PROG}`

nortc:
	cd `dirname ${TEST_PROG}` && ${OOC} -MOAv --no-rtc --pragmas "Assertions:=FALSE" `basename ${TEST_PROG}`

prof:
	cd `dirname ${TEST_PROG}` && ${OOC} -MOAv --no-rtc --pragmas "Assertions:=FALSE" --cflags "-O2 -p" --ldflags "-p" `basename ${TEST_PROG}`

clean:
	rm -Rf test-output

test: test-output ${TEST_PROG}
	set -e; for i in ${scripts}; do env TEST_PROG="${TEST_PROG}" DIFF="${DIFF}" $$i || exit 1; done
