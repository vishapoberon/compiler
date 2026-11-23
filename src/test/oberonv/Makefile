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
GPU_CFLAGS ?= -O2 -fno-strict-aliasing
CPU_CC ?= gcc
CPU_BENCH_ARGS ?=
GPU_BENCH_ARGS ?=
RUN_PYTHON = sh "$(ROOT)/src/tools/make/python.sh"
ARGS = --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)"

.PHONY: test test-independence test-cpu test-cpu-vectorization test-shared test-gpu test-gpu-compile test-gpu-shared test-gpu-device benchmark benchmark-cpu benchmark-gpu test-reductions test-reductions-cpu test-reductions-gpu test-reductions-device
test:
	$(RUN_PYTHON) test.py $(ARGS) --work "$(BUILD)/sequential"
	$(RUN_PYTHON) test-reductions.py $(ARGS) --work "$(BUILD)/reductions-sequential"
	$(RUN_PYTHON) test-independence.py $(ARGS) --work "$(BUILD)/independence"

test-independence:
	$(RUN_PYTHON) test-independence.py $(ARGS) --work "$(BUILD)/independence"

test-cpu:
	$(RUN_PYTHON) test.py $(ARGS) --cpu --work "$(BUILD)/cpu"
	$(RUN_PYTHON) test-independence.py $(ARGS) --cpu --cc "$(CPU_CC)" --work "$(BUILD)/independence-cpu"
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/driver"
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode cpu --work "$(BUILD)/reductions-cpu"

test-cpu-vectorization:
	$(RUN_PYTHON) test-vectorization.py $(ARGS) --cc "$(CPU_CC)" --mode sequential --work "$(BUILD)/vectorization/sequential"
	$(RUN_PYTHON) test-vectorization.py $(ARGS) --cc "$(CPU_CC)" --mode cpu --work "$(BUILD)/vectorization/cpu"

test-shared:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/shared" --hresh "$(HRESH)" --modules "$(MODULES)"

test-gpu:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu" --timeout "$(GPU_TIMEOUT)" --cflags="$(GPU_CFLAGS)"
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode gpu --cc "$(GPU_CC)" --work "$(BUILD)/reductions-gpu" --cflags="$(GPU_CFLAGS)"

test-gpu-compile:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CLANG)" --work "$(BUILD)/gpu-compile" --ptx-arch "$(GPU_ARCH)" --timeout "$(GPU_TIMEOUT)" --cflags="$(GPU_CFLAGS)"

test-gpu-shared:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu-shared" --hresh "$(HRESH)" --modules "$(MODULES)" --timeout "$(GPU_TIMEOUT)" --cflags="$(GPU_CFLAGS)"

test-gpu-device:
	$(RUN_PYTHON) test-gpu.py $(ARGS) --cc "$(GPU_CC)" --work "$(BUILD)/gpu-device" --device --timeout "$(GPU_TIMEOUT)" --cflags="$(GPU_CFLAGS)"
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode gpu --cc "$(GPU_CC)" --work "$(BUILD)/reductions-device" --device --cflags="$(GPU_CFLAGS)"

test-reductions:
	$(RUN_PYTHON) test-reductions.py $(ARGS) --work "$(BUILD)/reductions-sequential"

test-reductions-cpu:
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode cpu --work "$(BUILD)/reductions-cpu"

test-reductions-gpu:
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode gpu --cc "$(GPU_CC)" --work "$(BUILD)/reductions-gpu" --cflags="$(GPU_CFLAGS)"

test-reductions-device:
	$(RUN_PYTHON) test-reductions.py $(ARGS) --mode gpu --cc "$(GPU_CC)" --work "$(BUILD)/reductions-device" --device --cflags="$(GPU_CFLAGS)"

benchmark:
	$(RUN_PYTHON) test-openmp.py $(ARGS) --work "$(BUILD)/benchmark" --benchmark

benchmark-cpu:
	$(RUN_PYTHON) benchmark-cpu.py $(ARGS) --cc "$(CPU_CC)" --work "$(BUILD)/benchmark-cpu" $(CPU_BENCH_ARGS)

benchmark-gpu:
	$(RUN_PYTHON) benchmark-cpu.py $(ARGS) --gpu --cc "$(GPU_CC)" --work "$(BUILD)/benchmark-gpu" $(GPU_BENCH_ARGS)
