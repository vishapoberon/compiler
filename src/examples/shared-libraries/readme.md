# Using libraries in shared modules

These two programs use VOC's `oocStrings`, `IntStr`, `Math` and `Out` libraries:

- `LibraryDemo.Mod` exports `Run` and `Echo` commands for `hresh`.
- `LibraryMain.Mod` imports the same libraries directly. Its executable host
  loads the application `.so` at runtime, without a shell.

## Build and run

You need ELF Unix, GNU make and a GCC-compatible C compiler.

From the compiler repository root:

```sh
make
make -C src/examples/shared-libraries test
make -C src/examples/shared-libraries shell
```

The example Makefile builds a modular compiler in `build/hresh/compiler/voc`
and libraries in `build/hresh/modules/2`. The example's own output goes to
`build/examples/shared-libraries/2`. Set `HRESH_BUILD` or `BUILD` to change
these locations, and `VOCROOT` to use another VOC build.

Inside the shell:

```text
> LibraryDemo
  LibraryDemo.Echo
  LibraryDemo.Run
> LibraryDemo.Run
NATIVE MODULES
sqrt(16) = 4
integer = 42
calls: 1
> LibraryDemo.Run
NATIVE MODULES
sqrt(16) = 4
integer = 42
calls: 2
> LibraryDemo.Echo hello world
hello world
> quit
```

Tab completes module and command names. Notice that the call count increases:
the module keeps its state between commands in the same shell.

## Standalone host

```sh
make -C src/examples/shared-libraries standalone
build/examples/shared-libraries/2/LibraryMain
ldd build/examples/shared-libraries/2/LibraryMain
```

The program prints the results and `standalone library demo passed`.
The executable is a small host built with `-md`. It loads
`libvoc-LibraryMain-O2.so` after starting; that library in turn depends on
`oocStrings`, `IntStr`, `Math` and `Out`. This is why `ldd` on the executable
lists the loader and core runtime, but not those application libraries.

To embed the minimal VOC core while keeping libc and modules shared:

```sh
make -C src/examples/shared-libraries run-standalone HOST_MODE=mD
ldd build/examples/shared-libraries/2/LibraryMain
```

With `-mD`, the core is linked into the executable, so `ldd` no longer lists
`libvoc-core-O2.so`. The application modules and libc are still shared.

## Changing the application

After editing the application or adding an import, rebuild only its library:

```sh
make -C src/examples/shared-libraries application
build/examples/shared-libraries/2/LibraryMain
```

The executable does not need rebuilding. Keep the application `.so` beside it
and restart the program to load the new version. In `hresh`, `system.Free`
can unload modules when they are no longer in use; see
[module unloading](../../../doc/SharedModules.md#checked-unloading-and-rebuilding).

See [Shared modules](../../../doc/SharedModules.md) for compiler options and
loading rules, and [A gentle introduction to shared modules](../../../doc/ModuleTutorial.md)
for examples using an installed compiler and shell.
