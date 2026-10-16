# Shared defaults for opt-in examples. Never install or fetch anything.
.DEFAULT_GOAL := all
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
BUILD ?= $(ROOT)/build/examples/$(patsubst $(ROOT)/src/examples/%,%,$(SOURCE))/$(MODEL)
BUILD := $(abspath $(BUILD))
HRESH_BUILD ?= $(ROOT)/build/hresh
HRESH_BUILD := $(abspath $(HRESH_BUILD))
HRESH ?= $(HRESH_BUILD)/hresh
NATIVE_VOC := $(HRESH_BUILD)/compiler/voc
NATIVE_MODULES := $(HRESH_BUILD)/modules/$(MODEL)

EXAMPLE_ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(SOURCE);$(VOCROOT)/$(MODEL)/sym" \
 CFLAGS="$(CFLAGS) $(EXAMPLE_CFLAGS)" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR)) $(EXAMPLE_LDFLAGS)" \
 LDLIBS="$(LDLIBS) $(EXAMPLE_LDLIBS)"
NATIVE_ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(NATIVE_MODULES)" \
 OBERON="$(BUILD);$(NATIVE_MODULES)" VOC_MODULE_PATH="$(BUILD):$(NATIVE_MODULES)"
RUNTIME_ARGS = BUILD="$(HRESH_BUILD)" MODEL="$(MODEL)" VOC="$(VOC)" \
 VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"

.PHONY: check-voc native-libraries
check-voc:
	@test -x "$(VOC)" && test -d "$(VOCROOT)/$(MODEL)/sym" && test -d "$(VOCLIBDIR)" || { \
	  echo 'Build VOC at the repository root first: make'; \
	  echo 'Or set VOC, VOCROOT and VOCLIBDIR to a matching compiler/library image.'; exit 1; }

$(BUILD):
	mkdir -p "$@"

native-libraries: check-voc
	$(MAKE) -C "$(ROOT)" -f src/tools/hresh/Makefile all libraries $(RUNTIME_ARGS)

# Simple examples supply import-ordered MODULES and executable PROGRAMS lists.
# Native module examples provide their own targets using the defaults above.
ifeq ($(EXAMPLE_CUSTOM),)
.PHONY: all build run
all: build
build: check-voc $(EXAMPLE_DEPS) | $(BUILD)
	cd "$(BUILD)" && for source in $(LIBRARY_SOURCES) $(addprefix $(SOURCE)/,$(addsuffix .Mod,$(MODULES))); do \
	  $(EXAMPLE_ENV) "$(VOC)" -O$(MODEL) -Fs "$$source" || exit; \
	done
	cd "$(BUILD)" && for name in $(PROGRAMS); do \
	  $(EXAMPLE_ENV) "$(VOC)" -O$(MODEL) -sm "$(SOURCE)/$$name.Mod" || exit; \
	done
	@echo 'Example programs are in $(BUILD)'
run: build
	cd "$(SOURCE)" && $(EXAMPLE_ENV) "$(BUILD)/$(firstword $(PROGRAMS))" $(ARGS)
endif
