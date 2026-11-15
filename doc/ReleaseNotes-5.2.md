# Vishap Oberon 5.2

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.2 adds
Oberon name completion and call-parameter hints to the `none` terminal
editor, both as a standalone executable and as `none.Open` inside `hresh`.

## Completing Oberon names

In `.Mod` and `.mod` files, typing `.` after an imported module or its alias
opens a grey completion list. Exported procedures appear with their
signatures, followed by variables, constants and types. Ctrl-Space can also
list exports for a module which is not imported.

Without a module qualifier, Ctrl-Space offers declarations from the current
text, imported names and predeclared procedures. Local declarations are
collected across scopes. Typing filters the list case-insensitively;
Backspace widens it. Arrow and page keys select an entry, Enter or Tab
accepts it, and Esc closes the popup. Accepting a procedure with parameters
also inserts `(`.

## Call-parameter hints

While entering a call, the editor shows its signature and highlights the
current parameter. Hints cover imported procedures, procedures declared in
the current text and predeclared procedures. Calls continued across lines
retain their parameter context.

## Reading interfaces safely

Export completion reads VOC `.sym` files through the definition browser.
It does not load the corresponding module or run its initializer. Symbol
information is cached until the file is closed; local declarations are
refreshed after edits and remain available without symbol files.

Lookup includes the current and source directories, the `hresh -P` path,
`VOC_SYM_PATH`, `VOC_MODULE_PATH`, `OBERON`, `MODULES`, the current `Files`
search path and the installed symbol directories. Plain text files keep
their normal editing behaviour. See the [editor guide](SharedModules.md#compiler-definition-browser-and-editor)
for the complete controls and path rules.

## Building and upgrading

Run `make` to build the compiler and conventional libraries and run the
confidence suite. The local installation image includes `none` in
`install/bin/`. See [installation](Installation.md) for system installation.

To build and test the standalone editor with an installed compiler:

```sh
make none
make none-test
build/none/none Example.Mod
```

To build and test the hosted editor from the checkout's installation image:

```sh
make hresh
make -f src/tools/hresh/Makefile test-tools
```

The definition browser and its compiler-support modules are included in
both editor builds. Rebuild the editor and its module libraries together
when upgrading. `VOC` selects the compiler, `VOCROOT` selects its data root,
and `CONFIGURATION` selects the standalone browser's configuration module.

The language and parallel-execution features from
[VOC 5.1](ReleaseNotes-5.1.md), including `SUM`, `PROD` and multidimensional
CPU `ALL`, remain available. The [parallel setup guide](GPUSetup.md) covers
GCC and Clang on Debian and Gentoo.

## Validation

Clean GCC, Clang and TCC builds pass the confidence suite on 64-bit Linux.
Standalone and hosted editor checks cover aliases, exported and local
names, filtering, popup navigation, parameter hints, symbol search paths,
edit-cache invalidation, small and wide terminals, and terminal restoration.
A fixture with a failing initializer verifies that completion reads its
interface without executing it. All five bootstrap C source sets are
regenerated; fresh execution tests for this release are limited to Linux.
