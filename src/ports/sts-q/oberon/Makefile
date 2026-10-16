ROOT := $(abspath ../../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
SYMBOLS ?= $(VOCROOT)/$(MODEL)/sym
BUILD ?= $(ROOT)/build/ports/sts-q/oberon/$(MODEL)
BUILD := $(abspath $(BUILD))
include modules.mk
ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(SYMBOLS)" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))"

.PHONY: all check-build build modular test
all: build
check-build:
	@for name in ssqTypes ssqSys Int Random Str Path Ink Char Dot String Clist Line Text Viewer; do \
	 for ext in c h o sym; do if [ -e "$(BUILD)/$$name.$$ext" ] || [ -e "$(BUILD)/libvoc-$$name-O$(MODEL).so" ]; then \
	  echo 'This BUILD contains obsolete full-collection outputs; choose a fresh BUILD directory.'; exit 1; \
	 fi; done; done
build: check-build
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for source in $(SSQ_SOURCES); do $(ENV) "$(VOC)" -O$(MODEL) -Fs "$$source" || exit; done
	cd "$(BUILD)" && test ! -e "libssq-O$(MODEL).a.new" && \
	 $(AR) rcs "libssq-O$(MODEL).a.new" $(addsuffix .o,$(SSQ_MODULES)) && \
	 mv "libssq-O$(MODEL).a.new" "libssq-O$(MODEL).a"
modular: check-build
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && for source in $(SSQ_SOURCES); do $(ENV) "$(VOC)" -O$(MODEL) -sFl "$$source" || exit; done
test:
	$(MAKE) -C "$(ROOT)/src/test/ports/sts-q" test MODEL="$(MODEL)" VOC="$(VOC)" \
	 VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" SYMBOLS="$(SYMBOLS)" BUILD="$(BUILD)"
