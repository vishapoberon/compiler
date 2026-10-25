TEST_PROG=../../TestParser
scripts=./valid.sh ./not-wf.sh

.PHONY: all clean test ${TEST_PROG}

test-output:
	mkdir test-output test-output/valid test-output/not-wf

${TEST_PROG}:
	cd `dirname ${TEST_PROG}` && ${OOC} -MOv `basename ${TEST_PROG}`

clean:
	rm -Rf test-output

test: test-output ${TEST_PROG}
	set -e; for i in ${scripts}; do env TEST_PROG="${TEST_PROG}" DIFF="${DIFF}" $$i || exit 1; done
