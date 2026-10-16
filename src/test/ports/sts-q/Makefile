ROOT := $(abspath ../../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
SYMBOLS ?= $(VOCROOT)/$(MODEL)/sym
LIBRARY_TARGET ?= build
FLAGS ?= -sm
BUILD ?= $(ROOT)/build/tests/ports/sts-q/$(MODEL)
BUILD := $(abspath $(BUILD))
ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(SYMBOLS)" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))"

.PHONY: all test test-bundled
all: test
test:
	$(MAKE) -C "$(ROOT)/src/ports/sts-q/oberon" $(LIBRARY_TARGET) MODEL="$(MODEL)" VOC="$(VOC)" \
	 VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" SYMBOLS="$(SYMBOLS)" BUILD="$(BUILD)"
	cd "$(BUILD)" && for name in TestKbdLibrary TestKbd; do \
	 $(ENV) "$(VOC)" -O$(MODEL) $(FLAGS) "$(CURDIR)/$$name.Mod" || exit; done
	cd "$(BUILD)" && ./TestKbdLibrary
	python3 ./test-kbd.py "$(BUILD)" "$(MODEL)"

# Linking only against the ordinary library image: never compile a local Kbd.
test-bundled:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for name in TestKbdLibrary TestKbd; do \
	 $(ENV) "$(VOC)" -O$(MODEL) $(FLAGS) "$(CURDIR)/$$name.Mod" || exit; done
	cd "$(BUILD)" && ./TestKbdLibrary
	python3 ./test-kbd.py "$(BUILD)" "$(MODEL)" bundled
