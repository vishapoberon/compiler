VOC ?= voc
MODEL ?= 2
SOURCE := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SOURCE)/../../..)
BUILD ?= $(ROOT)/build/ports/ooc/$(MODEL)
BUILD := $(abspath $(BUILD))
C_MODEL ?= $(shell $(CC) -dM -E - < /dev/null | awk '$$2=="__SIZEOF_POINTER__" {p=$$3} $$2=="__SIZEOF_LONG__" {l=$$3} END {if(p==4) print "ILP32"; else if(l==8) print "LP64"; else print "LLP64"}')

include $(ROOT)/src/tools/make/modular-libraries.mk

MODULES := $(MODULAR_OOC) C$(C_MODEL)
TESTS := TestLongStrings TestMessages TestOocChannels TestOocURI TestOocUnified TestIntStr TestAsciiCodes
PKG_CONFIG ?= pkg-config
IDNA_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags libidn2)
IDNA_LIBS ?= $(shell $(PKG_CONFIG) --libs libidn2)

.PHONY: all test idna test-idna clean
# Local symbol files make the linker select these objects over installed copies.
all:
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for name in $(MODULES); do \
		$(VOC) -O$(MODEL) -s -F "$(SOURCE)/$$name.Mod" || exit; \
	done

test: all
	cd "$(BUILD)" && for name in $(TESTS); do \
		$(VOC) -O$(MODEL) -s -m "$(ROOT)/src/test/confidence/library/$$name.mod" && \
		"./$$name" || exit; \
		done
	cd "$(BUILD)" && $(VOC) -O$(MODEL) -s -F -m "$(ROOT)/src/test/confidence/library/TestOocURIFixtures.mod"
	python3 "$(SOURCE)/tests/check-uri.py" "$(BUILD)/TestOocURIFixtures" --work "$(BUILD)/uri-fixtures"

idna:
	@$(PKG_CONFIG) --exists libidn2 || { echo "IDNA requires libidn2 development files and pkg-config."; exit 1; }
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && CFLAGS="$(CFLAGS) $(IDNA_CFLAGS)" LDLIBS="$(LDLIBS) $(IDNA_LIBS)" $(VOC) -O$(MODEL) -s -F "$(SOURCE)/IDNA.Mod"

test-idna: idna
	cd "$(BUILD)" && LDLIBS="$(LDLIBS) $(IDNA_LIBS)" $(VOC) -O$(MODEL) -s -F -m "$(ROOT)/src/test/confidence/library/TestIDNA.mod" && ./TestIDNA

clean:
	rm -f "$(BUILD)/TestIDNA" $(foreach name,IDNA TestIDNA,$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)"))
	rm -f "$(BUILD)/TestOocURIFixtures" $(foreach ext,c h o sym,"$(BUILD)/TestOocURIFixtures.$(ext)")
	rm -f $(foreach name,$(MODULES) $(TESTS),$(foreach ext,c h o sym,"$(BUILD)/$(name).$(ext)")) \
		$(foreach name,$(TESTS),"$(BUILD)/$(name)")
