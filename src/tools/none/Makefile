VOC ?= voc
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/none
BUILD := $(abspath $(BUILD))

.PHONY: all test
all:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(VOC) -O2 -sm "$(SOURCE)/none.Mod"

test: all
	python3 "$(SOURCE)/test-editor.py" "$(BUILD)/none" --work "$(BUILD)/tests"
