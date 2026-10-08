VOC ?= voc
CC ?= cc
VOCROOT ?= /usr/share/voc
VOCLIBDIR ?= $(dir $(shell $(CC) -print-file-name=libvoc-O2.so))
MODEL ?= 2
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
DEMO := $(ROOT)/src/test/shared-libraries
VISH_BUILD ?= $(ROOT)/build/vish
VISH_BUILD := $(abspath $(VISH_BUILD))
BUILD ?= $(ROOT)/build/tests/shared-libraries/$(MODEL)
BUILD := $(abspath $(BUILD))
NATIVE_VOC := $(VISH_BUILD)/compiler/voc
MODULES := $(VISH_BUILD)/modules/$(MODEL)
HOST_MODE ?= md
ENV := VOCROOT="$(VOCROOT)" VOCLIBDIR="$(MODULES)" OBERON="$(MODULES)"
RUNTIME_ARGS := BUILD="$(VISH_BUILD)" MODEL="$(MODEL)" VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"

.PHONY: all libraries for-vish application standalone vish-host run-vish run-standalone shell test
all: for-vish standalone
libraries:
	$(MAKE) -C "$(ROOT)" -f src/tools/vish/Makefile libraries $(RUNTIME_ARGS)
	mkdir -p "$(BUILD)"
for-vish: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(DEMO)/LibraryDemo.Mod"
standalone: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -s$(HOST_MODE) "$(DEMO)/LibraryMain.Mod"
application: libraries
	cd "$(BUILD)" && $(ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(DEMO)/LibraryMain.Mod"
vish-host: libraries
	$(MAKE) -C "$(ROOT)" -f src/tools/vish/Makefile all $(RUNTIME_ARGS)
run-vish: for-vish vish-host
	"$(VISH_BUILD)/vish" "-P$(BUILD):$(MODULES)" LibraryDemo.Run
run-standalone: standalone
	"$(BUILD)/LibraryMain"
shell: for-vish vish-host
	"$(VISH_BUILD)/vish" "-P$(BUILD):$(MODULES)"
test: run-vish run-standalone
