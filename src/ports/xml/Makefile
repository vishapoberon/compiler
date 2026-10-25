VOC ?= voc
MODEL ?= 2
OFLAGS ?= -O2 -s -F
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/ports/xml/2
BUILD := $(abspath $(BUILD))

ifneq ($(MODEL),2)
$(error The XML port targets MODEL=2)
endif

include $(ROOT)/src/tools/make/modular-libraries.mk

TESTS := TestUnicodeCodecs TestUnicodeMessages TestMemoryBuffers TestDTDResolver \
 TestParser TestNamespaces TestValidation TestWriter TestBasic TestProtocol TestEntityPolicy TestLimits

.PHONY: all test xmlcheck conformance limits fuzz clean
all:
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" MODEL=2 VOC="$(VOC)" all
	cd "$(BUILD)" && for name in $(MODULAR_XML); do \
		$(VOC) $(OFLAGS) "$(SOURCE)/$$name.Mod" || exit; \
	done

test: all
	$(MAKE) -C "$(SOURCE)/../ooc" BUILD="$(BUILD)" MODEL=2 VOC="$(VOC)" test
	python3 "$(SOURCE)/tests/voc/check-codecs.py" --build "$(BUILD)" --voc "$(VOC)" --flags "$(OFLAGS)"
	cd "$(BUILD)" && for name in $(TESTS); do \
		$(VOC) $(OFLAGS) -m "$(SOURCE)/tests/voc/$$name.Mod" && timeout 20 "./$$name" || exit; \
	done

xmlcheck: all
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(SOURCE)/tools/XMLCheck.Mod"

conformance: xmlcheck
	@for suite in xmltest validation canonical protocol misc; do \
		python3 "$(SOURCE)/tests/voc/check-$$suite.py" "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance" || exit; \
	done

limits: xmlcheck
	python3 "$(SOURCE)/tests/voc/check-limits.py" "$(BUILD)/XMLCheck" --work "$(BUILD)/limits"

fuzz: xmlcheck
	python3 "$(SOURCE)/tests/voc/check-fuzz.py" "$(BUILD)/XMLCheck" --work "$(BUILD)/fuzz"

clean:
	rm -f $(foreach name,$(MODULAR_XML) $(TESTS) TestCodecVectors XMLCheck,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) \
		$(foreach name,$(TESTS) TestCodecVectors XMLCheck,"$(BUILD)/$(name)")
