PROGRAMS = Main
LIBRARY_SOURCES = $(ROOT)/src/ports/une/oberon-cairo/Cairo.Mod
PKG_CONFIG ?= pkg-config
EXAMPLE_CFLAGS = $(shell $(PKG_CONFIG) --cflags cairo)
EXAMPLE_LDLIBS = $(shell $(PKG_CONFIG) --libs cairo)
EXAMPLE_DEPS = check-cairo
include ../../../tools/make/example.mk

.PHONY: check-cairo
check-cairo:
	@$(PKG_CONFIG) --exists cairo || { echo 'Install Cairo development files and pkg-config (Debian: libcairo2-dev pkg-config).'; exit 1; }
