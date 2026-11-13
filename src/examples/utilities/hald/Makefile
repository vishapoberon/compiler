ROOT := $(abspath ../../../..)
MODEL ?= 2
BUILD ?= $(ROOT)/build/examples/hald/$(MODEL)
HALD_PACKAGE := $(ROOT)/src/ports/norayr/hald-clut
HALD_SOURCE := $(HALD_PACKAGE)/HaldClut.Mod
COMMAND_SOURCE := $(CURDIR)/HaldCmd.Mod
BENCH_SOURCE := $(CURDIR)/HaldBench.Mod
PREP_SOURCE := $(CURDIR)/HaldPrepare.Mod
TEST_SOURCE := $(CURDIR)/test.py
BACKEND_TEST_SOURCE := $(CURDIR)/test-backend.py
PREP_TEST_SOURCE := $(CURDIR)/test-prepare.py

include $(HALD_PACKAGE)/build.mk

.PHONY: prepare test-prepare
prepare: sequential

test: test-prepare

test-prepare: prepare
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" $(RUN_PYTHON) "$(PREP_TEST_SOURCE)" --build "$(BUILD)"
