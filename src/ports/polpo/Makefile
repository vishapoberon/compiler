VOC ?= voc
ROOT := $(abspath ../../..)
BUILD ?= $(ROOT)/build/ports/pictures
BUILD := $(abspath $(BUILD))

.PHONY: all test
all:
	python3 check-codecs.py --voc "$(VOC)" --build "$(BUILD)" --build-only
test:
	python3 check-codecs.py --voc "$(VOC)" --build "$(BUILD)"
