VOC ?= voc
.DEFAULT_GOAL := all
OFLAGS ?= -O2 -s -F
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/ports/xmpp/2
BUILD := $(abspath $(BUILD))
MODULES := XmppTypes XmppConst XmppItems XmppXmlStream XmppXmlGen XmppConnections \
 XmppStrings XmppCore XmppMessenger XmppWire XmppSasl XmppClient \
 XmppIQ XmppPresence XmppPresenceTracker XmppPing XmppVersion XmppDisco XmppRoster XmppPubSub

include $(ROOT)/src/tools/make/modular-libraries.mk
NETWORK_MODULES := $(MODULAR_INTERNET) $(filter-out norayr/tls/httpsPure,$(MODULAR_TLS))
# Linux's openat/syscall declarations are hidden in strict C language modes.
NETWORK_CFLAGS = $(CFLAGS) -D_DEFAULT_SOURCE

.PHONY: all dependencies test network network-test probe tls-regression clean
dependencies:
	$(MAKE) -C "$(SOURCE)/../xml" BUILD="$(BUILD)" VOC="$(VOC)" all
	$(MAKE) -C "$(SOURCE)/../punycode" BUILD="$(BUILD)" VOC="$(VOC)" all

all: dependencies
	cd "$(BUILD)" && for name in $(MODULES); do \
		$(VOC) $(OFLAGS) "$(SOURCE)/$$name.Mod" || exit; \
	done

test: all
	python3 "$(SOURCE)/tests/check-upstream.py"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppStream.Mod" && timeout 30 ./TestXmppStream
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppCore.Mod" && timeout 30 ./TestXmppCore
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppClient.Mod" && timeout 30 ./TestXmppClient
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppIQ.Mod" && timeout 30 ./TestXmppIQ
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppRosterPubSub.Mod" && timeout 30 ./TestXmppRosterPubSub
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppPresence.Mod" && timeout 30 ./TestXmppPresence

network: all
	@test "$$(uname -s)" = Linux || { echo "The XMPP TCP/TLS driver currently requires Linux."; exit 1; }
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" VOC="$(VOC)" idna
	cd "$(BUILD)" && for name in $(NETWORK_MODULES); do \
		CFLAGS="$(NETWORK_CFLAGS)" $(VOC) $(OFLAGS) "$(ROOT)/src/ports/$$name.Mod" || exit; \
	done
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(SOURCE)/XmppTCP.Mod"

network-test: network
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" VOC="$(VOC)" test-idna
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppNetwork.Mod"
	python3 "$(SOURCE)/tests/loopback.py" "$(BUILD)"

probe: network
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tools/XmppProbe.Mod"

tls-regression: network
	cd "$(BUILD)" && for name in norayr/strutils/strTypes norayr/strutils/strUtils \
		norayr/base64/StringBase64 $(MODULAR_HTTP) norayr/tls/httpsPure $(MODULAR_HTTPS) $(MODULAR_GEMINI); do \
		CFLAGS="$(NETWORK_CFLAGS)" $(VOC) $(OFLAGS) "$(ROOT)/src/ports/$$name.Mod" || exit; \
	done
	cd "$(ROOT)/src/test/ports" && sh ./tls/test.sh "$(VOC)" "$(BUILD)" 2 "-sFm"
	cd "$(ROOT)/src/test/ports" && sh ./gemini/test.sh "$(VOC)" "$(BUILD)" 2 "-sFm"

clean:
	rm -f $(foreach name,$(MODULES) XmppTCP XmppProbe TestXmppStream TestXmppCore TestXmppClient TestXmppIQ TestXmppRosterPubSub TestXmppPresence TestXmppNetwork,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestXmppStream" "$(BUILD)/TestXmppCore" "$(BUILD)/TestXmppClient" "$(BUILD)/TestXmppIQ" "$(BUILD)/TestXmppRosterPubSub" "$(BUILD)/TestXmppPresence" "$(BUILD)/TestXmppNetwork" "$(BUILD)/XmppProbe"
