ROOT := $(abspath ../../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
BUILD ?= $(ROOT)/build/tests/ports/ssqJson/$(MODEL)
BUILD := $(abspath $(BUILD))
SOURCE := $(CURDIR)
ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(VOCROOT)/$(MODEL)/sym" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))"

.PHONY: all test upstream
all: test
test:
	$(MAKE) -C .. test NETWORK=0 VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" MODEL="$(MODEL)" BUILD="$(BUILD)"

# The original program is a demonstration: some fixtures intentionally warn or
# fail to parse. Its printed failures are not assertion-based regression results.
upstream:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(VOC)" -O$(MODEL) -sm "$(SOURCE)/upstream/JsonTest.Mod"
	cd upstream/json && $(ENV) "$(BUILD)/JsonTest"
