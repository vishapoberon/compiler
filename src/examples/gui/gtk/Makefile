MODULES = G Pango Gdk Gtk Glade handlers
PROGRAMS = HelloWorld
EXAMPLE_DEPS = check-gtk
EXAMPLE_CFLAGS = $(shell pkg-config --cflags libglade-2.0)
EXAMPLE_LDLIBS = $(shell pkg-config --libs libglade-2.0)
EXAMPLE_LDFLAGS = -Wl,--export-dynamic
include ../../../tools/make/example.mk

.PHONY: check-gtk
check-gtk:
	@pkg-config --exists libglade-2.0 || { echo 'This legacy example requires GTK 2 and libglade-2.0 development files.'; exit 1; }
