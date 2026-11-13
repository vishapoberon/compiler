ROOT := $(abspath ../../../..)
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/examples/gpu/$(MODEL)
BUILD := $(abspath $(BUILD))
HERE := $(CURDIR)
GPU_CC ?= clang
GPU_CFLAGS ?= -O3 -fno-strict-aliasing
CPU_OPENMP_CFLAGS ?= -fopenmp
export VOCROOT VOCLIBDIR

.PHONY: all sequential cpu gpu probe run-sequential run-cpu run-gpu test-fallback
all: sequential cpu

sequential:
	mkdir -p "$(BUILD)/sequential"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFjc "$(HERE)/GPUArrays.Mod"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFjm "$(HERE)/UseGPU.Mod" "$(HERE)/Vectors.Mod"

cpu:
	mkdir -p "$(BUILD)/cpu"
	cd "$(BUILD)/cpu" && VOC_OPENMP_CFLAGS="$(CPU_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(CPU_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFjcP "$(HERE)/GPUArrays.Mod"
	cd "$(BUILD)/cpu" && VOC_OPENMP_CFLAGS="$(CPU_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(CPU_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFjmP "$(HERE)/UseGPU.Mod" "$(HERE)/Vectors.Mod"

gpu:
	mkdir -p "$(BUILD)/gpu"
	cd "$(BUILD)/gpu" && CC="$(GPU_CC)" CFLAGS="$(GPU_CFLAGS)" "$(VOC)" -O$(MODEL) -sFjcG "$(HERE)/GPUArrays.Mod"
	cd "$(BUILD)/gpu" && CC="$(GPU_CC)" CFLAGS="$(GPU_CFLAGS)" "$(VOC)" -O$(MODEL) -sFjmG "$(HERE)/UseGPU.Mod" "$(HERE)/Vectors.Mod"

probe:
	mkdir -p "$(BUILD)/gpu"
	$(GPU_CC) $(GPU_CFLAGS) $(VOC_OPENMP_CFLAGS) "$(ROOT)/src/test/oberonv/DeviceProbe.c" $(VOC_OPENMP_LDFLAGS) -o "$(BUILD)/gpu/DeviceProbe"
	OMP_TARGET_OFFLOAD=MANDATORY "$(BUILD)/gpu/DeviceProbe"

run-sequential: sequential
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/sequential/UseGPU"
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/sequential/Vectors"

run-cpu: cpu
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/cpu/UseGPU"
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/cpu/Vectors"

run-gpu: gpu probe
	OMP_TARGET_OFFLOAD=MANDATORY LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/gpu/UseGPU"
	OMP_TARGET_OFFLOAD=MANDATORY LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/gpu/Vectors"

test-fallback: gpu
	OMP_TARGET_OFFLOAD=DISABLED LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/gpu/UseGPU"
	OMP_TARGET_OFFLOAD=DISABLED LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" "$(BUILD)/gpu/Vectors"
