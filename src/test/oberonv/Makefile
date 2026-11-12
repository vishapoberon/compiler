ROOT := $(abspath ../../..)
VOCROOT ?= $(ROOT)/install
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/oberonv-tests/$(MODEL)
BUILD := $(abspath $(BUILD))
HRESH_BUILD ?= $(ROOT)/build/hresh
HRESH ?= $(HRESH_BUILD)/hresh
MODULES ?= $(HRESH_BUILD)/modules/$(MODEL)
RUN_PYTHON = sh "$(ROOT)/src/tools/make/python.sh"
ARGS = --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)"

.PHONY: test test-cpu test-shared benchmark
test:
	$(RUN_PYTHON) test.py $(ARGS) --work "$(BUILD)/sequential"

test-cpu:
	$(RUN_PYTHON) test.py $(ARGS) --cpu --work "$(BUILD)/cpu"
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/driver"

test-shared:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/shared" --hresh "$(HRESH)" --modules "$(MODULES)"

benchmark:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/benchmark" --benchmark
