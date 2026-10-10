# Bundled-library module loading demo

This example uses VOC's own `oocStrings`, `ooc2IntStr`, `Math` and `Out`
libraries. No external Oberon library checkout is required.

- `LibraryDemo.Mod` exports `Run` and `Echo` commands for `hresh`.
- `LibraryMain.Mod` imports the same libraries directly. Its executable host
  loads the application `.so` at runtime; it does not require `hresh` to run.

## Build and run from the checkout

Requires an installed VOC bootstrap compiler/runtime, GNU make, a GCC-compatible
C compiler and ELF Unix. The full build includes X11 bindings and needs X11
development files; pass `WITH_X11=0` for a headless build.

From the compiler repository root:

```sh
make modular-library
make -C src/test/shared-libraries test
make -C src/test/shared-libraries shell
```

The Makefile builds and explicitly uses `build/hresh/compiler/voc`, leaving the
root and installed compiler binaries untouched. Libraries are built in
`build/hresh/modules/2`; demo files are in `build/tests/shared-libraries/2`.
`BUILD`, `HRESH_BUILD`, `VOC`, `VOCROOT`, `VOCLIBDIR` and `MODEL` can be overridden.

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

Tab discovers commands from `.sym` files without running initializers. State
persists across commands in the same shell. `make hresh-demo` runs both variants
with demo output in `build/hresh/library-demo`.

## Standalone host

```sh
make -C src/test/shared-libraries standalone
build/tests/shared-libraries/2/LibraryMain
ldd build/tests/shared-libraries/2/LibraryMain
```

The program prints the three result lines and `standalone library demo passed`.
With `-md`, `ldd` lists the loader, minimal core and libc, not `oocStrings`,
`ooc2IntStr`, `Math` or `Out`. Those are dependencies of
`libvoc-LibraryMain-O2.so`, which is opened with `dlopen` after the host starts.

To embed the minimal VOC core while keeping libc and modules shared:

```sh
make -C src/test/shared-libraries run-standalone HOST_MODE=mD
ldd build/tests/shared-libraries/2/LibraryMain
```

This time `ldd` no longer lists `libvoc-core-O2.so`. It is not fully static.
`-d` is shorthand for `-md`; the normal `-m`/`-M` modes continue to use the
monolithic shared/static runtime, and `-mP` links module libraries at startup.

After editing the application or adding an import, rebuild only its library:

```sh
make -C src/test/shared-libraries application
build/tests/shared-libraries/2/LibraryMain
```

The existing host is unchanged. Keep the application `.so` beside its host;
matching runtime libraries must remain available. Restart to use rebuilt code:
libraries are not unloaded or replaced in a running process.

See [Shared modules](../../../doc/SharedModules.md) for compiler options and
loading rules, and [A gentle introduction to shared modules](../../../doc/ModuleTutorial.md)
for examples using an installed compiler and shell.
