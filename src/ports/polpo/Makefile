VOC ?= voc
ROOT := $(abspath ../../..)
BUILD ?= $(ROOT)/build/ports/pictures
BUILD := $(abspath $(BUILD))

.PHONY: all test
all:
	sh "$(ROOT)/src/tools/make/python.sh" check-codecs.py --voc "$(VOC)" --build "$(BUILD)" --build-only
test:
	sh "$(ROOT)/src/tools/make/python.sh" check-codecs.py --voc "$(VOC)" --build "$(BUILD)"
