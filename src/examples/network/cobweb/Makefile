APPLICATION := cobweb
COMMAND ?= Serve
include ../../../tools/make/network-application.mk

.PHONY: test
test:
	$(MAKE) -C ../../../test/ports/applications test VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" BUILD="$(BUILD)/tests"
