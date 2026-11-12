ROOT := $(abspath ../../../..)
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/examples/hald/$(MODEL)
BUILD := $(abspath $(BUILD))
HERE := $(CURDIR)
PORTS := $(ROOT)/src/ports
CFLAGS ?= -O3 -fno-strict-aliasing
export CFLAGS VOCROOT VOCLIBDIR

.PHONY: all sequential cpu codecs test
all: sequential cpu

codecs: $(BUILD)/codecs/ready

$(BUILD)/codecs/ready: $(ROOT)/src/library/Args.Mod $(wildcard $(PORTS)/s3/Zlib*.Mod) $(PORTS)/polpo/png-codec/src/PNG0.Mod $(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod Makefile
	mkdir -p "$(BUILD)/codecs"
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(ROOT)/src/library/Args.Mod"
	cd "$(BUILD)/codecs" && for name in Zlib ZlibBuffers ZlibInflate ZlibDeflate; do "$(VOC)" -O$(MODEL) -sF "$(PORTS)/s3/$$name.Mod" || exit; done
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(PORTS)/polpo/png-codec/src/PNG0.Mod" "$(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod"
	touch "$@"

sequential: codecs
	mkdir -p "$(BUILD)/sequential"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/sequential/"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFj "$(HERE)/HaldClut.Mod"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFm "$(HERE)/HaldCmd.Mod"

cpu: codecs
	mkdir -p "$(BUILD)/cpu"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/cpu/"
	cd "$(BUILD)/cpu" && "$(VOC)" -O$(MODEL) -sFjP "$(HERE)/HaldClut.Mod"
	cd "$(BUILD)/cpu" && "$(VOC)" -O$(MODEL) -sFmjP "$(HERE)/HaldCmd.Mod"

test: all
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" DYLD_LIBRARY_PATH="$(VOCLIBDIR)$${DYLD_LIBRARY_PATH:+:$$DYLD_LIBRARY_PATH}" sh "$(ROOT)/src/tools/make/python.sh" test.py --build "$(BUILD)"
