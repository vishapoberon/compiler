VOC ?= voc
CC ?= cc
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/none
BUILD := $(abspath $(BUILD))
CONFIGURATION ?= $(if $(wildcard $(ROOT)/Configuration.Mod),$(ROOT)/Configuration.Mod,$(BUILD)/configuration/Configuration.Mod)

.PHONY: all test
all: $(CONFIGURATION)
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(VOC) -O2 -s "$(CONFIGURATION)"
	cd "$(BUILD)" && for module in OPM OPS OPT OPC OPV; do $(VOC) -O2 -s "$(ROOT)/src/compiler/$$module.Mod" || exit; done
	cd "$(BUILD)" && $(VOC) -O2 -s "$(ROOT)/src/tools/browser/BrowserCmd.Mod"
	cd "$(BUILD)" && $(VOC) -O2 -s "$(SOURCE)/NonePaths.Mod"
	cd "$(BUILD)" && $(VOC) -O2 -sm "$(SOURCE)/none.Mod"

$(BUILD)/configuration/Configuration.Mod: $(ROOT)/src/tools/make/configure.c
	mkdir -p "$(dir $@)"
	$(CC) -I"$(ROOT)/src/runtime" "$<" -o "$(dir $@)configure"
	cd "$(dir $@)" && ./configure

test: all
	sh "$(ROOT)/src/tools/make/python.sh" "$(SOURCE)/test-editor.py" "$(BUILD)/none" --voc "$(VOC)" --work "$(BUILD)/tests"
