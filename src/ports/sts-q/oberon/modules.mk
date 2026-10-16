# Kbd-only inputs for independent builds and private examples.
# Default Unix model-2 library selection is in modular-libraries.mk.
SSQ_MODULES = Kbd
SSQ_SOURCES = $(addprefix $(ROOT)/src/ports/sts-q/oberon/,$(addsuffix .Mod,$(SSQ_MODULES)))
