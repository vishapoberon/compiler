# Vishap Oberon master makefile.
#
# Makes sure configuration parameters are up to date and then hands off
# to src/tools/make/vishap.make.




# To build and install the Oberon compiler and library on a Unix based
# OS (Linux/Mac/BSD etc.) or on cygwin, run:
#
#   make full
#
# To override your OSs default C compiler, first run
#
#   export CC=compiler
#
# Where compiler is one of:
#
#   clang
#   gcc
#   i686-w64-mingw32-gcc        (32 bit cygwin only)
#   x86_64-w64-mingw32-gcc      (64 bit cygwin only)
#
# (To build on native Windows use make.cmd, not this makefile. Make.cmd automatically
# assumes use of the Microsoft compiler cl.)




# C compiler data models and sizes and alignments of Oberon types.
#
# There are just three distinct data models that we build for:
#
#    44  -  32 bit pointers, 32 bit alignment
#    48  -  32 bit pointers, 64 bit alignment
#    88  -  64 bit pointers, 64 bit alignment
#
# Meaning of n bit alignment:
#
#    Individual variables of up to n bits are aligned in memory to
#    whole multiples of their own size, rounded up to a power of two.
#    Variables larger than n bits are aligned to n bits.
#
#    (n will always be a power of 2).
#
# Thus:
#
#                  Size     32 bit alignment   64 bit alignment
#                --------   ----------------   ----------------
# CHAR            1 byte         1 byte             1 byte
# INTEGER         4 bytes        4 bytes            4 bytes
# LONGINT         8 bytes        4 bytes            8 bytes
#
# Note that in practice for 32 and 64 bit systems, this only affects
# LONGINT.
#
# C data model names:
#
# name           32 bit types            64 bit types         alignment
# ---------   ------------------   ------------------------   ---------
# ILP32       int, long, pointer   long long                  32 or 64
# LP64        int                  long, long long, pointer      64
# LLP64       int, long            long long                     64




# Default make target - explain usage
usage:
	@echo ""
	@echo Usage:
	@echo ""
	@echo "  make full"
	@echo ""
	@echo "      Does a full, clean build, installs it, and runs confidence tests."
	@echo "      Requires root access (for the install) except on cygwin."
	@echo ""
	@echo "Targets for building and installation:"
	@echo "  make clean         - Clean out the build directory"
	@echo "  make compiler      - Build the compiler but not the library"
	@echo "  make browsercmd    - Build the symbol browser (showdef)"
	@echo "  make library       - Build all library files and make library"
	@echo "  make install       - Install built compiler and library in /opt or C:\\PROGRAM FILES*"
	@echo "                       (Needs root access)"
	@echo ""
	@echo "Targets for (re)creating and reverting bootstrap C sources:"
	@echo "  make bootstrap       - Uddate bootstrap C source directories. Always run on 64 bit."
	@echo "  make revertbootstrap - Use git checkout to restore bootstrap C source directories"
	@echo ""
	@echo ""
	@echo "Multi-platform coordinated network build:"
	@echo "  make coordinator   - Start central task to trigger builds and collect logs"
	@echo "  make auto          - Start machine specific build server"
	@echo "  make autobuild     - Trigger all machines running 'make auto' to start a build"
	@echo "  make autobuild     - Terminate 'make auto' on all machines"




# Generate config files Configuration.Make and Configuration.Mod
FORCE:

configuration: FORCE
	@$(CC) -I src/system -o a.o src/tools/make/configure.c
	@./a.o
	@rm a.o
	@echo BRANCH=$$(git rev-parse --abbrev-ref HEAD)>>Configuration.Make
	@echo Branch: $$(git rev-parse --abbrev-ref HEAD).




reportsizes: FORCE
	@$(CC) -I src/system -o a.o src/tools/make/configure.c
	@./a.o report
	@rm a.o




# --- Building and installation ---




# clean - clean out the bulid directory
clean: configuration
	@make -f src/tools/make/vishap.make -s clean




# full: Full build of compiler and libarary.
full: configuration
	@make -f src/tools/make/vishap.make -s installable
	@-make -f src/tools/make/vishap.make -s uninstall
	@make -f src/tools/make/vishap.make -s clean
# Make bootstrap compiler from source suitable for current data model
	@printf "\n\n--- Compiler build started ---\n\n"
	@make -f src/tools/make/vishap.make -s compilerfromsavedsource
# Use bootstrap compiler to make compiler binary from latest compiler sources
	@make -f src/tools/make/vishap.make -s translate
	@make -f src/tools/make/vishap.make -s assemble
# Use latest compiler to make compiler binary from latest compiler sources
	@make -f src/tools/make/vishap.make -s translate
	@make -f src/tools/make/vishap.make -s assemble
	@printf "\n\n--- Compiler build successfull ---\n\n"
	@make -f src/tools/make/vishap.make -s browsercmd
	@printf "\n\n--- Library build started ---\n\n"
	@make -f src/tools/make/vishap.make -s library
	@printf "\n\n--- Library build successfull ---\n\n"
	@make -f src/tools/make/vishap.make -s sourcechanges
	@make -f src/tools/make/vishap.make -s install
	@printf "\n\n--- Confidence tests started ---\n\n"
	@make -f src/tools/make/vishap.make -s confidence
	@make -f src/tools/make/vishap.make -s showpath




# compile: compiler only, without cleaning
compiler: configuration
	@make -f src/tools/make/vishap.make -s translate
	@make -f src/tools/make/vishap.make -s assemble




# browsercmd: build the 'showdef' command
browsercmd: configuration
	@make -f src/tools/make/vishap.make -s browsercmd




# library: build all directories under src/library
library: configuration
	@make -f src/tools/make/vishap.make -s library

# Individual library components
v4: configuration
	@make -f src/tools/make/vishap.make -s v4

ooc2: configuration
	@make -f src/tools/make/vishap.make -s ooc2

ooc: configuration
	@make -f src/tools/make/vishap.make -s ooc

ulm: configuration
	@make -f src/tools/make/vishap.make -s ulm

pow32: configuration
	@make -f src/tools/make/vishap.make -s pow32

misc: configuration
	@make -f src/tools/make/vishap.make -s misc

s3: configuration
	@make -f src/tools/make/vishap.make -s s3



# install: Copy built files to install directory
install: configuration
	@make -f src/tools/make/vishap.make -s installable
	@make -f src/tools/make/vishap.make -s install
	@make -f src/tools/make/vishap.make -s showpath

uninstall: configuration
	@make -f src/tools/make/vishap.make -s installable
	@make -f src/tools/make/vishap.make -s uninstall




# confidence: Run a set of confidence tests
confidence: configuration
	@make -f src/tools/make/vishap.make -s confidence




# --- Bootstrap C source generation and reversion ---


# bootstrap: Rebuild the bootstrap directories
# If the bootstrap directories are broken or only partially
# built then run 'make revertbootstrap' first.
bootstrap: configuration
	@make -f src/tools/make/vishap.make -s clean
	@make -f src/tools/make/vishap.make -s translate
	@make -f src/tools/make/vishap.make -s assemble
	rm -rf bootstrap/*
	make -f src/tools/make/vishap.make -s translate INTSIZE=2 ADRSIZE=4 ALIGNMENT=4 PLATFORM=unix    BUILDDIR=bootstrap/unix-44    && rm bootstrap/unix-44/*.sym
	make -f src/tools/make/vishap.make -s translate INTSIZE=2 ADRSIZE=4 ALIGNMENT=8 PLATFORM=unix    BUILDDIR=bootstrap/unix-48    && rm bootstrap/unix-48/*.sym
	make -f src/tools/make/vishap.make -s translate INTSIZE=4 ADRSIZE=8 ALIGNMENT=8 PLATFORM=unix    BUILDDIR=bootstrap/unix-88    && rm bootstrap/unix-88/*.sym
	make -f src/tools/make/vishap.make -s translate INTSIZE=2 ADRSIZE=4 ALIGNMENT=8 PLATFORM=windows BUILDDIR=bootstrap/windows-48 && rm bootstrap/windows-48/*.sym
	make -f src/tools/make/vishap.make -s translate INTSIZE=4 ADRSIZE=8 ALIGNMENT=8 PLATFORM=windows BUILDDIR=bootstrap/windows-88 && rm bootstrap/windows-88/*.sym




revertbootstrap:
	@rm -rf bootstrap/*
	git checkout bootstrap




# --- multi-machine multi-platform build management ---

# NOTE: No longer used. Obsoleted by postpush.pl and buildall.pl.



# coordinator: Start the test machine coordinator
coordinator: configuration
	@make -f src/tools/make/vishap.make -s clean
	@make -f src/tools/make/vishap.make -s translate
	@make -f src/tools/make/vishap.make -s assemble
	@make -f src/tools/make/vishap.make -s testtools
	@rm -f "build/*.log"
	cd build && ../testcoordinator.exe




# auto: machine specific build server
auto: configuration
	@make -f src/tools/make/vishap.make -s auto




# autoonce: What auto does each time a build is triggered.
autoonce: configuration
	git pull
	@if make -s full; then echo \*\* Succeeded \*\*; else echo \*\* Failed \*\*;fi




# autobuild: Start test clients.
autobuild: configuration
	./testclient -c "make -s autoonce"




# autostop: Tell test clients to exit their wait loop.
autostop: configuration
	./testclient -c "exit"
