EXAMPLE_CUSTOM := 1
include ../../../tools/make/example.mk

.PHONY: all build run test native native-test
all: build
build: check-voc | $(BUILD)
	@test "$$(uname -s)" = Linux && test "$(MODEL)" = 2 || { echo 'The IRC example requires Linux and MODEL=2.'; exit 1; }
	cd "$(BUILD)" && $(EXAMPLE_ENV) "$(VOC)" -O2 -sm "$(SOURCE)/vocbot.Mod"
run: build
	cd "$(BUILD)" && $(EXAMPLE_ENV) ./vocbot $(ARGS)
test: build
	$(EXAMPLE_ENV) python3 "$(SOURCE)/tests/reconnect.py" "$(BUILD)/vocbot"
native: check-voc native-libraries | $(BUILD)
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -smD "$(SOURCE)/vocbot.Mod"
native-test: native
	$(NATIVE_ENV) python3 "$(SOURCE)/tests/reconnect.py" "$(BUILD)/vocbot"
