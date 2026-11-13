ROOT := $(abspath ../../../..)
MODEL ?= 2
BUILD ?= $(ROOT)/build/examples/hald/$(MODEL)
HALD_PACKAGE := $(ROOT)/src/ports/norayr/hald-clut
HALD_SOURCE := $(HALD_PACKAGE)/HaldClut.Mod
COMMAND_SOURCE := $(CURDIR)/HaldCmd.Mod
BENCH_SOURCE := $(CURDIR)/HaldBench.Mod
TEST_SOURCE := $(CURDIR)/test.py
BACKEND_TEST_SOURCE := $(CURDIR)/test-backend.py

include $(HALD_PACKAGE)/build.mk
