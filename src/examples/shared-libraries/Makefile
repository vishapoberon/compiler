EXAMPLE_CUSTOM = 1
include ../../tools/make/example.mk
HOST_MODE ?= md

.PHONY: all libraries for-hresh application standalone hresh-host run-hresh run-standalone shell test
all: for-hresh standalone
libraries: native-libraries
	mkdir -p "$(BUILD)"
for-hresh: libraries
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(SOURCE)/LibraryDemo.Mod"
standalone: libraries
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -s$(HOST_MODE) "$(SOURCE)/LibraryMain.Mod"
application: libraries
	cd "$(BUILD)" && $(NATIVE_ENV) "$(NATIVE_VOC)" -O$(MODEL) -sFl "$(SOURCE)/LibraryMain.Mod"
hresh-host: libraries
run-hresh: for-hresh hresh-host
	cd "$(BUILD)" && $(NATIVE_ENV) "$(HRESH)" "-P$(BUILD):$(NATIVE_MODULES)" LibraryDemo.Run
run-standalone: standalone
	"$(BUILD)/LibraryMain"
shell: for-hresh hresh-host
	cd "$(BUILD)" && $(NATIVE_ENV) "$(HRESH)" "-P$(BUILD):$(NATIVE_MODULES)"
test: run-hresh run-standalone
