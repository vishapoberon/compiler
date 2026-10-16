PROGRAMS = Snake
RAYLIB_PORT = $(ROOT)/src/ports/tmartiro/raylib
LIBRARY_SOURCES = $(RAYLIB_PORT)/RaylibNative.Mod $(RAYLIB_PORT)/Raylib.Mod
PKG_CONFIG ?= pkg-config
EXAMPLE_CFLAGS = $(shell $(PKG_CONFIG) --cflags raylib)
EXAMPLE_LDLIBS = $(shell $(PKG_CONFIG) --libs raylib)
EXAMPLE_DEPS = check-raylib
include ../../../tools/make/example.mk

.PHONY: check-raylib
check-raylib:
	@$(PKG_CONFIG) --exists raylib || { echo 'Install raylib development files and pkg-config (Debian: libraylib-dev pkg-config).'; exit 1; }

# Do not launch a window during builds or test runs. The ARM copy's software
# rendering setting remains an explicit choice, e.g. make run LIBGL_ALWAYS_SOFTWARE=1.
