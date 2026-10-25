# Shared modules and hresh

An Oberon program consists of modules. A module provides an interface through
its exported declarations and an implementation through its procedures and
module body. Other modules use this interface by naming the module in an
`IMPORT` statement.

VOC can compile a module into a native shared library. A program may then load
the module when it is needed, rather than link its implementation into the
executable. The same module can be used by a command shell or by an ordinary
standalone application. The Oberon source still uses `IMPORT` and ordinary
procedure calls; no special calling convention is required in the program.

For a step-by-step introduction, see [A gentle introduction to shared
modules](ModuleTutorial.md). This page describes the compilation options,
library organisation and loading rules in more detail.

## Two ways to organise the runtime

The conventional VOC runtime is a single library containing the standard
modules. A program compiled with `-m` uses the shared `libvoc` library. On Linux,
`-M` links the program and its libraries statically. These options retain their
usual meaning.

The modular runtime separates the libraries into individual modules. A small
common core contains `SYSTEM`, `PlatformNative`, `Platform`, `Heap` and `Modules`. The remaining
modules have their own shared libraries. For example, `Out` is provided by
`libvoc-Out-O2.so`, and `oocStrings` by `libvoc-oocStrings-O2.so`.

All modules in one process use the same core, including the same heap and
module registry. The core may be a shared library or part of the executable.
Do not load individual modular libraries into a process using the conventional
monolithic runtime. The two arrangements may coexist in an installation, but
must not be mixed within a program.

## Compiling a shared module

Suppose that `Commands.Mod` contains a module named `Commands`. Compile it with:

```sh
voc -sl Commands.Mod
```

The `-l` option builds a shared library. The `-s` option allows the compiler to
replace a previous symbol file if the module's interface has changed. With
the default Oberon-2 type model, the following files are produced:

| File | Purpose |
| --- | --- |
| `Commands.sym` | Exported declarations used when compiling an importing module |
| `Commands.h` | Declarations used by the C backend |
| `Commands.c` | The translated implementation |
| `libvoc-Commands-O2.so` | The compiled module, ready to be loaded |

Compile dependencies first. An `IMPORT` statement tells VOC which module
libraries are needed; a separate list of imports is not required for linking.
Even an import used only for a type is retained, since the imported module
may have initialisation code.

The shared library, symbol file and header have different uses. Executing a
compiled program requires the library. Compiling another module against it
also requires the symbol file and header. `hresh` uses symbol files to discover
commands in modules that have not yet been loaded.

`-l` cannot be combined with an executable option. `-lc` compiles a modular
object without linking the shared library, and `-lS` produces the translated
C without invoking the C compiler.

## Building an application which loads its main module

An application need not use `hresh`. Consider the following main module:

```oberon
MODULE Main;
  IMPORT Out;
BEGIN
  Out.String("Hello from a loaded module"); Out.Ln
END Main.
```

Save it as `Main.Mod`, then compile and run it:

```sh
voc -smd Main.Mod
./Main
```

The compiler creates an executable named `Main` and an application library
named `libvoc-Main-O2.so`. The executable is a small host: it starts the common
runtime, loads the application library, and executes the module body. Loading
`Main` also makes its imported `Out` library available. The imported module is
initialised before the body of `Main` runs.

The host links to the loader and core, not to the application or its imports.
On Linux, `ldd Main` therefore lists `libvoc-ModuleLoader-O2.so`,
`libvoc-core-O2.so` and libc, but not `libvoc-Main-O2.so` or `libvoc-Out-O2.so`.
The latter libraries are loaded after the executable starts.

To place the common core inside the executable instead, use:

```sh
voc -smD Main.Mod
```

This host uses the same application libraries. Its core is no longer a shared
library dependency, but its loader, application and libc remain shared. Thus
`-mD` is not a fully static build.

The available executable options can be summarised as follows:

| Option | Runtime arrangement | Application entry |
| --- | --- | --- |
| `-m` | Shared monolithic runtime | Conventionally linked main module |
| `-M` | Static monolithic runtime and, on Linux, static system libraries | Conventionally linked main module |
| `-md` | Shared minimal core | Main module loaded after startup |
| `-mD` | Minimal core embedded in the executable | Main module loaded after startup |
| `-mP` | Shared minimal core and individual module libraries | Main module linked at startup |

`-d` is a shorthand for `-md`. Uppercase `-P` selects modular linking;
lowercase `-p` still controls pointer initialisation. `-M` cannot be combined
with `-d`, `-D` or `-P`: fully static system linking is not suitable for these
loading hosts. `-dS` generates the application and host C sources without
compiling them; `-dc` compiles only the application object.

Program arguments remain available through `Modules.GetArg`. Finalisers run
when the program exits normally, just as with a conventionally linked main.

## Changing an application

The host is independent of the main module's imports. After changing the body
of `Main`, rebuild only its library:

```sh
voc -sl Main.Mod
./Main
```

There is no need to relink the executable. Adding an import also requires only
an application-library rebuild, provided the imported library has already been
built. Changing an exported interface may require recompiling the modules
which use that interface.

A loaded module is not replaced in a running process. Exit and restart the
application, or leave and restart `hresh`, before using a rebuilt library.

## Commands in hresh

`hresh` executes exported Oberon procedures in its own process. A procedure
which has no formal parameters and no result can be used as a command. For
example, the exported `Run` procedure in `Commands` is called by typing:

```text
> Commands.Run
```

Typing just the module name lists its commands:

```text
> Commands
  Commands.Run
```

Listing a module or completing its name with Tab does not execute its
initialisation code. The shell reads the module's `.sym` file. When a command
is first invoked, the library and its imports are loaded and initialised.
Later invocations use the same module and its existing variables.

The shell provides cursor editing, backspace and delete, session history,
Ctrl-A/E/U, and Ctrl-C to cancel a line. Tab completes module and command names;
after a command it completes file and directory names. Relative, absolute and
`~/` paths are accepted. Quote an argument containing spaces. A completed
directory name ends in `/`, allowing completion to continue inside it.

Type `quit` or `exit`, or press Ctrl-D on an empty line, to leave the shell.
`hresh` is an Oberon command host, not a Unix shell: commands such as `voc` and
`ldd` should be entered at the operating system's shell prompt.

It is also possible to run one command or a sequence of commands without an
interactive prompt:

```sh
hresh Commands.Run
printf 'Commands.Run\nCommands.Run\n' | hresh
```

A command may read the text following its name through `Oberon.Par.text`,
starting at `Oberon.Par.pos`. This follows the usual Oberon command convention.
Exported procedures with parameters or results remain available to importing
modules, but are not commands in the shell.

### Compiler, definition browser and editor

The Oberon-2 modular profile includes lowercase command modules:

```text
> none.Open Commands.Mod
> compiler.Compile -sl Commands.Mod
> browser.ShowDef Commands
> Commands.Run
> system.ShowModules
> system.Free Commands
```

`compiler.Compile` runs the compiler inside the shell and returns after source
or C compilation errors. It accepts the usual VOC options. Use `-sl` to build
a library for `hresh`; conventional `-m` and `-M` builds still produce standalone
programs. Rebuilding a library which is already loaded is refused: successfully
free it with `system.Free` first, or restart the shell. Compilation still invokes the selected native C
compiler and linker as external programs.

`browser.ShowDef` reads a module's `.sym` file without loading that module or
running its initializer. The `.sym` suffix is optional; `-x` shows layout details.
`system.ShowCommands` lists a module's commands, `system.ShowModules` lists loaded
modules, `system.Collect` collects garbage, and `system.Directory` lists files in
the current or named directory.
Each module's reference count includes one persistent runtime pin, applied
before its initialization body executes, plus references from importing modules.
Explicitly retained references are shown separately.

`none.Open` edits a file in the terminal. Ctrl-O saves, Ctrl-X exits,
Ctrl-W searches, and Ctrl-G shows help. Shift with movement keys selects text;
Ctrl-B selects a rectangular block. Ctrl-C copies, Ctrl-K cuts and Ctrl-V or
Ctrl-U pastes. The editor supports bracketed paste and restores the terminal
when returning to the shell. Plain files remain plain; Ctrl-T in the save prompt
switches between plain and Oberon text storage.

These commands read parameters with `Texts.Scanner` from `Oberon.Par.text`, not
from the process's startup arguments. Use double quotes for paths containing
spaces or punctuation. The scanner accepts arguments of at most 62 characters.

The same editor also builds as a standalone executable against the conventional
VOC library, using an installed compiler:

```sh
make none
build/none/none 'Commands.Mod'
make none-test
```

`make -C src/tools/none` builds it directly. Set `VOC` to select the compiler
and `BUILD` to select the output directory. The standalone command takes one
file name directly from its command-line arguments; shell quoting preserves
spaces. File names remain subject to the `Files` module's resolved-path limits.
`none --help` shows usage. A full Unix build includes
`none` in `install/bin/`, and `make install` installs it alongside `voc`.

### Stopping commands and cleaning up modules

In a Unix `hresh`, Ctrl-C stops the current command and returns to the prompt.
Commands which hold resources register an idempotent, parameterless cleanup
procedure with `Oberon.OnStop`:

```oberon
PROCEDURE Close;
BEGIN
  (* Close sockets or files held in module variables, then clear those variables.
     Do nothing when the resources have already been closed. *)
END Close;

PROCEDURE Run*;
BEGIN
  Oberon.OnStop(Close);
  (* Acquire resources and perform the command's work. *)
  Close
END Run;
```

Registrations persist between commands; registering the same procedure again
does not duplicate it. The shell calls the cleanup procedures after leaving
the stopped command, not from the signal handler. There is no stack unwinding:
the command does not resume, and local resources are not automatically closed.
Keep resources needed by cleanup in module variables.
`Oberon.RemoveStop(Close)` removes a registration. Successful module teardown
calls and removes that owner's stop cleanups; they are not called again after
its code is unloaded. A stop-cleanup snapshot retains its callback owners until
the snapshot has been called and reinstalled.

Module termination is a separate lifetime. A modular library can register
`Modules.InstallTermHandler(Close)` in its initialization body. Each module has
one termination handler; a later registration replaces it. `Modules.res = 0`
reports success. The runtime identifies even private handlers from procedure
addresses registered by the compiler, without relying on native library layouts.
At normal shutdown or `HALT`, object finalizers run first, then module termination
handlers run with clients before their imports. A callback is removed before it
is called, so it is not called twice by repeated finalization. Termination
handlers should not call importing clients or register further cleanup work.

Cancellation is deferred until an Oberon statement or loop boundary. Runtime
heap, file-buffer and text-list updates, initializers, and generated native calls
are protected against cancellation midway through an update. Native calls must
return before the stop can be delivered; foreign code that retries interrupts
indefinitely can therefore delay Ctrl-C indefinitely. Native code which calls
back into Oberon must keep that entire call protected. For other multi-step
resource updates, pair `Platform.CommandCritical(TRUE)` and
`Platform.CommandCritical(FALSE)`; do not return early while still protected.
This facility is single-threaded and does not recover from `HALT`, assertions,
or faults. Commands must not replace the host's SIGINT handler.

`none` keeps Ctrl-C for copying text. In `hresh`, an external SIGINT stops the editor and runs
its terminal-restoration cleanup. Ordinary editor exit restores the terminal too.

### Checked unloading and rebuilding

On Linux with glibc, `system.Free Commands` unloads an eligible module. Several
names may be supplied, in client-before-import order; the customary trailing
`~` is optional. No force-unload operation is provided.

The runtime refuses freeing modules that have loaded import clients, executing
code, explicitly retained references, or externally reachable heap objects whose
type descriptors belong to the module. The current initializer, permanent core,
untracked modules, and unloading during heap collection/finalization are also
protected. Signal callbacks installed through `Platform` are checked too;
remove or replace them before freeing their owner. Conservative stack roots
can delay a free even after a variable has been cleared. A refusal before
cleanup preserves the module's private state.

After these checks, stop cleanups and object finalizers run, followed by the
module's termination handler. Imports stay mapped throughout cleanup. The runtime
collects the module's private objects, rechecks for surviving descriptors and
callbacks, closes its native ownership, verifies that the old image is gone,
then removes its registry/procedure metadata and releases its import references.
Each initialized library has independent native ownership, including imports
loaded implicitly by the ELF loader.

Cleanup must not create new external objects, install further callbacks, load
new clients of the terminating module, or recursively free modules. If cleanup
leaves references, or the native loader unexpectedly retains the old image, the
module remains mapped but is **finalized and disabled**. The command reports
failure; restart the host process before loading the module again. Explicit ELF
`NODELETE` libraries are refused before cleanup. Musl keeps libraries mapped,
so checked unloading is refused there. BSD unloading has not been validated.
Any attached native library destructors must obey the same contract and must
not reenter Oberon while the native image is being closed.

After a successful free, edit and rebuild normally:

```text
> system.Free Commands
> none.Open Commands.Mod
> compiler.Compile -sl Commands.Mod
> system.ShowCommands Commands
> Commands.NewCommand
```

Discovery reads the new `.sym` file without initializing the replacement.
The next invocation loads fresh code and runs its initializer. Changing an
exported interface can require rebuilding and reloading its importing clients.

### Retaining dynamically obtained commands and native references

An ordinary `IMPORT Commands` automatically keeps that module available while
the importer is loaded. Dynamic lookup does not create such an import edge.
Use a retained command reference when saving a dynamically obtained command:

```oberon
m := SharedModules.ThisMod("Commands");
command := SharedModules.AcquireCommand(m, "Run");
IF command # NIL THEN
  SharedModules.Invoke(command);
  SharedModules.ReleaseCommand(command)
END;
```

Declare `command` as `SharedModules.CommandRef`. The reference holds its owning
module until explicitly released; copying it does not create another lease.
Releasing through any copy disables invocation through all copies. The shell
uses this interface and releases its command reference after normal completion
or command-stop cleanup.

For a procedure value, static-data address or callback retained by native code,
hold a `Modules.Retention` obtained with `Modules.Retain(owner)`. Unregister the
callback, wait until foreign code can no longer use it, clear saved addresses,
then call `Modules.Release(retention)`. Duplicate release is rejected; dropping
a token without releasing it intentionally continues to block unloading.

`Modules.ThisCommand` and `SharedModules.ThisCommand` remain raw lookup interfaces
for compatibility. A stored raw procedure value **must** be covered by a retained
owner. The runtime does not automatically discover arbitrary procedure values,
integer-encoded addresses, or pointers hidden in foreign storage. Bypassing this
cooperative contract with `SYSTEM` or native code can still cause invalid calls.
Native threads and asynchronous callbacks are not made safe automatically.

Oberon programs may call `Modules.Free(name, FALSE)` or
`ModuleLoader.Free(name, FALSE)`; results are in `Modules.res`/`resMsg` and
`ModuleLoader.res`/`resMsg`. `all = TRUE` additionally attempts unused imports
recursively, leaving shared or protected imports loaded. Runtime unload hooks
retain their own owners until explicitly unregistered. A destructive cleanup
failure in a recursively freed import is reported even if the requested root
was already freed; restart before attempting to load it again.
The loader's runtime notifier is permanent. A free-handler registration retains
its owner until replaced or removed with `Modules.InstallFreeHandler(NIL)`.

## Finding modules and their imports

By default, the loader searches the current directory and the directory of
`libvoc-ModuleLoader-O2.so`. An application host also searches beside its
executable for the main module. Keep the application library beside the host
when distributing a program.

`VOC_MODULE_PATH` supplies a colon-separated module search path. In `hresh`,
`-Ppath` or `-P path` replaces that path. For example:

```sh
hresh -P./modules:/opt/oberon/modules Commands.Run
```

Symbol files are searched in the module directories, then in `VOC_SYM_PATH`,
or the installation's modular symbol directory when that variable is unset.
`VOCROOT` may select a different installation root.

Finding a requested module and finding its imports are separate operations.
The VOC loader finds the requested `.so`; the operating system's dynamic
linker finds the libraries named by that file's dependencies. Generated
libraries record a search path containing their own directory (`$ORIGIN`) and
the modular runtime directory. Imports elsewhere need an appropriate runtime
search path or `LD_LIBRARY_PATH`. The shell's `-P` option does not change the
dynamic linker's search rules.

At compilation time, VOC searches the current directory, `VOC_MODULE_PATH`,
and `VOCLIBDIR` for modular libraries. `OBERON` and `MODULES` select symbol
search directories. With an installed modular runtime, the modular compiler
options select its headers, symbols and libraries automatically. Ordinary
compilation continues to select the conventional runtime.

## Building the bundled libraries

The modular profile is optional. From a compiler checkout, an installed VOC
can be used to build it on Linux with GNU make and GCC, Clang or TCC:

```sh
make modular-library hresh
```

The library build includes the runtime, V4, unified oo2c, Ulm, POW, misc, S3 and
the supported portable and libc-backed networking ports. It does not require
X11, Cairo or raylib development packages.

Build those bindings separately, after installing their native development
packages. On Debian, these are `libx11-dev`, `libcairo2-dev`, `libraylib-dev`
and `pkg-config` (availability depends on the Debian release):

```sh
make modular-library-bindings
```

Use `WITH_X11=0`, `WITH_CAIRO=0` or `WITH_RAYLIB=0` to omit a family from this
bindings target. For example,
`make modular-library-bindings WITH_X11=0 WITH_RAYLIB=0` builds only Cairo.
These switches do not add bindings to the base
`modular-library` target. The two profiles have separate `libraries.list` and
`bindings.list` manifests. Games and demonstrations remain source-only.

The full profile uses the default Oberon-2 type sizes (`MODEL=2`). Some older
bundled libraries depend on those sizes. The smaller runtime and shell profile
can also be built with `MODEL=C` or `MODEL=V`; use a separate application build
directory for each type model.

The build leaves its compiler in `build/hresh/compiler/voc`, libraries and
development files in `build/hresh/modules/2`, and the shell in `build/hresh/hresh`.
It does not replace installed tools. To compile against this local build,
use its compiler and point `VOCLIBDIR` and `OBERON` at its module directory.
For example, from the checkout root:

```sh
export VOCROOT=/usr/share/voc
export VOCLIBDIR="$(pwd)/build/hresh/modules/2"
export OBERON="$VOCLIBDIR"
build/hresh/compiler/voc -smd /path/to/Main.Mod
```

Use the `VOCROOT` of the bootstrap installation if it differs from
`/usr/share/voc`. `VOC`, `VOCROOT`, `VOCLIBDIR`, `CC`, `MODEL` and `BUILD` may
also be supplied to the make targets when choosing another installation or
build directory.

The [bundled-library examples](../src/examples/shared-libraries/readme.md) have
their own makefile. The following targets exercise the libraries, shell and
loading hosts:

```sh
make modular-library-test hresh-test hresh-demo
# Optional: also check the selected bindings without opening a display.
make modular-library-bindings-test
```

The binding checks are independent of the base-library suite and do not start
games or graphical demos. The opt-in profile regression also verifies that
building/staging bindings does not change the base manifest or rebuild base
libraries; it needs a fresh output directory:

```sh
python3 src/test/hresh/test-library-profiles.py --build /path/to/fresh-build
```

## Installing and linking libraries

Modular development files are kept separate from conventional ones. With an
installation under `/usr`, their usual locations are:

| Files | Location |
| --- | --- |
| Module headers | `/usr/share/voc/modular/2/include` |
| Symbol files | `/usr/share/voc/modular/2/sym` |
| Module libraries and the minimal core | `/usr/lib/voc/modular/2` or `/usr/lib64/voc/modular/2` |

`install-modular` in `src/tools/hresh/Makefile` installs the base library files.
`install-modular-bindings` additionally installs the selected bindings and
their separate `bindings.list` manifest. Neither target removes previously
installed files when a family is disabled; package managers should track the
two manifests when replacing an existing installation.
`INSTALL_ROOT` and `INSTALL_LIBDIR` select the data and library directories;
`DESTDIR` supplies a staging prefix for package builds. The static minimal-core
archive is included for building `-mD` hosts. It does not replace the
conventional static runtime.

Module libraries do not link a private core. The host supplies the common
runtime, either through the shared core or by exporting its embedded core.
`SYSTEM`, `PlatformNative`, `Platform`, `Heap` and `Modules` therefore cannot be built as separate
module libraries. The library name `core` is reserved for the runtime.

Module search, ABI validation, ELF inspection, native ownership records and
archive-path checks are implemented in Oberon. `NativeModules` provides the
thin dynamic-loader bindings; `PlatformNative` isolates native directory and
terminal types and calls. POSIX signal recovery stays in `SYSTEM.c`: its
`sigsetjmp` frame must remain alive until the command returns. Cleanup policy
and callbacks remain in Oberon.

The compiler honours `CC`, `CFLAGS`, `LDFLAGS` and `LDLIBS` for native builds.
`VOC_RUNPATH` may replace the recorded runtime search path when packaging
libraries. Installed files should name installation directories, not temporary
build directories.

## Loading modules from an Oberon program

`Modules.ThisMod` looks for a module which has already been initialised.
To load a module on demand, use `ModuleLoader.ThisMod` instead. It returns the
registered module, or `NIL` on failure; `ModuleLoader.resMsg` describes a loading
error. `SharedModules` adds command discovery and command lookup for clients
such as `hresh`.

Loading a module uses the system's `dlopen` and `dlsym` operations. Its
initialiser registers the module, its commands and its garbage-collection
roots. Imported procedures are then called directly, as in other compiled
Oberon programs; they are not looked up by name for every call.

The loader checks the module's data layout against the host, including pointer
and basic-type sizes, the module-registry layout and runtime-core ownership.
The registry pin, procedure ownership, cancellable-command support, import
ownership and active-call tracking are part of core ABI profile 3. Rebuild the modular
core and all module libraries together; libraries from a different profile are
rejected before their Oberon initializer is called. This is not a complete
interface-version check. Build the host and its modules for the same
architecture, type model, runtime and exported interfaces. Imported libraries
must also match; their descriptors are not checked recursively. Unrelated
Ofront shared libraries do not satisfy this loading contract.

## Present limits

Native module loading currently uses ELF Unix libraries. Linux builds are
supported; BSD execution has not yet been verified. Windows DLLs and macOS
dynamic libraries are not supported by this loader.

Module and command names may contain up to 63 characters in the modular
runtime. The conventional runtime retains its original registry layout and
name limits.

Libraries remain mapped until explicitly and successfully freed or process exit.
Only checked Linux/glibc unloading is supported; the permanent core and
startup-linked dependencies cannot be replaced in a running process. Modules
without independent native ownership cannot be freed. Rebuild the complete
modular profile together rather than mixing libraries from different builds.

Commands run with the host's permissions and share its address space. A HALT,
failed assertion or fault terminates the host. Load only trusted modules.
The shell does not provide Unix pipelines, job control or process isolation.

The supplied `Texts` and `Oberon` modules are headless. Module loading does not
provide a graphical Oberon environment, and a graphical module cannot replace
their interfaces with incompatible declarations of the same names.
