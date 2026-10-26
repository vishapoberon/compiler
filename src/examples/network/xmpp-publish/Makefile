EXAMPLE_CUSTOM := 1
include ../../../tools/make/example.mk

.PHONY: all build run test native native-test
all: build
build: check-voc | $(BUILD)
	$(MAKE) -C "$(ROOT)/src/ports/norayr/xmpp-publish" all VOC="$(VOC)" BUILD="$(BUILD)"
run: build
	"$(BUILD)/XmppPublish"
test: check-voc | $(BUILD)
	$(MAKE) -C "$(ROOT)/src/ports/norayr/xmpp-publish" test network-test VOC="$(VOC)" BUILD="$(BUILD)"

native: check-voc native-libraries | $(BUILD)
	@test "$$(uname -s)" = Linux && test "$(MODEL)" = 2 || { echo 'The publisher requires Linux and MODEL=2.'; exit 1; }
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -sFl "$(ROOT)/src/ports/xmpp/XmppTCP.Mod"
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -sFl "$(ROOT)/src/ports/norayr/xmpp-publish/XmppPublisher.Mod"
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -smD "$(SOURCE)/XmppPublish.Mod"
native-test: native
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O2 -smD "$(ROOT)/src/ports/norayr/xmpp-publish/tests/TestXmppPublish.Mod"
	python3 "$(ROOT)/src/ports/norayr/xmpp-publish/tests/config.py" "$(BUILD)"
	python3 "$(ROOT)/src/ports/norayr/xmpp-publish/tests/loopback.py" "$(BUILD)" "$(ROOT)/src/ports/xmpp/tests/loopback.py"
