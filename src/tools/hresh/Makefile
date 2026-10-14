# Optional ELF modular runtime and shell. Bootstrap against an installed VOC.
VOC ?= voc
CC ?= cc
VOCROOT ?= /usr/share/voc
VOCLIBDIR ?= $(dir $(shell $(CC) -print-file-name=libvoc-O2.so))
MODEL ?= 2
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
BUILD ?= $(ROOT)/build/hresh
BUILD := $(abspath $(BUILD))
TOOLS := $(ROOT)/src/tools/hresh
SUPPORT := $(ROOT)/src/library/v4
COMPILER := $(BUILD)/compiler
MODULES := $(BUILD)/modules/$(MODEL)
NEWVOC := $(COMPILER)/voc
ENV := VOCROOT="$(VOCROOT)" VOCLIBDIR="$(MODULES)" OBERON="$(MODULES)"
# Bundled libraries find their siblings after staging/installing as well as in
# the build tree. Hosts/applications retain the compiler's normal search path.
LIBRARY_ENV := $(ENV) VOC_RUNPATH='$(if $(VOC_RUNPATH),$(VOC_RUNPATH),$$ORIGIN)'
SOURCES := Configuration OPM OPS OPT OPC OPV OPB OPP extTools Compiler
INCLUDEFLAG := $(if $(findstring tcc,$(notdir $(firstword $(CC)))),-I,-iquote)
INCLUDES := $(INCLUDEFLAG)$(MODULES) $(INCLUDEFLAG)$(ROOT)/src/runtime $(INCLUDEFLAG)$(VOCROOT)/$(MODEL)/include
# Core C files find generated headers beside their source. Do not add that
# directory a second time with -I: TCC's include_next must reach libc headers.
CORE_INCLUDES := $(INCLUDEFLAG)$(ROOT)/src/runtime
NATIVEFLAGS := -fPIC -g -fno-strict-aliasing
# The compiler's temporary syntax trees rely on conservative stack GC roots.
# Match the conventional compiler build; CFLAGS still optimize the libraries.
COMPILER_CFLAGS ?= -O0
DL_LIBS ?= $(if $(filter Linux,$(shell uname -s)),-ldl,)
RESOURCE_ROOT ?= $(INSTALL_ROOT)
WITH_X11 ?= 1
C_MODEL ?= $(shell $(CC) -dM -E - < /dev/null | awk '$$2=="__SIZEOF_POINTER__" {p=$$3} $$2=="__SIZEOF_LONG__" {l=$$3} END {if(p==4) print "ILP32"; else if(l==8) print "LP64"; else print "LLP64"}')
include $(ROOT)/src/tools/make/modular-libraries.mk

.PHONY: all compiler modules tools libraries test test-tools test-commands test-unload test-hosted-unload test-library demo install-modular FORCE
all: $(BUILD)/hresh
ifeq ($(MODEL),2)
all: tools
tools: $(MODULES)/tools.stamp
else
tools:
	@echo "The hosted compiler and browser require MODEL=2."
	@exit 1
endif
compiler: $(NEWVOC)
modules: $(MODULES)/modules.stamp
ifeq ($(MODEL),2)
libraries: $(MODULES)/libraries.stamp
else
libraries:
	@echo "The full bundled-library profile requires MODEL=2; use modules for MODEL=$(MODEL)."
	@exit 1
endif

$(BUILD) $(COMPILER) $(MODULES):
	mkdir -p "$@"

# Record inputs that make cannot otherwise see changing between invocations.
# GNU make writes the values without interpreting compiler flags as shell code.
define BUILD_CONFIGURATION
VOC=$(VOC)
VOCROOT=$(VOCROOT)
VOCLIBDIR=$(VOCLIBDIR)
CC=$(CC)
CFLAGS=$(CFLAGS)
COMPILER_CFLAGS=$(COMPILER_CFLAGS)
LDFLAGS=$(LDFLAGS)
LDLIBS=$(LDLIBS)
DL_LIBS=$(DL_LIBS)
RESOURCE_ROOT=$(RESOURCE_ROOT)
INSTALL_LIBDIR=$(INSTALL_LIBDIR)
VOC_RUNPATH=$(VOC_RUNPATH)
endef

$(COMPILER)/build.config: FORCE | $(COMPILER)
	$(file >$@.new,$(BUILD_CONFIGURATION))
	@if cmp -s "$@.new" "$@"; then rm "$@.new"; else mv "$@.new" "$@"; fi

# Generate configuration in our own directory, never overwrite the user's
# root Configuration.Mod/Make or replace the installed compiler/runtime.
$(COMPILER)/Configuration.Mod: $(ROOT)/src/tools/make/configure.c $(COMPILER)/build.config $(TOOLS)/Makefile | $(COMPILER)
	$(CC) -I$(ROOT)/src/runtime "$<" -o "$(COMPILER)/configure"
	cd "$(COMPILER)" && CC="$(CC)" INSTALLDIR="$(RESOURCE_ROOT)" LIBDIR="$(INSTALL_LIBDIR)" ./configure

$(NEWVOC): $(wildcard $(ROOT)/src/compiler/*.Mod) $(COMPILER)/Configuration.Mod $(TOOLS)/Makefile $(ROOT)/src/runtime/SYSTEM.h
	cp "$(ROOT)/src/runtime/SYSTEM.h" "$(COMPILER)/SYSTEM.h"
	cd "$(COMPILER)" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" $(VOC) -sFS Configuration.Mod
	cd "$(COMPILER)" && for name in OPM OPS OPT OPC OPV OPB OPP extTools; do VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" $(VOC) -sFS "$(ROOT)/src/compiler/$$name.Mod" || exit; done
	cd "$(COMPILER)" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" $(VOC) -sSm "$(ROOT)/src/compiler/Compiler.Mod"
	$(CC) $(CFLAGS) $(COMPILER_CFLAGS) $(NATIVEFLAGS) -DVOC_MAIN_PROGRAM=1 $(INCLUDEFLAG)$(COMPILER) $(INCLUDEFLAG)$(VOCROOT)/2/include $(addprefix $(COMPILER)/,$(addsuffix .c,$(SOURCES))) $(LDFLAGS) -L$(VOCLIBDIR) -Wl,--enable-new-dtags -Wl,-rpath,$(abspath $(VOCLIBDIR)) -o "$@" -lvoc-O2

$(COMPILER)/CoreSource: $(ROOT)/src/tools/make/CoreSource.Mod $(NEWVOC)
	cd "$(COMPILER)" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" OBERON="$(VOCROOT)/2/sym" $(VOC) -sm "$<"

$(MODULES)/libvoc-core-O$(MODEL).so: $(NEWVOC) $(COMPILER)/CoreSource $(ROOT)/src/runtime/Platformunix.Mod $(ROOT)/src/runtime/Heap.Mod $(ROOT)/src/runtime/Modules.Mod $(ROOT)/src/runtime/SYSTEM.c $(ROOT)/src/runtime/SYSTEM.h $(ROOT)/src/runtime/CommandContext.h $(ROOT)/src/runtime/PlatformDirectory.h $(ROOT)/src/runtime/PlatformTermios.h | $(MODULES)
	cp "$(ROOT)/src/runtime/SYSTEM.h" "$(ROOT)/src/runtime/PlatformDirectory.h" "$(ROOT)/src/runtime/PlatformTermios.h" "$(ROOT)/src/runtime/WindowsWrapper.h" "$(MODULES)/"
	"$(COMPILER)/CoreSource" "$(ROOT)/src/runtime/Heap.Mod" "$(MODULES)/Heap.Mod"
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(ROOT)/src/runtime/Platformunix.Mod"
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFSapx Heap.Mod
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(ROOT)/src/runtime/Modules.Mod"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -DVOC_CORE_RUNTIME -c "$(ROOT)/src/runtime/SYSTEM.c" -o "$(MODULES)/SYSTEM.o"
	cd "$(MODULES)" && $(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -c Platform.c Heap.c Modules.c
	ar rcs "$(MODULES)/libvoc-core-O$(MODEL).a" $(addprefix $(MODULES)/,SYSTEM.o Platform.o Heap.o Modules.o)
	$(CC) -shared $(LDFLAGS) $(if $(findstring tcc,$(CC)),,-Wl,-z,defs) -Wl,-soname,libvoc-core-O$(MODEL).so -o "$@" $(addprefix $(MODULES)/,SYSTEM.o Platform.o Heap.o Modules.o)

# The dependency order is the Oberon import order. The compiler discovers the
# actual DT_NEEDED edges itself; no list of commands/imports is generated here.
$(MODULES)/modules.stamp: $(MODULES)/libvoc-core-O$(MODEL).so $(wildcard $(ROOT)/src/runtime/*.Mod) $(SUPPORT)/ModuleLoader.Mod $(SUPPORT)/CommandSymbols.Mod $(SUPPORT)/SharedModules.Mod $(SUPPORT)/termios.Mod $(SUPPORT)/UnixTermios.Mod $(SUPPORT)/LineEditor.Mod $(SUPPORT)/SharedModulesSupport.c $(SUPPORT)/SharedModulesSupport.h $(ROOT)/src/library/ooc/oocStrings.Mod
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(INCLUDES) -I$(SUPPORT) -DVOC_RESOURCE_ROOT='"$(RESOURCE_ROOT)"' -c "$(SUPPORT)/SharedModulesSupport.c" -o "$(MODULES)/SharedModulesSupport.o"
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) -I$(SUPPORT)" LDLIBS="SharedModulesSupport.o $(DL_LIBS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/ModuleLoader.Mod"
	cd "$(MODULES)" && for name in Out Reals Strings In Files Math MathL Texts Oberon VT100; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/runtime/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/ooc/oocStrings.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/CommandSymbols.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/termios.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/UnixTermios.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/LineEditor.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) -I$(SUPPORT)" "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/SharedModules.Mod"
	touch "$@"

# In-process tools share the shell's core and library instances. Loading the
# compiler or browser never invokes their conventional command-line startup.
$(MODULES)/tools.stamp: $(MODULES)/modules.stamp $(wildcard $(ROOT)/src/compiler/*.Mod) $(ROOT)/src/tools/browser/BrowserCmd.Mod $(TOOLS)/compiler.Mod $(TOOLS)/browser.Mod $(TOOLS)/xxs.Mod $(TOOLS)/system.Mod
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(COMPILER)/Configuration.Mod"
	cd "$(MODULES)" && for name in OPM OPS OPT OPC OPV OPB OPP extTools Compiler; do $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/compiler/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/tools/browser/BrowserCmd.Mod"
	cd "$(MODULES)" && for name in compiler browser xxs system; do $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/$$name.Mod" || exit; done
	touch "$@"

FORCE:

# Changing the optional X11 selection must also refresh the installed file list.
$(MODULES)/libraries.config: FORCE | $(MODULES)
	@printf '%s\n' 'WITH_X11=$(WITH_X11)' > "$@.new"
	@if cmp -s "$@.new" "$@"; then rm "$@.new"; else mv "$@.new" "$@"; fi

$(MODULES)/libraries.stamp: $(MODULES)/modules.stamp $(MODULES)/tools.stamp $(MODULES)/libraries.config $(ROOT)/src/tools/make/modular-libraries.mk $(wildcard $(ROOT)/src/library/*/*.Mod)
	cd "$(MODULES)" && for name in $(MODULAR_V4); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/v4/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_OOC); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/ooc/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/ooc/oocC$(C_MODEL).Mod"
	cd "$(MODULES)" && for name in $(MODULAR_OOC2); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/ooc2/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_ULM); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/ulm/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_POW); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/pow/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_MISC); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/misc/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_S3); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/s3/$$name.Mod" || exit; done
	if [ "$(WITH_X11)" = 1 ]; then cd "$(MODULES)" && for name in $(MODULAR_X11); do $(LIBRARY_ENV) LDLIBS="-lX11" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/oocX11/$$name.Mod" || exit; done; fi
	printf '%s\n' Out Reals Strings In Files Math MathL Texts Oberon VT100 ModuleLoader CommandSymbols termios UnixTermios LineEditor SharedModules $(SOURCES) BrowserCmd compiler browser xxs system $(MODULAR_V4) $(MODULAR_OOC) oocC $(MODULAR_OOC2) $(MODULAR_ULM) $(MODULAR_POW) $(MODULAR_MISC) $(MODULAR_S3) $(if $(filter 1,$(WITH_X11)),$(MODULAR_X11)) | awk '!seen[$$0]++' > "$(MODULES)/libraries.list"
	touch "$@"

$(BUILD)/hresh: $(TOOLS)/hresh.Mod $(MODULES)/modules.stamp
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/hresh.Mod"

test: all test-commands test-unload
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/SharedProvider.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/SharedConsumer.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/TypeOnly.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/HelloShared.Mod"
	"$(BUILD)/HelloShared"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TOOLS)/tests/HelloShared.Mod"
	"$(BUILD)/HelloShared"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestShared.Mod"
	"$(BUILD)/TestShared" "$(BUILD)"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(INCLUDES) -DVOC_TEST_MODEL_$(MODEL) -shared "$(TOOLS)/tests/BadCoreABI.c" -o "$(BUILD)/libvoc-BadCoreABI-O$(MODEL).so"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestLoaderABI.Mod"
	"$(BUILD)/TestLoaderABI" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestCommandSymbols.Mod"
	cd "$(BUILD)" && ./TestCommandSymbols
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TOOLS)/tests/TestShared.Mod"
	"$(BUILD)/TestShared" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smd "$(TOOLS)/tests/TestLoaded.Mod"
	"$(BUILD)/TestLoaded" "runtime argument"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TOOLS)/tests/TestLoaded.Mod"
	"$(BUILD)/TestLoaded" "runtime argument"
	cp "$(BUILD)/TestLoaded" "$(BUILD)/TestLoaded.host"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/changed/TestLoaded.Mod"
	cmp "$(BUILD)/TestLoaded" "$(BUILD)/TestLoaded.host"
	"$(BUILD)/TestLoaded" "runtime argument"
	"$(BUILD)/hresh" "-P$(BUILD)" SharedConsumer.Run
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/platform/testDirectories.Mod"
	mkdir -p "$(BUILD)/directory-fixture/child"
	touch "$(BUILD)/directory-fixture/file.txt"
	ln -sfn child "$(BUILD)/directory-fixture/link"
	"$(BUILD)/testDirectories" "$(BUILD)/directory-fixture"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/arrayparameters/TestArrayParameters.mod"
	"$(BUILD)/TestArrayParameters"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/arrayparameters/TestOpenArrayRows.mod"
	"$(BUILD)/TestOpenArrayRows"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/arrayparameters/TestNestedArrayLengths.mod"
	"$(BUILD)/TestNestedArrayLengths"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/arrayparameters/TestFixedArrayValues.mod"
	"$(BUILD)/TestFixedArrayValues"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/filesafety/TestFileStrings.mod"
	"$(BUILD)/TestFileStrings"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/texts/TestScannerNumbers.mod"
	"$(BUILD)/TestScannerNumbers"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/intsyntax/TestSignedShifts.mod"
	"$(BUILD)/TestSignedShifts"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(ROOT)/src/test/confidence/heaproots" "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/heaproots/TestHeapRoots.mod"
	"$(BUILD)/TestHeapRoots"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/confidence/ckeywords/TestCKeywords.mod"
	"$(BUILD)/TestCKeywords"
	mkdir -p "$(BUILD)/compatibility"
	cd "$(BUILD)/compatibility" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" OBERON="$(VOCROOT)/2/sym" "$(NEWVOC)" -O2 -sm "$(TOOLS)/tests/CompatMain.Mod"
	"$(BUILD)/compatibility/CompatMain"
	cd "$(BUILD)" && for flags in -Md -MD -MP -D; do if $(ENV) "$(NEWVOC)" -s "$$flags" "$(TOOLS)/tests/TestLoaded.Mod"; then echo "Unexpectedly accepted $$flags"; exit 1; fi; done
	cd "$(BUILD)/compatibility" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" OBERON="$(VOCROOT)/2/sym" "$(NEWVOC)" -O2 -sM "$(TOOLS)/tests/CompatMain.Mod"
	"$(BUILD)/compatibility/CompatMain"

test-library: libraries
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestAsciiCodes.mod"
	"$(BUILD)/TestAsciiCodes"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/LongModuleRegistryNames.Mod"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(SUPPORT)" "$(NEWVOC)" -O$(MODEL) -smD "$(TOOLS)/tests/TestLibraries.Mod"
	"$(BUILD)/TestLibraries" "$(MODULES)/libraries.list" "$(MODULES)" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/ulm/testTimes.Mod"
	"$(BUILD)/testTimes"

test-tools: all test-hosted-unload
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestHostedTools.Mod"
	cd "$(BUILD)" && $(ENV) ./TestHostedTools
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -c "$(TOOLS)/tests/TestTerminalSupport.c" -o "$(BUILD)/TestTerminalSupport.o"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(TOOLS)/tests" LDLIBS="TestTerminalSupport.o" "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestTerminalState.Mod"
	cd "$(BUILD)" && ./TestTerminalState

# Cleanup lifetimes are independent: Ctrl-C stops a command; termination
# finalizes a module's objects before calling its private termination handler.
test-commands: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/InitInterruptProbe.Mod"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) -c "$(TOOLS)/tests/TestCommandSupport.c" -o "$(BUILD)/TestCommandSupport.o"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(TOOLS)/tests" LDLIBS="TestCommandSupport.o" "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestCommandStop.Mod"
	cd "$(BUILD)" && ./TestCommandStop
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/TerminationProbe.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestModuleTermination.Mod"
	"$(BUILD)/TestModuleTermination" "$(BUILD)"

test-unload: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadState.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadProbe.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadStopClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadResurrect.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadDamageClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadPinned.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadSpawn.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/UnloadCallbacks.Mod"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(INCLUDES) -c "$(TOOLS)/tests/TestModuleUnloadSupport.c" -o "$(BUILD)/TestModuleUnloadSupport.o"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(TOOLS)/tests" LDLIBS="TestModuleUnloadSupport.o $(DL_LIBS)" "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/tests/TestModuleUnload.Mod"
	"$(BUILD)/TestModuleUnload" "$(BUILD)"

test-hosted-unload: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/tests/ReloadDriver.Mod"
	cd "$(BUILD)" && printf '%s\n' 'ReloadDriver.VersionOne' 'compiler.Compile -sfl HostedReload.Mod' 'HostedReload.Run' 'system.Free HostedReload' 'ReloadDriver.VersionTwo' 'compiler.Compile -sfl HostedReload.Mod' 'ReloadDriver.CheckSymbols' 'HostedReload' 'HostedReload.Changed' 'system.Free HostedReload' 'ReloadDriver.Check' 'quit' | $(ENV) ./hresh "-P$(BUILD):$(MODULES)"

# Stage the separate profile. This never installs or replaces libvoc-O2.so.
INSTALL_ROOT ?= /usr/share/voc
INSTALL_LIBDIR ?= /usr/lib64
DESTDIR ?=
install-modular: libraries
	mkdir -p "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)"
	cd "$(MODULES)" && while IFS= read -r name; do cp "$$name.h" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include/" && cp "$$name.sym" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym/" && cp "libvoc-$$name-O$(MODEL).so" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)/" || exit; done < libraries.list
	cp "$(MODULES)/SYSTEM.h" "$(MODULES)/Platform.h" "$(MODULES)/Heap.h" "$(MODULES)/Modules.h" "$(MODULES)/PlatformDirectory.h" "$(MODULES)/PlatformTermios.h" "$(MODULES)/WindowsWrapper.h" "$(SUPPORT)/SharedModulesSupport.h" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include/"
	cp "$(MODULES)/Platform.sym" "$(MODULES)/Heap.sym" "$(MODULES)/Modules.sym" "$(ROOT)/src/runtime/Errors.Txt" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym/"
	cp "$(MODULES)/libvoc-core-O$(MODEL).so" "$(MODULES)/libvoc-core-O$(MODEL).a" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)/"
	cp "$(MODULES)/libraries.list" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/"

# Build and test both demo variants in src/test/shared-libraries.
demo:
	$(MAKE) -C "$(ROOT)/src/test/shared-libraries" test HRESH_BUILD="$(BUILD)" BUILD="$(BUILD)/library-demo" MODEL="$(MODEL)" VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"
