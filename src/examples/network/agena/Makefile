APPLICATION := agena
COMMAND ?= Serve
include ../../../tools/make/network-application.mk

.PHONY: test domain-names test-names native-test-names
build: domain-names
domain-names: check-voc | $(BUILD)
	$(MAKE) -C "$(ROOT)/src/ports/punycode" all BUILD="$(BUILD)" VOC="$(VOC)" MODEL=2

test-names: build
	cd "$(BUILD)" && $(EXAMPLE_ENV) "$(VOC)" -O2 -sFm "$(ROOT)/src/test/ports/agena/TestAgenaNames.Mod" && ./TestAgenaNames

native-test-names: native
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -smD "$(ROOT)/src/test/ports/agena/TestAgenaNames.Mod" && ./TestAgenaNames

test:
	$(MAKE) -C ../../../test/ports/applications test VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" BUILD="$(BUILD)/tests"
