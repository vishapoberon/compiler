# A gentle introduction to shared modules

## Background

This introduction is for readers who have written a small Oberon program and
would like to use modules as independently compiled components. We shall
build a command module, use it in `hresh`, and
then build an application which runs without that shell.

The examples use VOC's own `Out` and `oocStrings` libraries. You will need a VOC
installation with the modular runtime and `hresh`. The commands below assume
that `voc` and `hresh` are on your operating system's search path. Module loading
currently uses ELF Unix shared libraries; the examples have been tested on
Linux.

For the complete set of options and loading rules, see
[Shared modules and hresh](SharedModules.md).

## Modules as components

A module defines a component with an interface and an implementation. An
exported declaration belongs to the interface; other declarations remain
private. In Oberon, an asterisk after a declaration's name
marks it as exported.

When a module imports `Out`, it declares that it uses the interface of `Out`.
The compiler checks calls such as `Out.String` against that interface.
The modules are compiled separately, using symbol files to describe their
interfaces.

A shared library is one way to keep the compiled implementation separate too.
With VOC, a module named `Commands` can be supplied as
`libvoc-Commands-O2.so`. Its symbol file, `Commands.sym`, describes the exported
interface. The library contains the code which will run when the module is
loaded.

## First look at hresh

`hresh` is the Hosted Runtime Extensible Shell for Oberon commands. Start it at
your Unix shell prompt:

```sh
hresh
```

Inside `hresh`, type the name of a bundled module:

```text
> LowReal
  LowReal.ClearError
```

Typing a module name lists its commands. To call the procedure shown above,
type:

```text
> LowReal.ClearError
```

This command has no output. We shall write another command shortly so that its
effect is visible. Notice the notation `Module.Command`: it identifies both
the component and the procedure to call.

Listing a module reads its symbol file without loading its code or running its
initialisation. Calling a command loads the library if necessary.

Type `quit` to return to the Unix shell:

```text
> quit
```

`hresh` calls Oberon procedures; commands such as `voc`, `mkdir` and `ldd`
belong to the Unix shell. In the transcripts below, `>` denotes the `hresh`
prompt. Type the text following it.

## A command module

Choose a directory for the examples:

```sh
mkdir -p ~/voc-loading-test
cd ~/voc-loading-test
```

Save the following source in a file named `Commands.Mod`:

```oberon
MODULE Commands;
  IMPORT Out, oocStrings;
  VAR calls: LONGINT;

  PROCEDURE Run*;
    VAR text: ARRAY 64 OF CHAR;
  BEGIN
    text := "loaded";
    oocStrings.Capitalize(text);
    INC(calls);
    Out.String(text); Out.String(" calls: ");
    Out.Int(calls, 0); Out.Ln
  END Run;
END Commands.
```

`Commands` imports two components. `oocStrings` supplies string operations and
`Out` writes to standard output. The call to `Capitalize` changes the letters
in `text` to capitals; the following output procedures print that text and a
number.

The asterisk in `Run*` exports the procedure. `Run` has no formal parameters
and no result, so it can be called as a command. The variable `calls` has no
asterisk, so it remains private to the module.

Compile the module at the Unix shell prompt:

```sh
voc -sl Commands.Mod
```

The `-l` option builds a module library. The `-s` option
allows a previous symbol file to be replaced if we change the interface. The
compiler produces `Commands.sym`, `Commands.h`, `Commands.c`, and
`libvoc-Commands-O2.so`. `O2` denotes the default Oberon-2 type model.

Start `hresh` from this directory and ask it to use the component:

```sh
hresh
```

```text
> Commands
  Commands.Run
> Commands.Run
LOADED calls: 1
> Commands.Run
LOADED calls: 2
```

Try typing `Commands.R` and pressing Tab. The shell completes the command name
from the symbol file. Completion and listing read that interface; the first
command call initialises the library.

Why does the second call print `2`? `calls` is a module variable. The module
remains loaded between commands, and both calls use the same variable. The
local `text` array is prepared afresh for each call.

Exit and start `hresh` again. The first call now prints `1`: this is a new
process with a new instance of the module's state.

It is also possible to run a command directly from the Unix shell:

```sh
hresh Commands.Run
```

Each such invocation starts a separate process. To call the command twice in
one process without an interactive prompt, use:

```sh
printf 'Commands.Run\nCommands.Run\n' | hresh
```

The output is again `LOADED calls: 1` followed by `LOADED calls: 2`.

## An application without hresh

The command shell is only one possible host for shared modules. An application
may import the same libraries and call their procedures in the usual way.

Leave `hresh` with `quit` if it is still running. In the same example directory,
save this program as `Main.Mod`:

```oberon
MODULE Main;
  IMPORT Out, oocStrings;
  VAR text: ARRAY 64 OF CHAR;
BEGIN
  text := "native";
  oocStrings.Capitalize(text);
  oocStrings.Append(" MODULES", text);
  Out.String(text); Out.Ln
END Main.
```

Unlike `Commands`, this module has no exported command procedure. Its work is
in the module body, between the final `BEGIN` and `END Main`. That body is the
entry point of the application.

Compile and run it:

```sh
voc -smd Main.Mod
./Main
```

The output is:

```text
NATIVE MODULES
```

The compiler produces an executable named `Main` and a library named
`libvoc-Main-O2.so`. The executable starts the runtime and loads the main module.
The main module imports `Out` and `oocStrings`, so their
libraries are made available as well. The executable runs directly from the
Unix shell.

## Module initialisation and the common runtime

Imported modules are initialised before the module which uses them. Each
module's initialisation runs once in a process. This gives a library a place
to prepare its private state before a caller uses its exported procedures.

For `Main`, the imported libraries are ready before the module body executes.
For `Commands`, they are ready before the first call to `Run`. Later commands
use the initialised module and its retained state.

The modules also share a common runtime. Its small core contains `SYSTEM`,
`Platform`, `Heap` and `Modules`. All loaded modules use this runtime and its
single heap.

On Linux, inspect the executable's shared dependencies with:

```sh
ldd ./Main
```

You should find `libvoc-ModuleLoader-O2.so`, `libvoc-core-O2.so` and libc.
The host opens `libvoc-Main-O2.so`, `libvoc-Out-O2.so` and
`libvoc-oocStrings-O2.so` later, through the module loader.

There is another choice for the common core:

```sh
voc -smD Main.Mod
./Main
ldd ./Main
```

The output of `Main` is unchanged, but `libvoc-core-O2.so` disappears from the
dependency list. Uppercase `D` places the minimal core inside the executable
and makes its procedures available to loaded libraries. The loader, application
libraries and libc remain shared dependencies.

Thus `-md` and `-mD` choose where the common core lives. Both use the same
Oberon source and `IMPORT` statements.

## Changing the implementation

A useful consequence of separating the host from the application is that we
can change the implementation without rebuilding the host.

First record the executable's checksum:

```sh
sha256sum Main > host.sha256
```

In `Main.Mod`, change the assignment to:

```oberon
  text := "updated";
```

Now compile only the application library:

```sh
voc -sl Main.Mod
sha256sum -c host.sha256
./Main
```

The checksum check reports `Main: OK`, and the program prints:

```text
UPDATED MODULES
```

The executable keeps its checksum. It loads the new implementation when it next
runs. Adding an import also requires only an application-library rebuild,
provided the imported library is available. If we change an exported interface,
we may also need to recompile the modules which use that interface.

Restart `hresh` or the application after rebuilding a library so the new
process loads the updated implementation.

## Further examples

The bundled compression commands can also be called from hresh:

```text
> gzip.Compress sample.txt
> gzip.Decompress sample.txt.gz restored.txt
> zip.Add samples.zip sample.txt restored.txt
> zip.Directory samples.zip
> zip.Extract samples.zip sample.txt
```

The input files are kept. Quote names containing spaces. `Zip` is the library;
`zip` is the command module, so the optional native profile needs a
case-sensitive filesystem. Use a trusted extraction directory: these commands
share the host's permissions. See the
[release notes](ReleaseNotes-4.0.md#libraries) for format and update limitations.

The sources used here are available in
[`src/examples/module-tutorial`](../src/examples/module-tutorial). That directory's
makefile can compile and run them against this checkout's compiler and libraries:

```sh
make -C src/examples/module-tutorial test
```

The [bundled-library examples](../src/examples/shared-libraries/readme.md) also use
`IntStr` and `Math`, and show how a command reads its argument text through
`Oberon.Par`.

As an exercise, add `Math` to the imports of `Main` and print the square root
of `16.0`. Rebuild the library with `-l` and verify that the executable's checksum
is unchanged. The compiler and system loader use the new import and discover
its library through the module's dependencies.

Ordinary `-m` and `-M` compilation remains available. Shared-module loading is
an additional way to organise a program.
