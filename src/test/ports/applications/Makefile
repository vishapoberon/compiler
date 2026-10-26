ROOT := $(abspath ../../../..)
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
BUILD ?= $(ROOT)/build/tests/network-applications
BUILD := $(abspath $(BUILD))
PROFILE ?= conventional
HRESH_BUILD ?= $(ROOT)/build/hresh
HRESH_BUILD := $(abspath $(HRESH_BUILD))

.PHONY: all test applications
all: test
applications:
	@case "$(PROFILE)" in conventional) target=build ;; native) target=native ;; *) echo 'PROFILE must be conventional or native'; exit 1 ;; esac; \
	for application in dcs agena cobweb; do \
	  $(MAKE) -C "$(ROOT)/src/examples/network/$$application" "$$target" \
	    BUILD="$(BUILD)/$$application" HRESH_BUILD="$(HRESH_BUILD)" \
	    VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" || exit; \
	done

test: applications
	@case "$(PROFILE)" in conventional) target=test-names ;; native) target=native-test-names ;; esac; \
	$(MAKE) -C "$(ROOT)/src/examples/network/agena" "$$target" \
	  BUILD="$(BUILD)/agena" HRESH_BUILD="$(HRESH_BUILD)" \
	  VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"
	python3 ./test.py "$(BUILD)" "$(PROFILE)" "$(HRESH_BUILD)"
