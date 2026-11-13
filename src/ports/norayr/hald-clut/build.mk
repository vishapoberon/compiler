VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD := $(abspath $(BUILD))
PORTS := $(ROOT)/src/ports
HALD_BUILD_MK := $(lastword $(MAKEFILE_LIST))
CFLAGS ?= -O3 -fno-strict-aliasing
GPU_CC ?= clang
GPU_CFLAGS ?= -O3 -fno-strict-aliasing
KERNEL_CC ?= gcc
KERNEL_CFLAGS ?= -O3 -fno-strict-aliasing
KERNEL_OPENMP_CFLAGS ?= -fopenmp
CPU_OPENMP_CFLAGS ?= -fopenmp
GPU_BACKEND := $(dir $(HALD_SOURCE))kernel.py
RUN_PYTHON = sh "$(ROOT)/src/tools/make/python.sh"
export CFLAGS VOCROOT VOCLIBDIR VOC_OPENMP_CFLAGS VOC_OPENMP_LDFLAGS

.PHONY: all sequential cpu gpu cpu-kernel codecs test test-gpu test-gpu-device test-cpu-kernel check-source
all: sequential cpu

check-source:
	@test -f "$(PORTS)/polpo/png-codec/src/PNG0.Mod" -a -f "$(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod" || { echo 'set VOC_SOURCE to a VOC source tree containing the PNG and JPEG codecs'; exit 1; }

codecs: check-source $(BUILD)/codecs/ready

$(BUILD)/codecs/ready: $(ROOT)/src/library/Args.Mod $(wildcard $(PORTS)/s3/Zlib*.Mod) $(PORTS)/polpo/png-codec/src/PNG0.Mod $(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod $(HALD_BUILD_MK)
	mkdir -p "$(BUILD)/codecs"
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(ROOT)/src/library/Args.Mod"
	cd "$(BUILD)/codecs" && for name in Zlib ZlibBuffers ZlibInflate ZlibDeflate; do "$(VOC)" -O$(MODEL) -sF "$(PORTS)/s3/$$name.Mod" || exit; done
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(PORTS)/polpo/png-codec/src/PNG0.Mod" "$(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod"
	touch "$@"

sequential: codecs
	mkdir -p "$(BUILD)/sequential"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/sequential/"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFj "$(HALD_SOURCE)"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFm "$(COMMAND_SOURCE)"
ifneq ($(BENCH_SOURCE),)
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFm "$(BENCH_SOURCE)"
endif

cpu: codecs
	mkdir -p "$(BUILD)/cpu"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/cpu/"
	cd "$(BUILD)/cpu" && VOC_OPENMP_CFLAGS="$(CPU_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(CPU_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFjP "$(HALD_SOURCE)"
	cd "$(BUILD)/cpu" && VOC_OPENMP_CFLAGS="$(CPU_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(CPU_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjP "$(COMMAND_SOURCE)"
ifneq ($(BENCH_SOURCE),)
	cd "$(BUILD)/cpu" && VOC_OPENMP_CFLAGS="$(CPU_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(CPU_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjP "$(BENCH_SOURCE)"
endif

gpu: codecs
	mkdir -p "$(BUILD)/gpu"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/gpu/"
	$(RUN_PYTHON) "$(GPU_BACKEND)" --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --source "$(HALD_SOURCE)" --work "$(BUILD)/gpu" --cc "$(GPU_CC)" --cflags="$(GPU_CFLAGS)"
	cd "$(BUILD)/gpu" && CC="$(GPU_CC)" CFLAGS="$(GPU_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjG "$(COMMAND_SOURCE)"
ifneq ($(BENCH_SOURCE),)
	cd "$(BUILD)/gpu" && CC="$(GPU_CC)" CFLAGS="$(GPU_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjG "$(BENCH_SOURCE)"
endif

cpu-kernel: codecs
	mkdir -p "$(BUILD)/cpu-kernel"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/cpu-kernel/"
	VOC_OPENMP_CFLAGS="$(KERNEL_OPENMP_CFLAGS)" $(RUN_PYTHON) "$(GPU_BACKEND)" --backend cpu --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --source "$(HALD_SOURCE)" --work "$(BUILD)/cpu-kernel" --cc "$(KERNEL_CC)" --cflags="$(KERNEL_CFLAGS)"
	cd "$(BUILD)/cpu-kernel" && CC="$(KERNEL_CC)" CFLAGS="$(KERNEL_CFLAGS)" VOC_OPENMP_CFLAGS="$(KERNEL_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(KERNEL_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjP "$(COMMAND_SOURCE)"
ifneq ($(BENCH_SOURCE),)
	cd "$(BUILD)/cpu-kernel" && CC="$(KERNEL_CC)" CFLAGS="$(KERNEL_CFLAGS)" VOC_OPENMP_CFLAGS="$(KERNEL_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(KERNEL_OPENMP_CFLAGS)" "$(VOC)" -O$(MODEL) -sFmjP "$(BENCH_SOURCE)"
endif

test: all
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" DYLD_LIBRARY_PATH="$(VOCLIBDIR)$${DYLD_LIBRARY_PATH:+:$$DYLD_LIBRARY_PATH}" sh "$(ROOT)/src/tools/make/python.sh" "$(TEST_SOURCE)" --build "$(BUILD)"

test-gpu: gpu
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(TEST_SOURCE)" --build "$(BUILD)" --modes gpu
ifneq ($(BACKEND_TEST_SOURCE),)
	OMP_TARGET_OFFLOAD=DISABLED LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(BACKEND_TEST_SOURCE)" --build "$(BUILD)/gpu" --backend "$(GPU_BACKEND)" --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --cc "$(GPU_CC)" --cflags="$(GPU_CFLAGS)" --gpu
endif

test-gpu-device: gpu
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(TEST_SOURCE)" --build "$(BUILD)" --modes gpu --device --cc "$(GPU_CC)" --cflags="$(GPU_CFLAGS)" --probe "$(ROOT)/src/test/oberonv/DeviceProbe.c"
ifneq ($(BACKEND_TEST_SOURCE),)
	OMP_TARGET_OFFLOAD=MANDATORY LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(BACKEND_TEST_SOURCE)" --build "$(BUILD)/gpu" --backend "$(GPU_BACKEND)" --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --cc "$(GPU_CC)" --cflags="$(GPU_CFLAGS)" --gpu
endif

test-cpu-kernel: cpu-kernel
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(TEST_SOURCE)" --build "$(BUILD)" --modes cpu-kernel
ifneq ($(BACKEND_TEST_SOURCE),)
	VOC_OPENMP_CFLAGS="$(KERNEL_OPENMP_CFLAGS)" VOC_OPENMP_LDFLAGS="$(KERNEL_OPENMP_CFLAGS)" LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(BACKEND_TEST_SOURCE)" --build "$(BUILD)/cpu-kernel" --backend "$(GPU_BACKEND)" --voc "$(VOC)" --vocroot "$(VOCROOT)" --model "$(MODEL)" --cc "$(KERNEL_CC)" --cflags="$(KERNEL_CFLAGS)"
endif
