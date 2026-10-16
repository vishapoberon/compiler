ROOT := $(abspath ../../../..)
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD ?= $(ROOT)/build/tests/ports/une/$(MODEL)
BUILD := $(abspath $(BUILD))
STAR_PORT := $(ROOT)/src/ports/une/oberon-stars
IP_PORT := $(ROOT)/src/ports/une/oberon-ip
STAR_SOURCES := Angle MathE Epoch Coordinate Precession Nutation
ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(VOCROOT)/$(MODEL)/sym" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))"

.PHONY: all test
all: test
test:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(VOC)" -O$(MODEL) -Fs "$(IP_PORT)/IP.Mod"
	cd "$(BUILD)" && for name in $(STAR_SOURCES); do $(ENV) "$(VOC)" -O$(MODEL) -Fs "$(STAR_PORT)/$$name.Mod" || exit; done
	cd "$(BUILD)" && $(ENV) "$(VOC)" -O$(MODEL) -sm "$(ROOT)/src/test/ports/une/TestIP.Mod"
	cd "$(BUILD)" && ./TestIP
	cd "$(BUILD)" && $(ENV) "$(VOC)" -O$(MODEL) -sm "$(ROOT)/src/examples/network/ip/IPRange.Mod"
	python3 ./test-iprange.py "$(BUILD)/IPRange"
	cd "$(BUILD)" && $(ENV) "$(VOC)" -O$(MODEL) -sm "$(ROOT)/src/test/ports/une/TestStars.Mod"
	cd "$(BUILD)" && TZ=UTC0 ./TestStars
