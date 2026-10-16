MODULES = newt
PROGRAMS = newttest newttest2
EXAMPLE_DEPS = check-newt
EXAMPLE_CFLAGS = -include newt.h
EXAMPLE_LDLIBS = -lnewt
include ../../../tools/make/example.mk

.PHONY: check-newt
check-newt:
	@printf '#include <newt.h>\n' | $(CC) $(CFLAGS) -E -x c - > /dev/null || { echo 'This example requires libnewt development files.'; exit 1; }
