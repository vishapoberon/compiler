# Bindings are compiled into the example build directory, never beside sources.
include $(dir $(lastword $(MAKEFILE_LIST)))example.mk
LIBRARY_SOURCES += $(addprefix $(ROOT)/src/ports/oocX11/,oocX11.Mod oocXutil.Mod oocXYplane.Mod)
EXAMPLE_LDLIBS += -lX11
