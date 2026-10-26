VOC ?= voc
MODEL ?= 2
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/ports/punycode/$(MODEL)
BUILD := $(abspath $(BUILD))
MODULES := Punycode IDNAMapping IDNAData UnicodeNFC IDNA

.PHONY: all test conformance clean
all:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for name in $(MODULES); do \
		$(VOC) -O$(MODEL) -s -F "$(SOURCE)/$$name.Mod" || exit; \
	done
test: all
	cd "$(BUILD)" && $(VOC) -O$(MODEL) -s -F -m "$(SOURCE)/tests/TestPunycode.Mod" && ./TestPunycode
	cd "$(BUILD)" && $(VOC) -O$(MODEL) -s -F -m "$(ROOT)/src/test/confidence/library/TestIDNA.mod" && ./TestIDNA
conformance: all
	cd "$(BUILD)" && $(VOC) -O$(MODEL) -s -F -m "$(SOURCE)/tests/DomainVectors.Mod"
	python3 "$(SOURCE)/tests/check-vectors.py" "$(BUILD)/DomainVectors" --work "$(BUILD)/vectors"
clean:
	rm -f $(foreach name,$(MODULES) TestPunycode TestIDNA DomainVectors,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) "$(BUILD)/TestPunycode" "$(BUILD)/TestIDNA" "$(BUILD)/DomainVectors"
