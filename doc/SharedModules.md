# Shared modules and vish

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
common core contains `SYSTEM`, `Platform`, `Heap` and `Modules`. The remaining
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
also requires the symbol file and header. `vish` uses symbol files to discover
commands in modules that have not yet been loaded.

`-l` cannot be combined with an executable option. `-lc` compiles a modular
object without linking the shared library, and `-lS` produces the translated
C without invoking the C compiler.

## Building an application which loads its main module

An application need not use `vish`. Consider the following main module:

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
application, or leave and restart `vish`, before using a rebuilt library.

## Commands in vish

`vish` executes exported Oberon procedures in its own process. A procedure
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
`vish` is an Oberon command host, not a Unix shell: commands such as `voc` and
`ldd` should be entered at the operating system's shell prompt.

It is also possible to run one command or a sequence of commands without an
interactive prompt:

```sh
vish Commands.Run
printf 'Commands.Run\nCommands.Run\n' | vish
```

A command may read the text following its name through `Oberon.Par.text`,
starting at `Oberon.Par.pos`. This follows the usual Oberon command convention.
Exported procedures with parameters or results remain available to importing
modules, but are not commands in the shell.

## Finding modules and their imports

By default, the loader searches the current directory and the directory of
`libvoc-ModuleLoader-O2.so`. An application host also searches beside its
executable for the main module. Keep the application library beside the host
when distributing a program.

`VOC_MODULE_PATH` supplies a colon-separated module search path. In `vish`,
`-Ppath` or `-P path` replaces that path. For example:

```sh
vish -P./modules:/opt/oberon/modules Commands.Run
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
can be used to build it with GNU make and GCC or Clang:

```sh
make modular-library vish
```

The full library build includes the runtime, V4, OOC, OOC2, Ulm, POW, misc and
S3 libraries. It also builds the three OOC X11 bindings when X11 development
files are available. To omit these bindings, use `WITH_X11=0`.

The full profile uses the default Oberon-2 type sizes (`MODEL=2`). Some older
bundled libraries depend on those sizes. The smaller runtime and shell profile
can also be built with `MODEL=C` or `MODEL=V`; use a separate application build
directory for each type model.

The build leaves its compiler in `build/vish/compiler/voc`, libraries and
development files in `build/vish/modules/2`, and the shell in `build/vish/vish`.
It does not replace installed tools. To compile against this local build,
use its compiler and point `VOCLIBDIR` and `OBERON` at its module directory.
For example, from the checkout root:

```sh
export VOCROOT=/usr/share/voc
export VOCLIBDIR="$(pwd)/build/vish/modules/2"
export OBERON="$VOCLIBDIR"
build/vish/compiler/voc -smd /path/to/Main.Mod
```

Use the `VOCROOT` of the bootstrap installation if it differs from
`/usr/share/voc`. `VOC`, `VOCROOT`, `VOCLIBDIR`, `CC`, `MODEL` and `BUILD` may
also be supplied to the make targets when choosing another installation or
build directory.

The [bundled-library examples](../src/test/shared-libraries/README.md) have
their own makefile. The following targets exercise the libraries, shell and
loading hosts:

```sh
make modular-library-test vish-test vish-demo
```

## Installing and linking libraries

Modular development files are kept separate from conventional ones. With an
installation under `/usr`, their usual locations are:

| Files | Location |
| --- | --- |
| Module headers | `/usr/share/voc/modular/2/include` |
| Symbol files | `/usr/share/voc/modular/2/sym` |
| Module libraries and the minimal core | `/usr/lib/voc/modular/2` or `/usr/lib64/voc/modular/2` |

`install-modular` in `src/tools/vish/Makefile` installs these files.
`INSTALL_ROOT` and `INSTALL_LIBDIR` select the data and library directories;
`DESTDIR` supplies a staging prefix for package builds. The static minimal-core
archive is included for building `-mD` hosts. It does not replace the
conventional static runtime.

Module libraries do not link a private core. The host supplies the common
runtime, either through the shared core or by exporting its embedded core.
`SYSTEM`, `Platform`, `Heap` and `Modules` therefore cannot be built as separate
module libraries. The library name `core` is reserved for the runtime.

The compiler honours `CC`, `CFLAGS`, `LDFLAGS` and `LDLIBS` for native builds.
`VOC_RUNPATH` may replace the recorded runtime search path when packaging
libraries. Installed files should name installation directories, not temporary
build directories.

## Loading modules from an Oberon program

`Modules.ThisMod` looks for a module which has already been initialised.
To load a module on demand, use `ModuleLoader.ThisMod` instead. It returns the
registered module, or `NIL` on failure; `ModuleLoader.resMsg` describes a loading
error. `SharedModules` adds command discovery and command lookup for clients
such as `vish`.

Loading a module uses the system's `dlopen` and `dlsym` operations. Its
initialiser registers the module, its commands and its garbage-collection
roots. Imported procedures are then called directly, as in other compiled
Oberon programs; they are not looked up by name for every call.

The loader checks the module's data layout against the host, including pointer
and basic-type sizes and the module-registry layout. This is not a complete
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

Libraries remain loaded until process exit. A directly loaded module's registry
entry is retained so that its garbage-collection roots cannot be removed while
the code is still in use. There is no unloading or replacement of a module in
a running process.

Commands run with the host's permissions and share its address space. A HALT,
failed assertion or fault terminates the host. Load only trusted modules.
The shell does not provide Unix pipelines, job control or process isolation.

The supplied `Texts` and `Oberon` modules are headless. Module loading does not
provide a graphical Oberon environment, and a graphical module cannot replace
their interfaces with incompatible declarations of the same names.
