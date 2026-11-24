ROOT := $(abspath ../../..)
VOCROOT ?= $(ROOT)/install
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/nilcheck-tests/$(MODEL)

.PHONY: test
test:
	sh "$(ROOT)/src/tools/make/python.sh" test.py --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --work "$(BUILD)"
