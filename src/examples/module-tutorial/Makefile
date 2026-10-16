# Examples from doc/ModuleTutorial.md, using this checkout's modular profile.
EXAMPLE_CUSTOM = 1
include ../../tools/make/example.mk

.PHONY: all commands standalone embedded shell test
all: commands standalone

commands: native-libraries | $(BUILD)
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -sl "$(SOURCE)/Commands.Mod"

standalone: native-libraries | $(BUILD)
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -smd "$(SOURCE)/Main.Mod"

embedded: native-libraries | $(BUILD)
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -smD "$(SOURCE)/Main.Mod"

shell: commands
	cd "$(BUILD)" && $(NATIVE_ENV) "$(HRESH)" "-P$(BUILD):$(NATIVE_MODULES)"

test: all
	cd "$(BUILD)" && printf 'Commands\nCommands.Run\nCommands.Run\nquit\n' | $(NATIVE_ENV) "$(HRESH)" "-P$(BUILD):$(NATIVE_MODULES)" > Commands.out
	grep -Fx '  Commands.Run' "$(BUILD)/Commands.out"
	grep -Fx 'LOADED calls: 1' "$(BUILD)/Commands.out"
	grep -Fx 'LOADED calls: 2' "$(BUILD)/Commands.out"
	cd "$(BUILD)" && ./Main > Main.out
	grep -Fx 'NATIVE MODULES' "$(BUILD)/Main.out"
	$(MAKE) embedded VOC="$(VOC)" BUILD="$(BUILD)"
	cd "$(BUILD)" && ./Main > Main.out
	grep -Fx 'NATIVE MODULES' "$(BUILD)/Main.out"
