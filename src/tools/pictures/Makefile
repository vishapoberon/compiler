VOC ?= voc
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/pictures
BUILD := $(abspath $(BUILD))

.PHONY: all
all:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(VOC) -O2 -sm "$(SOURCE)/PngCmd.Mod"
	cd "$(BUILD)" && $(VOC) -O2 -sm "$(SOURCE)/JpegCmd.Mod"
	cd "$(BUILD)" && $(VOC) -O2 -sm "$(SOURCE)/GifCmd.Mod"
