# Optional ELF modular runtime and shell. Bootstrap against the checkout image.
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
VOC ?= $(VOCROOT)/bin/voc
CC ?= cc
VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
MODEL ?= 2
BUILD ?= $(ROOT)/build/hresh
BUILD := $(abspath $(BUILD))
TOOLS := $(ROOT)/src/tools/hresh
EDITOR := $(ROOT)/src/tools/none
TESTS := $(ROOT)/src/test/hresh
SUPPORT := $(ROOT)/src/runtime
TERMINAL := $(ROOT)/src/library/terminal
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
WITH_CAIRO ?= 1
WITH_RAYLIB ?= 1
PKG_CONFIG ?= pkg-config
WITH_NETWORK ?= $(if $(filter Linux,$(shell uname -s)),1,0)
ifeq ($(WITH_NETWORK),1)
ifneq ($(shell uname -s),Linux)
$(error The networking profile requires Linux; set WITH_NETWORK=0)
endif
endif
C_MODEL ?= $(shell $(CC) -dM -E - < /dev/null | awk '$$2=="__SIZEOF_POINTER__" {p=$$3} $$2=="__SIZEOF_LONG__" {l=$$3} END {if(p==4) print "ILP32"; else if(l==8) print "LP64"; else print "LLP64"}')
include $(ROOT)/src/tools/make/modular-libraries.mk

# libc-backed ports remain in the ordinary library profile. Only bindings to
# additional native libraries belong to the explicitly requested add-on.
TERMINAL_SOURCES = $(addprefix $(TERMINAL)/,$(addsuffix .Mod,$(MODULAR_TERMINAL)))
STANDARD_SOURCES = $(addprefix $(ROOT)/src/library/,$(addsuffix .Mod,Out In Files Math MathL Oberon Reals Strings))
LIBRARY_SOURCES = $(addprefix $(ROOT)/src/library/,$(addsuffix .Mod,$(MODULAR_CLI))) \
 $(addprefix $(ROOT)/src/ports/v4/,$(addsuffix .Mod,$(MODULAR_V4))) \
 $(addprefix $(ROOT)/src/ports/ooc/,$(addsuffix .Mod,$(MODULAR_OOC) C$(C_MODEL))) \
 $(if $(filter 2,$(MODEL)),$(addprefix $(ROOT)/src/ports/xml/,$(addsuffix .Mod,$(MODULAR_XML)))) \
 $(addprefix $(ROOT)/src/ports/ulm/,$(addsuffix .Mod,$(MODULAR_ULM))) \
 $(addprefix $(ROOT)/src/ports/pow/,$(addsuffix .Mod,$(MODULAR_POW))) \
 $(addprefix $(ROOT)/src/library/misc/,$(addsuffix .Mod,$(MODULAR_MISC))) \
 $(addprefix $(ROOT)/src/ports/s3/,$(addsuffix .Mod,$(MODULAR_S3))) \
 $(addprefix $(ROOT)/src/ports/,$(addsuffix .Mod,$(MODULAR_PORTABLE) $(MODULAR_UNIX_PORTS) \
 $(if $(filter Linux,$(shell uname -s)),$(MODULAR_LINUX_BASE_PORTS)) \
 $(if $(filter 1,$(WITH_NETWORK)),$(MODULAR_LINUX_PORTS))))
BINDING_NAMES = $(if $(filter 1,$(WITH_X11)),$(MODULAR_X11)) \
 $(if $(filter 1,$(WITH_CAIRO)),$(MODULAR_CAIRO)) \
 $(if $(filter 1,$(WITH_RAYLIB)),$(MODULAR_RAYLIB))
BINDING_SOURCES = $(if $(filter 1,$(WITH_X11)),$(addprefix $(ROOT)/src/ports/oocX11/,$(addsuffix .Mod,$(MODULAR_X11)))) \
 $(if $(filter 1,$(WITH_CAIRO)),$(ROOT)/src/ports/une/oberon-cairo/Cairo.Mod) \
 $(if $(filter 1,$(WITH_RAYLIB)),$(addprefix $(ROOT)/src/ports/tmartiro/raylib/,$(addsuffix .Mod,$(MODULAR_RAYLIB))))

.PHONY: all compiler modules tools archives libraries bindings test test-tools test-commands test-unload test-hosted-unload test-library test-bindings test-archives demo install-modular install-modular-bindings FORCE
all: $(BUILD)/hresh $(BUILD)/none
ifeq ($(MODEL),2)
all: tools archives
tools: $(MODULES)/tools.stamp
archives: $(MODULES)/archives.stamp
else
tools:
	@echo "The hosted compiler and browser require MODEL=2."
	@exit 1
archives:
	@echo "The archive command profile requires MODEL=2."
	@exit 1
endif
compiler: $(NEWVOC)
modules: $(MODULES)/modules.stamp
ifeq ($(MODEL),2)
libraries: $(MODULES)/libraries.stamp
bindings: $(MODULES)/bindings.stamp
else
libraries bindings:
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

$(MODULES)/libvoc-core-O$(MODEL).so: $(NEWVOC) $(COMPILER)/CoreSource $(ROOT)/src/runtime/PlatformNativeunix.Mod $(ROOT)/src/runtime/Platformunix.Mod $(ROOT)/src/runtime/Heap.Mod $(ROOT)/src/runtime/Modules.Mod $(ROOT)/src/runtime/SYSTEM.c $(ROOT)/src/runtime/SYSTEM.h | $(MODULES)
	cp "$(ROOT)/src/runtime/SYSTEM.h" "$(ROOT)/src/runtime/WindowsWrapper.h" "$(MODULES)/"
	"$(COMPILER)/CoreSource" "$(ROOT)/src/runtime/Heap.Mod" "$(MODULES)/Heap.Mod"
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(ROOT)/src/runtime/PlatformNativeunix.Mod"
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(ROOT)/src/runtime/Platformunix.Mod"
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFSapx Heap.Mod
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(ROOT)/src/runtime/Modules.Mod"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -DVOC_CORE_RUNTIME -c "$(ROOT)/src/runtime/SYSTEM.c" -o "$(MODULES)/SYSTEM.o"
	cd "$(MODULES)" && $(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -c PlatformNative.c Platform.c Heap.c Modules.c
	ar rcs "$(MODULES)/libvoc-core-O$(MODEL).a" $(addprefix $(MODULES)/,SYSTEM.o PlatformNative.o Platform.o Heap.o Modules.o)
	$(CC) -shared $(LDFLAGS) $(if $(findstring tcc,$(CC)),,-Wl,-z,defs) -Wl,-soname,libvoc-core-O$(MODEL).so -o "$@" $(addprefix $(MODULES)/,SYSTEM.o PlatformNative.o Platform.o Heap.o Modules.o)

# The dependency order is the Oberon import order. The compiler discovers the
# actual DT_NEEDED edges itself; no list of commands/imports is generated here.
$(MODULES)/modules.stamp: $(MODULES)/libvoc-core-O$(MODEL).so $(wildcard $(ROOT)/src/runtime/*.Mod) $(STANDARD_SOURCES) $(TERMINAL_SOURCES) $(ROOT)/src/ports/ooc/oocStrings.Mod $(ROOT)/src/tools/make/modular-libraries.mk $(TOOLS)/Makefile
	@for name in $(addprefix ooc,$(filter-out ooc% Real0 oo2c2LRealConv,$(MODULAR_OOC)) C) $(addprefix ooc2,$(filter-out ooc% oo2c2LRealConv,$(MODULAR_OOC))) ooc2Strings; do \
	  if [ -e "$(MODULES)/$$name.sym" ] || [ -e "$(MODULES)/libvoc-$$name-O$(MODEL).so" ]; then \
	    echo "Obsolete oo2c module $$name in $(MODULES); rebuild in a fresh BUILD directory."; exit 1; \
	  fi; \
	done
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) -D_GNU_SOURCE -DVOC_RESOURCE_ROOT='\"$(RESOURCE_ROOT)\"'" LDLIBS="$(DL_LIBS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/NativeModules.Mod"
	cd "$(MODULES)" && for name in ModulePaths ModuleImages NativeLibraries ModuleLoader; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/Out.Mod"
	cd "$(MODULES)" && for name in Reals Strings; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/Files.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/In.Mod"
	cd "$(MODULES)" && for name in Math MathL; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in Texts; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/runtime/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/Oberon.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/runtime/VT100.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/ooc/oocStrings.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/CommandSymbols.Mod"
	cd "$(MODULES)" && for name in $(MODULAR_TERMINAL); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TERMINAL)/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) -I$(SUPPORT)" "$(NEWVOC)" -O$(MODEL) -sFl "$(SUPPORT)/SharedModules.Mod"
	touch "$@"

# In-process tools share the shell's core and library instances. Loading the
# compiler or browser never invokes their conventional command-line startup.
$(MODULES)/tools.stamp: $(MODULES)/modules.stamp $(wildcard $(ROOT)/src/compiler/*.Mod) $(ROOT)/src/tools/browser/BrowserCmd.Mod $(TOOLS)/compiler.Mod $(TOOLS)/browser.Mod $(EDITOR)/none.Mod $(TOOLS)/system.Mod
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(COMPILER)/Configuration.Mod"
	cd "$(MODULES)" && for name in OPM OPS OPT OPC OPV OPB OPP extTools Compiler; do $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/compiler/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/tools/browser/BrowserCmd.Mod"
	cd "$(MODULES)" && for name in compiler browser system; do $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $(COMPILER_CFLAGS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(EDITOR)/none.Mod"
	touch "$@"

FORCE:

# Changing optional profiles must also refresh the installed file list.
$(MODULES)/libraries.config: FORCE | $(MODULES)
	@printf '%s\n' 'WITH_NETWORK=$(WITH_NETWORK)' > "$@.new"
	@if cmp -s "$@.new" "$@"; then rm "$@.new"; else mv "$@.new" "$@"; fi

$(MODULES)/bindings.config: FORCE | $(MODULES)
	@printf '%s\n' 'WITH_X11=$(WITH_X11)' 'WITH_CAIRO=$(WITH_CAIRO)' 'WITH_RAYLIB=$(WITH_RAYLIB)' 'PKG_CONFIG=$(PKG_CONFIG)' > "$@.new"
	@if cmp -s "$@.new" "$@"; then rm "$@.new"; else mv "$@.new" "$@"; fi

$(MODULES)/archives.stamp: $(MODULES)/modules.stamp $(ROOT)/src/tools/make/modular-libraries.mk $(addprefix $(ROOT)/src/ports/s3/,$(addsuffix .Mod,$(MODULAR_ARCHIVE))) $(TOOLS)/CommandArgs.Mod $(TOOLS)/ArchivePaths.Mod $(TOOLS)/gzip.Mod $(TOOLS)/zip.Mod
	@for name in $(addprefix eth,$(MODULAR_ARCHIVE)); do \
	  if [ -e "$(MODULES)/$$name.sym" ] || [ -e "$(MODULES)/libvoc-$$name-O$(MODEL).so" ]; then \
	    echo "Obsolete module $$name in $(MODULES); rebuild in a fresh BUILD directory."; exit 1; \
	  fi; \
	done
	cd "$(MODULES)" && for name in $(MODULAR_ARCHIVE); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/s3/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/CommandArgs.Mod"
	cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) -I$(TOOLS)" "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/ArchivePaths.Mod"
	cd "$(MODULES)" && for name in gzip zip; do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TOOLS)/$$name.Mod" || exit; done
	touch "$@"

$(MODULES)/libraries.stamp: $(MODULES)/modules.stamp $(MODULES)/tools.stamp $(MODULES)/archives.stamp $(MODULES)/libraries.config $(ROOT)/src/tools/make/modular-libraries.mk $(TOOLS)/Makefile $(LIBRARY_SOURCES)
	@for name in $(addprefix ulm,$(filter-out ulm%,$(MODULAR_ULM))) $(addprefix eth,$(filter-out eth%,$(MODULAR_S3))); do \
	  if [ -e "$(MODULES)/$$name.sym" ] || [ -e "$(MODULES)/libvoc-$$name-O$(MODEL).so" ]; then \
	    echo "Obsolete module $$name in $(MODULES); rebuild in a fresh BUILD directory."; exit 1; \
	  fi; \
	done
	cd "$(MODULES)" && for name in $(MODULAR_CLI); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_V4); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/v4/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_OOC); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/ooc/$$name.Mod" || exit; done
	cd "$(MODULES)" && $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/ooc/C$(C_MODEL).Mod"
	@if [ "$(MODEL)" = 2 ]; then cd "$(MODULES)" && for name in $(MODULAR_XML); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/xml/$$name.Mod" || exit; done; fi
	cd "$(MODULES)" && for name in $(MODULAR_ULM); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/ulm/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_POW); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/pow/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_MISC); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/library/misc/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(filter-out $(MODULAR_ARCHIVE),$(MODULAR_S3)); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/s3/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_PORTABLE); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/$$name.Mod" || exit; done
	cd "$(MODULES)" && for name in $(MODULAR_UNIX_PORTS); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/$$name.Mod" || exit; done
	if [ "$(shell uname -s)" = Linux ]; then cd "$(MODULES)" && for name in $(MODULAR_LINUX_BASE_PORTS); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/$$name.Mod" || exit; done; fi
	if [ "$(WITH_NETWORK)" = 1 ]; then cd "$(MODULES)" && for name in $(MODULAR_LINUX_PORTS); do $(LIBRARY_ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/$$name.Mod" || exit; done; fi
	printf '%s\n' Out Reals Strings In Files Math MathL Texts Oberon VT100 NativeModules ModulePaths ModuleImages NativeLibraries ModuleLoader CommandSymbols $(MODULAR_TERMINAL) SharedModules $(SOURCES) BrowserCmd compiler browser none system CommandArgs ArchivePaths gzip zip $(MODULAR_CLI) $(MODULAR_V4) $(MODULAR_OOC) C $(if $(filter 2,$(MODEL)),$(MODULAR_XML)) $(MODULAR_ULM) $(MODULAR_POW) $(MODULAR_MISC) $(MODULAR_S3) $(notdir $(MODULAR_PORTABLE) $(MODULAR_UNIX_PORTS)) $(if $(filter Linux,$(shell uname -s)),$(notdir $(MODULAR_LINUX_BASE_PORTS))) $(if $(filter 1,$(WITH_NETWORK)),$(notdir $(MODULAR_LINUX_PORTS))) | awk '!seen[$$0]++' > "$(MODULES)/libraries.list"
	touch "$@"

# This target alone needs the development packages for extra native APIs.
# Keep its manifest separate: rebuilding/installing libraries never adds them.
$(MODULES)/bindings.stamp: $(MODULES)/libraries.stamp $(MODULES)/bindings.config $(ROOT)/src/tools/make/modular-libraries.mk $(TOOLS)/Makefile $(BINDING_SOURCES)
	if [ "$(WITH_X11)" = 1 ]; then cd "$(MODULES)" && for name in $(MODULAR_X11); do $(LIBRARY_ENV) LDLIBS="$(LDLIBS) -lX11" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/oocX11/$$name.Mod" || exit; done; fi
	@if [ "$(WITH_CAIRO)" = 1 ]; then \
	  $(PKG_CONFIG) --exists cairo || { echo "Cairo bindings require pkg-config and Cairo development files (Debian: pkg-config libcairo2-dev)."; exit 1; }; \
	  cflags=$$($(PKG_CONFIG) --cflags cairo) && libs=$$($(PKG_CONFIG) --libs cairo) || exit; \
	  cd "$(MODULES)" && $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $$cflags" LDLIBS="$(LDLIBS) $$libs" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/une/oberon-cairo/Cairo.Mod" || exit; \
	fi
	@if [ "$(WITH_RAYLIB)" = 1 ]; then \
	  $(PKG_CONFIG) --exists raylib || { echo "Raylib bindings require pkg-config and raylib development files (Debian: pkg-config libraylib-dev)."; exit 1; }; \
	  cflags=$$($(PKG_CONFIG) --cflags raylib) && libs=$$($(PKG_CONFIG) --libs raylib) || exit; \
	  cd "$(MODULES)" && for name in $(MODULAR_RAYLIB); do \
	    $(LIBRARY_ENV) CFLAGS="$(CFLAGS) $$cflags" LDLIBS="$(LDLIBS) $$libs" "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/ports/tmartiro/raylib/$$name.Mod" || exit; \
	  done; \
	fi
	printf '%s\n' $(BINDING_NAMES) | awk 'NF && !seen[$$0]++' > "$(MODULES)/bindings.list"
	touch "$@"

$(BUILD)/hresh: $(TOOLS)/hresh.Mod $(MODULES)/modules.stamp
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TOOLS)/hresh.Mod"

$(BUILD)/none: $(EDITOR)/none.Mod $(MODULES)/modules.stamp
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$<"

test: all test-commands test-unload
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestModulePaths.Mod"
	"$(BUILD)/TestModulePaths"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestModuleImages.Mod"
	"$(BUILD)/TestModuleImages"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/SharedProvider.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/SharedConsumer.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/TypeOnly.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/HelloShared.Mod"
	"$(BUILD)/HelloShared"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TESTS)/HelloShared.Mod"
	"$(BUILD)/HelloShared"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestShared.Mod"
	"$(BUILD)/TestShared" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFSl "$(TESTS)/BadCoreABI.Mod"
	cd "$(BUILD)" && sed 's/__voc_runtime = &VOC_CoreABI;/__voc_runtime = \&VOC_CoreABI + 1;/' BadCoreABI.c > BadCoreABI-bad.c
	cd "$(BUILD)" && $(CC) $(CFLAGS) $(NATIVEFLAGS) $(INCLUDES) -shared BadCoreABI-bad.c -o "libvoc-BadCoreABI-O$(MODEL).so"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestLoaderABI.Mod"
	"$(BUILD)/TestLoaderABI" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestCommandSymbols.Mod"
	cd "$(BUILD)" && ./TestCommandSymbols
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TESTS)/TestShared.Mod"
	"$(BUILD)/TestShared" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smd "$(TESTS)/TestLoaded.Mod"
	"$(BUILD)/TestLoaded" "runtime argument"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TESTS)/TestLoaded.Mod"
	"$(BUILD)/TestLoaded" "runtime argument"
	cp "$(BUILD)/TestLoaded" "$(BUILD)/TestLoaded.host"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/TestLoadedWithImport.Mod"
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
	cd "$(BUILD)/compatibility" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" OBERON="$(VOCROOT)/2/sym" "$(NEWVOC)" -O2 -sm "$(TESTS)/CompatMain.Mod"
	"$(BUILD)/compatibility/CompatMain"
	cd "$(BUILD)" && for flags in -Md -MD -MP -D; do if $(ENV) "$(NEWVOC)" -s "$$flags" "$(TESTS)/TestLoaded.Mod"; then echo "Unexpectedly accepted $$flags"; exit 1; fi; done
	cd "$(BUILD)/compatibility" && VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" OBERON="$(VOCROOT)/2/sym" "$(NEWVOC)" -O2 -sM "$(TESTS)/CompatMain.Mod"
	"$(BUILD)/compatibility/CompatMain"

test-library: libraries
	@if [ "$(MODEL)" = 2 ]; then cd "$(BUILD)" && for name in TestParser TestValidation TestWriter TestBasic; do $(ENV) "$(NEWVOC)" -O2 -smD "$(ROOT)/src/ports/xml/tests/voc/$$name.Mod" && "./$$name" || exit; done; fi
	$(MAKE) -C "$(ROOT)/src/test/ports" test VOC="$(NEWVOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(MODULES)" SYMBOLS="$(MODULES)" MODEL=$(MODEL) FLAGS=-smD NETWORK=$(WITH_NETWORK) BUILD="$(BUILD)/port-tests"
	$(MAKE) -C "$(ROOT)/src/test/ports/sts-q" test-bundled VOC="$(NEWVOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(MODULES)" SYMBOLS="$(MODULES)" MODEL=$(MODEL) FLAGS=-smD BUILD="$(BUILD)/kbd-tests"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestAsciiCodes.mod"
	"$(BUILD)/TestAsciiCodes"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestOocUnified.mod"
	"$(BUILD)/TestOocUnified"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(ROOT)/src/test/confidence/library/TypeAliases.mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestTypeAliases.mod"
	"$(BUILD)/TestTypeAliases"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestIntStr.mod"
	"$(BUILD)/TestIntStr"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestLibraryNames.mod"
	"$(BUILD)/TestLibraryNames"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/LongModuleRegistryNames.Mod"
	cd "$(BUILD)" && $(ENV) CFLAGS="$(CFLAGS) -I$(SUPPORT)" "$(NEWVOC)" -O$(MODEL) -smD "$(TESTS)/TestLibraries.Mod"
	"$(BUILD)/TestLibraries" "$(MODULES)/libraries.list" "$(MODULES)" "$(BUILD)"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/ulm/testTimes.Mod"
	"$(BUILD)/testTimes"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/confidence/library/TestCompression.mod"
	cd "$(BUILD)" && ./TestCompression
	$(MAKE) -f "$(TOOLS)/Makefile" test-archives BUILD="$(BUILD)" VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)" CFLAGS="$(CFLAGS)"

test-bindings: bindings
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(TESTS)/TestBindings.Mod"
	"$(BUILD)/TestBindings" "$(MODULES)/bindings.list" "$(MODULES)"
	@if [ "$(WITH_CAIRO)" = 1 ]; then \
	  mkdir -p "$(BUILD)/cairo-test" && cd "$(BUILD)/cairo-test" && \
	  $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/ports/cairo/TestCairo.Mod" && ./TestCairo || exit; \
	fi
	@if [ "$(WITH_RAYLIB)" = 1 ]; then \
	  mkdir -p "$(BUILD)/raylib-test" && cd "$(BUILD)/raylib-test" && \
	  $(ENV) "$(NEWVOC)" -O$(MODEL) -smD "$(ROOT)/src/test/ports/raylib/TestRaylib.Mod" && ./TestRaylib || exit; \
	fi

test-archives: archives $(BUILD)/hresh
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(ROOT)/src/test/platform/TestPlatformTime.Mod"
	cd "$(BUILD)" && TZ=UTC0 ./TestPlatformTime "$(BUILD)/platform-time-fixture"
	python3 "$(TESTS)/test-archives.py" "$(BUILD)/hresh" "$(MODULES)" "$(BUILD)"

test-tools: all test-hosted-unload
	python3 "$(EDITOR)/test-editor.py" "$(BUILD)/none" --hresh "$(BUILD)/hresh" --modules "$(MODULES)" --work "$(BUILD)/editor-tests"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestHostedTools.Mod"
	cd "$(BUILD)" && $(ENV) ./TestHostedTools
	cd "$(MODULES)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFSl "$(TESTS)/TestTerminalNative.Mod"
	$(CC) $(CFLAGS) $(NATIVEFLAGS) $(CORE_INCLUDES) -D_XOPEN_SOURCE=700 -shared "$(MODULES)/TestTerminalNative.c" -Wl,-soname,libvoc-TestTerminalNative-O$(MODEL).so -o "$(BUILD)/libvoc-TestTerminalNative-O$(MODEL).so"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestTerminalState.Mod"
	cd "$(BUILD)" && ./TestTerminalState

# Cleanup lifetimes are independent: Ctrl-C stops a command; termination
# finalizes a module's objects before calling its private termination handler.
test-commands: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/InitInterruptProbe.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFS "$(TESTS)/TestCommandNative.Mod"
	cd "$(BUILD)" && $(CC) $(CFLAGS) $(NATIVEFLAGS) $(INCLUDES) -shared TestCommandNative.c -Wl,-soname,libvoc-TestCommandNative-O$(MODEL).so -o libvoc-TestCommandNative-O$(MODEL).so
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestCommandStop.Mod"
	cd "$(BUILD)" && ./TestCommandStop
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/TerminationProbe.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestModuleTermination.Mod"
	"$(BUILD)/TestModuleTermination" "$(BUILD)"

test-unload: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadState.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadProbe.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadStopClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadResurrect.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadDamageClient.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadPinned.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadSpawn.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/UnloadCallbacks.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/TestUnloadNative.Mod"
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -smP "$(TESTS)/TestModuleUnload.Mod"
	"$(BUILD)/TestModuleUnload" "$(BUILD)"

test-hosted-unload: all
	cd "$(BUILD)" && $(ENV) "$(NEWVOC)" -O$(MODEL) -sFl "$(TESTS)/ReloadDriver.Mod"
	cd "$(BUILD)" && printf '%s\n' 'ReloadDriver.VersionOne' 'compiler.Compile -sfl HostedReload.Mod' 'HostedReload.Run' 'system.Free HostedReload' 'ReloadDriver.VersionTwo' 'compiler.Compile -sfl HostedReload.Mod' 'ReloadDriver.CheckSymbols' 'HostedReload' 'HostedReload.Changed' 'system.Free HostedReload' 'ReloadDriver.Check' 'quit' | $(ENV) ./hresh "-P$(BUILD):$(MODULES)"

# Stage the separate profile. This never installs or replaces libvoc-O2.so.
INSTALL_ROOT ?= /usr/share/voc
INSTALL_LIBDIR ?= /usr/lib64
DESTDIR ?=
install-modular: libraries
	mkdir -p "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)"
	cd "$(MODULES)" && while IFS= read -r name; do cp "$$name.h" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include/" && cp "$$name.sym" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym/" && cp "libvoc-$$name-O$(MODEL).so" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)/" || exit; done < libraries.list
	cp "$(MODULES)/SYSTEM.h" "$(MODULES)/PlatformNative.h" "$(MODULES)/Platform.h" "$(MODULES)/Heap.h" "$(MODULES)/Modules.h" "$(MODULES)/WindowsWrapper.h" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include/"
	cp "$(MODULES)/PlatformNative.sym" "$(MODULES)/Platform.sym" "$(MODULES)/Heap.sym" "$(MODULES)/Modules.sym" "$(ROOT)/src/runtime/Errors.Txt" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym/"
	cp "$(MODULES)/libvoc-core-O$(MODEL).so" "$(MODULES)/libvoc-core-O$(MODEL).a" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)/"
	cp "$(MODULES)/libraries.list" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/"

install-modular-bindings: install-modular bindings
	cd "$(MODULES)" && while IFS= read -r name; do cp "$$name.h" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/include/" && cp "$$name.sym" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/sym/" && cp "libvoc-$$name-O$(MODEL).so" "$(DESTDIR)$(INSTALL_LIBDIR)/voc/modular/$(MODEL)/" || exit; done < bindings.list
	cp "$(MODULES)/bindings.list" "$(DESTDIR)$(INSTALL_ROOT)/modular/$(MODEL)/"

# Build and test both demo variants in src/examples/shared-libraries.
demo:
	$(MAKE) -C "$(ROOT)/src/examples/shared-libraries" test HRESH_BUILD="$(BUILD)" BUILD="$(BUILD)/library-demo" MODEL="$(MODEL)" VOC="$(VOC)" VOCROOT="$(VOCROOT)" VOCLIBDIR="$(VOCLIBDIR)"
