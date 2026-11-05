ROOT := $(abspath ../../..)
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
ONAME ?= voc
VOC ?= $(VOCROOT)/bin/$(ONAME)
MODEL ?= 2
BUILD ?= $(ROOT)/build/reals-tests/$(MODEL)
BUILD := $(abspath $(BUILD))
ENV = VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" \
 LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" \
 DYLD_LIBRARY_PATH="$(VOCLIBDIR)$${DYLD_LIBRARY_PATH:+:$$DYLD_LIBRARY_PATH}"

.PHONY: test
test:
	python3 "$(ROOT)/src/test/reals/check-implementation.py"
	mkdir -p "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(VOC)" -Fsfm -O$(MODEL) "$(ROOT)/src/test/reals/TestReals.Mod"
	$(ENV) "$(BUILD)/TestReals"
	cd "$(BUILD)" && $(ENV) "$(VOC)" -Fsfm -O$(MODEL) "$(ROOT)/src/test/reals/TestRealLiterals.Mod"
	$(ENV) "$(BUILD)/TestRealLiterals"
	$(ENV) python3 "$(ROOT)/src/test/reals/check-literals.py" --voc "$(VOC)" --work "$(BUILD)/literals" --model $(MODEL)
	$(CC) $(CFLAGS) -I"$(VOCROOT)/$(MODEL)/include" "$(ROOT)/src/test/reals/NativeOracle.c" \
	  -L"$(VOCLIBDIR)" -l$(ONAME)-O$(MODEL) $(LDFLAGS) -lm -o "$(BUILD)/NativeOracle"
	$(ENV) "$(BUILD)/NativeOracle"
