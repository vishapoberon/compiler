# Optional native applications. Never fetch, install or build them by default.
EXAMPLE_CUSTOM := 1
include $(dir $(lastword $(MAKEFILE_LIST)))example.mk

.PHONY: all build run native native-run check-network
all: build
check-network: check-voc
	@test "$$(uname -s)" = Linux && test "$(MODEL)" = 2 || { echo 'These network ports require Linux and MODEL=2.'; exit 1; }

build: check-network | $(BUILD)
	cd "$(BUILD)" && $(EXAMPLE_ENV) "$(VOC)" -O2 -sF "$(ROOT)/src/examples/network/support/PortArgs.Mod"
	cd "$(BUILD)" && $(EXAMPLE_ENV) "$(VOC)" -O2 -sF "$(SOURCE)/$(APPLICATION).Mod"
	cd "$(BUILD)" && $(EXAMPLE_ENV) "$(VOC)" -O2 -sm "$(SOURCE)/$(APPLICATION)Main.Mod"
	mv "$(BUILD)/$(APPLICATION)Main" "$(BUILD)/$(APPLICATION)"
	@echo 'Application: $(BUILD)/$(APPLICATION)'

run: build
	cd "$(SOURCE)" && $(EXAMPLE_ENV) "$(BUILD)/$(APPLICATION)" $(ARGS)

native: check-network native-libraries | $(BUILD)
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -sFl "$(ROOT)/src/examples/network/support/PortArgs.Mod"
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -sFl "$(SOURCE)/$(APPLICATION).Mod"

native-run: native
	cd "$(SOURCE)" && $(NATIVE_ENV) "$(HRESH)" "-P$(BUILD):$(NATIVE_MODULES)" "$(APPLICATION).$(COMMAND)" $(ARGS)
