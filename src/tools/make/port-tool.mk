.DEFAULT_GOAL := all
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
PYTHON ?= python3
BUILD ?= $(ROOT)/build/ports/$(patsubst $(ROOT)/src/ports/%,%,$(SOURCE))/$(MODEL)
BUILD := $(abspath $(BUILD))

TOOL_ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(SOURCE);$(VOCROOT)/$(MODEL)/sym" \
 CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))" \
 LDLIBS="$(LDLIBS)"

.PHONY: all build check-voc test
all: build
check-voc:
	@test -x "$(VOC)" && test -d "$(VOCROOT)/$(MODEL)/sym" && test -d "$(VOCLIBDIR)" || { \
	  echo 'Build VOC at the repository root first: make'; \
	  echo 'Or set VOC, VOCROOT and VOCLIBDIR to a matching compiler/library image.'; exit 1; }
build: check-voc
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for source in $(TOOL_LIBRARIES) $(addprefix $(SOURCE)/,$(addsuffix .Mod,$(TOOL_MODULES))); do \
	  $(TOOL_ENV) "$(VOC)" -O$(MODEL) -Fs "$$source" || exit; \
	done
	cd "$(BUILD)" && $(TOOL_ENV) "$(VOC)" -O$(MODEL) -sm "$(SOURCE)/$(TOOL_MAIN).Mod"
	cd "$(BUILD)" && for frame in $(TOOL_FRAMES); do cp "$$frame" . || exit; done
test: build
	$(TOOL_ENV) $(PYTHON) "$(ROOT)/src/test/ports/compiler-tools/test_tools.py" \
	  $(TOOL_TEST) --source "$(SOURCE)" --build "$(BUILD)" --voc "$(VOC)" --model "$(MODEL)"
