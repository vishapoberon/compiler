# Regressions use only a matching checkout image, or the optional modular image.
ROOT := $(abspath ../../..)
MODEL ?= 2
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
SYMBOLS ?= $(VOCROOT)/$(MODEL)/sym
BUILD ?= $(ROOT)/build/tests/ports/$(MODEL)
BUILD := $(abspath $(BUILD))
FLAGS ?= -sm
NETWORK ?= auto
TEST_ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 OBERON="$(BUILD);$(SYMBOLS)" \
 LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(abspath $(VOCLIBDIR))"

.PHONY: all test
all: test
test:
	mkdir -p "$(BUILD)"
	$(TEST_ENV) sh ./test.sh "$(abspath $(VOC))" "$(BUILD)" "$(MODEL)" "$(FLAGS)"
	@if [ "$(NETWORK)" = 1 ] || { [ "$(NETWORK)" = auto ] && [ -f "$(SYMBOLS)/Internet.sym" ]; }; then \
	  $(TEST_ENV) sh ./Internet/test.sh "$(abspath $(VOC))" "$(BUILD)/Internet" "$(MODEL)" "$(FLAGS)" && \
	  $(TEST_ENV) sh ./tls/test.sh "$(abspath $(VOC))" "$(BUILD)/tls" "$(MODEL)" "$(FLAGS)" && \
	  $(TEST_ENV) sh ./gemini/test.sh "$(abspath $(VOC))" "$(BUILD)/gemini" "$(MODEL)" "$(FLAGS)"; \
	fi
