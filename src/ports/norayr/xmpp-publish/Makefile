VOC ?= voc
OFLAGS ?= -O2 -s -F
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../../..)
XMPPSRC := $(ROOT)/src/ports/xmpp
BUILD ?= $(ROOT)/build/ports/xmpp-publish/2
BUILD := $(abspath $(BUILD))
MODULES := XmppPEP XmppPublishConfig XmppPublisher

.DEFAULT_GOAL := all
.PHONY: all dependencies test network-test probe
dependencies:
	$(MAKE) -C "$(XMPPSRC)" network VOC="$(VOC)" BUILD="$(BUILD)"
all: dependencies
	cd "$(BUILD)" && for name in $(MODULES); do $(VOC) $(OFLAGS) "$(SOURCE)/$$name.Mod" || exit; done
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/src/examples/network/xmpp-publish/XmppPublish.Mod"
test: all
	python3 "$(SOURCE)/tests/check-upstream.py"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppPublish.Mod" && ./TestXmppPublish
	python3 "$(SOURCE)/tests/config.py" "$(BUILD)"
network-test: all
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/src/examples/network/xmpp-publish/XmppPublishProbe.Mod"
	python3 "$(SOURCE)/tests/loopback.py" "$(BUILD)" "$(XMPPSRC)/tests/loopback.py"
probe: all
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/src/examples/network/xmpp-publish/XmppPublishProbe.Mod"
