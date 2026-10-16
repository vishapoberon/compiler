ROOT := $(abspath ../../..)
MODEL ?= 2
BUILD ?= $(ROOT)/build/ports/coco
BUILD := $(abspath $(BUILD))

.PHONY: all native aixp test test-native test-aixp
all: native aixp
native aixp:
	$(MAKE) -C $@ MODEL="$(MODEL)" BUILD="$(BUILD)/$@/$(MODEL)"
test: test-native test-aixp
test-native test-aixp:
	$(MAKE) -C $(patsubst test-%,%,$@) test MODEL="$(MODEL)" \
	  BUILD="$(BUILD)/$(patsubst test-%,%,$@)/$(MODEL)"
