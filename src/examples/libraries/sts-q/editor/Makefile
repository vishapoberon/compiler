# Building Viewer as an example component, not an installed library or program.
include ../../../../tools/make/example.mk
include $(ROOT)/src/ports/sts-q/oberon/modules.mk
include modules.mk
LIBRARY_SOURCES = $(SSQ_SOURCES)
MODULES = $(SSQ_EDITOR_MODULES)

.PHONY: test
test: build
	cd "$(BUILD)" && for name in TestSsqExamples TestSsqTerminal TestSsqInput; do \
	 $(EXAMPLE_ENV) "$(VOC)" -O$(MODEL) -sm "$(ROOT)/src/test/examples/sts-q/$$name.Mod" || exit; done
	cd "$(BUILD)" && ./TestSsqExamples
	python3 "$(ROOT)/src/test/examples/sts-q/test-editor.py" "$(BUILD)"
