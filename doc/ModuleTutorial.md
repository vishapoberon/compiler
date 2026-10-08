# A gentle introduction to shared modules

## Background

This introduction is for readers who have written a small Oberon program and
would like to use modules as independently compiled components. It is not an
Oberon language manual. We shall build a command module, use it in `vish`, and
then build an application which runs without that shell.

The examples use VOC's own `Out` and `oocStrings` libraries. You will need a VOC
installation with the modular runtime and `vish`. The commands below assume
that `voc` and `vish` are on your operating system's search path. Module loading
currently uses ELF Unix shared libraries; the examples have been tested on
Linux.

For the complete set of options and loading rules, see
[Shared modules and vish](SharedModules.md).

## Modules as components

A module defines a component with an interface and an implementation. An
exported declaration belongs to the interface; declarations which are not
exported remain private. In Oberon, an asterisk after a declaration's name
marks it as exported.

When a module imports `Out`, it declares that it uses the interface of `Out`.
The compiler checks calls such as `Out.String` against that interface. An
`IMPORT` statement does not copy the text of `Out` into the importing source
file. The modules are compiled separately.

A shared library is one way to keep the compiled implementation separate too.
With VOC, a module named `Commands` can be supplied as
`libvoc-Commands-O2.so`. Its symbol file, `Commands.sym`, describes the exported
interface. The library contains the code which will run when the module is
loaded.

## First look at vish

`vish` is a shell for Oberon commands. Start it at your Unix shell prompt:

```sh
vish
```

Inside `vish`, type the name of a bundled module:

```text
> oocLowReal
  oocLowReal.ClearError
```

Typing a module name lists its commands. To call the procedure shown above,
type:

```text
> oocLowReal.ClearError
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

The distinction between the two shells is important. `vish` calls Oberon
procedures; commands such as `voc`, `mkdir` and `ldd` belong to the Unix shell.
In the transcripts below, `>` denotes the `vish` prompt and should not be typed.

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
and no result, so it can be called as a command. The variable `calls` is
private to the module. It is not exported merely because an exported procedure
uses it.

Compile the module at the Unix shell prompt:

```sh
voc -sl Commands.Mod
```

The `-l` option builds a module library, not an executable. The `-s` option
allows a previous symbol file to be replaced if we change the interface. The
compiler produces `Commands.sym`, `Commands.h`, `Commands.c`, and
`libvoc-Commands-O2.so`. `O2` denotes the default Oberon-2 type model.

There is no executable named `Commands` to run. Instead, start `vish` from this
directory and ask it to use the component:

```sh
vish
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
from the symbol file. The library is not initialised merely by completing or
listing its commands.

Why does the second call print `2`? `calls` is a module variable, not a local
variable of `Run`. The module remains loaded between commands, and both calls
use the same variable. By contrast, the local `text` array is prepared afresh
for each call.

Exit and start `vish` again. The first call now prints `1`: this is a new
process with a new instance of the module's state.

It is also possible to run a command directly from the Unix shell:

```sh
vish Commands.Run
```

Each such invocation starts a separate process. To call the command twice in
one process without an interactive prompt, use:

```sh
printf 'Commands.Run\nCommands.Run\n' | vish
```

The output is again `LOADED calls: 1` followed by `LOADED calls: 2`.

## An application without vish

The command shell is only one possible host for shared modules. An application
may import the same libraries and call their procedures in the usual way.

Leave `vish` with `quit` if it is still running. In the same example directory,
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

The compiler produces two important files: an executable named `Main` and a
library named `libvoc-Main-O2.so`. The executable starts the runtime and loads
the main module. The main module imports `Out` and `oocStrings`, so their
libraries are made available as well. Neither building nor running this
application requires `vish`.

## Module initialisation and the common runtime

Imported modules are initialised before the module which uses them. Each
module's initialisation runs once in a process. This gives a library a place
to prepare its private state before a caller uses its exported procedures.

For `Main`, the imported libraries are ready before the module body executes.
For `Commands`, they are ready before the first call to `Run`. Later commands
do not repeat the initialisation. This is why a module can retain state across
calls without requiring the caller to initialise it repeatedly.

The modules also share a common runtime. Its small core contains `SYSTEM`,
`Platform`, `Heap` and `Modules`. In particular, all modules use one heap;
loading a new library does not create another independent Oberon runtime.

On Linux, inspect the executable's shared dependencies with:

```sh
ldd ./Main
```

You should find `libvoc-ModuleLoader-O2.so`, `libvoc-core-O2.so` and libc. You
should not find `libvoc-Main-O2.so`, `libvoc-Out-O2.so` or
`libvoc-oocStrings-O2.so` in this list. These are not startup dependencies of
the host. They are loaded when the host opens the main module.

There is another choice for the common core:

```sh
voc -smD Main.Mod
./Main
ldd ./Main
```

The output of `Main` is unchanged, but `libvoc-core-O2.so` disappears from the
dependency list. Uppercase `D` places the minimal core inside the executable
and makes its procedures available to loaded libraries. The loader, application
libraries and libc are still shared. This is not a fully static program.

Thus `-md` and `-mD` choose where the common core lives; they do not change the
Oberon source or its `IMPORT` statements.

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

The executable has not changed. It loads the new implementation when it next
runs. Adding an import also requires only an application-library rebuild,
provided the imported library is available. If we change an exported interface,
we may also need to recompile the modules which use that interface.

This does not replace a module inside a running process. Restart `vish` or the
application after rebuilding a library.

## Further examples

The sources used here are available in
[`src/test/module-tutorial`](../src/test/module-tutorial). That directory's
makefile can compile and run them against an installed modular VOC:

```sh
make -C src/test/module-tutorial test
```

The [bundled-library examples](../src/test/shared-libraries/README.md) also use
`ooc2IntStr` and `Math`, and show how a command reads its argument text through
`Oberon.Par`.

As an exercise, add `Math` to the imports of `Main` and print the square root
of `16.0`. Rebuild the library with `-l` and verify that the executable's checksum
is unchanged. The compiler and system loader use the new import; the host does
not need a separate list of application libraries.

Ordinary `-m` and `-M` compilation remains available. Shared-module loading is
an additional way to organise a program, not a different Oberon language.
