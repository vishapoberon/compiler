VOC ?= voc
CC ?= cc
VOCROOT ?= /usr/share/voc
VOCLIBDIR ?= $(dir $(shell $(CC) -print-file-name=libvoc-O2.so))
MODEL ?= 2
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
DEMO := $(ROOT)/src/test/shared-libraries
HRESH_BUILD ?= $(ROOT)/build/hresh
HRESH_BUILD := $(abspath $(HRESH_BUILD))
BUILD ?= $(ROOT)/build/tests/shared-libraries/$(MODEL)
BUILD := $(abspath $(BUILD))
NATIVE_VOC := $(HRESH_BUILD)/compiler/voc
MODULES := $(HRESH_BUILD)/modules/$(MODEL)
HOST_MODE ?= md
ENV := VOCROOT="$(VOCROOT)" VOCLIBDIR="$(MODULES)" OBERON="$(MODULES)"
RUNTIME_ARGS := BUILD="$(HRESH_BUILD)" MODEL="$(MODEL)" VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"

.PHONY: all libraries for-hresh application standalone hresh-host run-hresh run-standalone shell test
all: for-hresh standalone
libraries:
	$(MAKE) -C "$(ROOT)" -f src/tools/hresh/Makefile libraries $(RUNTIME_ARGS)
	mkdir -p "$(BUILD)"
for-hresh: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(DEMO)/LibraryDemo.Mod"
standalone: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -s$(HOST_MODE) "$(DEMO)/LibraryMain.Mod"
application: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(DEMO)/LibraryMain.Mod"
hresh-host: libraries
	$(MAKE) -C "$(ROOT)" -f src/tools/hresh/Makefile all $(RUNTIME_ARGS)
run-hresh: for-hresh hresh-host
	"$(HRESH_BUILD)/hresh" "-P$(BUILD):$(MODULES)" LibraryDemo.Run
run-standalone: standalone
	"$(BUILD)/LibraryMain"
shell: for-hresh hresh-host
	"$(HRESH_BUILD)/hresh" "-P$(BUILD):$(MODULES)"
test: run-hresh run-standalone
