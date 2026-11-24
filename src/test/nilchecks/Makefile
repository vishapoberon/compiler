ROOT := $(abspath ../../..)
VOCROOT ?= $(ROOT)/install
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/nilcheck-tests/$(MODEL)

.PHONY: test stack
test:
	sh "$(ROOT)/src/tools/make/python.sh" test.py --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --work "$(BUILD)"

stack:
	sh "$(ROOT)/src/tools/make/python.sh" test-stack.py --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --work "$(BUILD)/stack"
