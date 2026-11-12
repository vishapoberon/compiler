ROOT := $(abspath ../../..)
VOCROOT ?= $(ROOT)/install
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/oberonv-tests/$(MODEL)
BUILD := $(abspath $(BUILD))
HRESH_BUILD ?= $(ROOT)/build/hresh
HRESH ?= $(HRESH_BUILD)/hresh
MODULES ?= $(HRESH_BUILD)/modules/$(MODEL)
GPU_CC ?= gcc
GPU_CLANG ?= clang
GPU_ARCH ?= sm_53
GPU_TIMEOUT ?= 120
RUN_PYTHON = sh "$(ROOT)/src/tools/make/python.sh"
ARGS = --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)"

.PHONY: test test-cpu test-shared test-gpu test-gpu-compile test-gpu-shared test-gpu-device benchmark
test:
	$(RUN_PYTHON) test.py $(ARGS) --work "$(BUILD)/sequential"

test-cpu:
	$(RUN_PYTHON) test.py $(ARGS) --cpu --work "$(BUILD)/cpu"
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/driver"

test-shared:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/shared" --hresh "$(HRESH)" --modules "$(MODULES)"

test-gpu:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu" --timeout "$(GPU_TIMEOUT)"

test-gpu-compile:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CLANG)" --work "$(BUILD)/gpu-compile" --ptx-arch "$(GPU_ARCH)" --timeout "$(GPU_TIMEOUT)"

test-gpu-shared:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu-shared" --hresh "$(HRESH)" --modules "$(MODULES)" --timeout "$(GPU_TIMEOUT)"

test-gpu-device:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu-device" --device --timeout "$(GPU_TIMEOUT)"

benchmark:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/benchmark" --benchmark
