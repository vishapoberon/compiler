# Examples from doc/ModuleTutorial.md, using an installed modular VOC.
VOC ?= voc
VISH ?= vish
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
SOURCE := $(ROOT)/src/test/module-tutorial
BUILD ?= $(ROOT)/build/tests/module-tutorial
BUILD := $(abspath $(BUILD))

.PHONY: all commands standalone embedded shell test
all: commands standalone

$(BUILD):
	mkdir -p "$@"

commands: | $(BUILD)
	cd "$(BUILD)" && "$(VOC)" -sl "$(SOURCE)/Commands.Mod"

standalone: | $(BUILD)
	cd "$(BUILD)" && "$(VOC)" -smd "$(SOURCE)/Main.Mod"

embedded: | $(BUILD)
	cd "$(BUILD)" && "$(VOC)" -smD "$(SOURCE)/Main.Mod"

shell: commands
	cd "$(BUILD)" && "$(VISH)"

test: all
	cd "$(BUILD)" && printf 'Commands\nCommands.Run\nCommands.Run\nquit\n' | "$(VISH)" > Commands.out
	grep -Fx '  Commands.Run' "$(BUILD)/Commands.out"
	grep -Fx 'LOADED calls: 1' "$(BUILD)/Commands.out"
	grep -Fx 'LOADED calls: 2' "$(BUILD)/Commands.out"
	cd "$(BUILD)" && ./Main > Main.out
	grep -Fx 'NATIVE MODULES' "$(BUILD)/Main.out"
	$(MAKE) embedded VOC="$(VOC)" BUILD="$(BUILD)"
	cd "$(BUILD)" && ./Main > Main.out
	grep -Fx 'NATIVE MODULES' "$(BUILD)/Main.out"
