VOC ?= voc
.DEFAULT_GOAL := all
OFLAGS ?= -O2 -s -F
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/ports/xmpp/2
BUILD := $(abspath $(BUILD))
MODULES := XmppTypes XmppConst XmppItems XmppBase64 XmppXmlStream XmppXmlGen XmppConnections \
 XmppStrings XmppCore XmppMessenger XmppWire XmppSasl XmppClient \
 XmppIQ XmppIbb XmppByteStreams XmppSocks5 XmppIbbTransfer XmppStreamInit XmppFileReceiver XmppFileSender XmppRegister XmppPresence XmppPresenceTracker XmppMuc XmppMucTracker XmppPing XmppVersion XmppDisco XmppRoster XmppPubSub

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
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppIbb.Mod" && timeout 30 ./TestXmppIbb
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppByteStreams.Mod" && timeout 30 ./TestXmppByteStreams
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppSocks5.Mod" && timeout 30 ./TestXmppSocks5
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppIbbTransfer.Mod" && timeout 30 ./TestXmppIbbTransfer
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppStreamInit.Mod" && timeout 30 ./TestXmppStreamInit
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppFileReceiver.Mod" && timeout 30 ./TestXmppFileReceiver
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppFileSender.Mod" && timeout 30 ./TestXmppFileSender
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppRegister.Mod" && timeout 30 ./TestXmppRegister
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppRosterPubSub.Mod" && timeout 30 ./TestXmppRosterPubSub
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppPresence.Mod" && timeout 30 ./TestXmppPresence
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppMuc.Mod" && timeout 30 ./TestXmppMuc
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppMucTracker.Mod" && timeout 30 ./TestXmppMucTracker

network: all
	@test "$$(uname -s)" = Linux || { echo "The XMPP TCP/TLS driver currently requires Linux."; exit 1; }
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" VOC="$(VOC)" idna
	cd "$(BUILD)" && for name in $(NETWORK_MODULES); do \
		CFLAGS="$(NETWORK_CFLAGS)" $(VOC) $(OFLAGS) "$(ROOT)/src/ports/$$name.Mod" || exit; \
	done
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(SOURCE)/XmppTCP.Mod"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(SOURCE)/XmppSocks5TCP.Mod"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(SOURCE)/XmppAsyncTCP.Mod"

network-test: network
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppSocks5TCP.Mod" && timeout 30 ./TestXmppSocks5TCP
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppAsync.Mod"
	python3 "$(SOURCE)/tests/async-loopback.py" "$(BUILD)"
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" VOC="$(VOC)" test-idna
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppNetwork.Mod"
	python3 "$(SOURCE)/tests/loopback.py" "$(BUILD)"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tests/TestXmppRegisterNetwork.Mod"
	python3 "$(SOURCE)/tests/registration-loopback.py" "$(BUILD)"

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
	rm -f $(foreach name,XmppAsyncTCP TestXmppAsync,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestXmppAsync"
	rm -f $(foreach name,XmppSocks5TCP TestXmppByteStreams TestXmppSocks5 TestXmppSocks5TCP,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestXmppByteStreams" "$(BUILD)/TestXmppSocks5" "$(BUILD)/TestXmppSocks5TCP"
	rm -f $(foreach name,TestXmppIbb TestXmppIbbTransfer TestXmppStreamInit TestXmppFileReceiver TestXmppFileSender,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestXmppIbb" "$(BUILD)/TestXmppIbbTransfer" "$(BUILD)/TestXmppStreamInit" "$(BUILD)/TestXmppFileReceiver" "$(BUILD)/TestXmppFileSender"
	rm -f $(foreach name,$(MODULES) XmppTCP XmppProbe TestXmppStream TestXmppCore TestXmppClient TestXmppIQ TestXmppRegister TestXmppRosterPubSub TestXmppPresence TestXmppMuc TestXmppMucTracker TestXmppNetwork TestXmppRegisterNetwork,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestXmppStream" "$(BUILD)/TestXmppCore" "$(BUILD)/TestXmppClient" "$(BUILD)/TestXmppIQ" "$(BUILD)/TestXmppRegister" "$(BUILD)/TestXmppRosterPubSub" "$(BUILD)/TestXmppPresence" "$(BUILD)/TestXmppMuc" "$(BUILD)/TestXmppMucTracker" "$(BUILD)/TestXmppNetwork" "$(BUILD)/TestXmppRegisterNetwork" "$(BUILD)/XmppProbe"
