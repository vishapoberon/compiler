# Vishap Oberon 4.0

Vishap Oberon 4.0 adds shared Oberon modules and `hresh`, a command shell
where modules keep their state between calls. Programs can also load shared
modules without using the shell. VOC still translates Oberon-2 to C; normal
`-m` and `-M` compilation works as before.

## hresh and shared modules

`hresh` provides line editing, command history, and completion of command and
file names. It includes a compiler (`compiler.Compile`), definition browser
(`browser.ShowDef`) and text editor (`xxs.Open`). The editor supports selection,
block editing, search, copy/paste, and plain or rich text.

Modules can be unloaded, edited and recompiled without restarting the shell:

```text
> system.Free Commands
> xxs.Open Commands.Mod
> compiler.Compile -sl Commands.Mod
> system.ShowCommands Commands
> Commands.Run
```

`system.Free` unloads a module only when no imports, active calls, live typed
objects or retained references depend on it. Code that saves commands or native
callbacks must use the retain/release interface; the runtime cannot track
arbitrary copies of procedure values. See [shared modules](SharedModules.md)
for the loading and unloading rules.

`system.ShowModules` lists loaded modules, `system.ShowCommands` lists their
commands, `system.Directory` lists files, and `system.Collect` runs the garbage
collector. Ctrl-C interrupts a command and returns to the prompt. Commands can
register cleanup callbacks to restore resources when interrupted.

## Compiler and runtime fixes

- The garbage collector finds live pointers held only in callee-saved
  registers, including during module-unloading checks.
- Rows of multidimensional open arrays select the correct elements. Nested
  procedures receive the correct length for each dimension.
- Fixed-array value arguments are checked against the declared parameter
  type. String literals are zero-padded to the parameter size rather than
  copied past the end of the literal.
- Generated C includes the headers needed for exported aliases of imported
  types and avoids clashes with newer C keywords, including C23 keywords.
- Unix output handles short and interrupted writes. Unix file timestamps are
  converted through the host's `time_t` type, fixing date errors where its size
  differs from Oberon's `LONGINT`.
- `Files.ReadString` and `Files.ReadLine` respect destination bounds and
  consume the rest of an overlong record before the next read.
- `Texts.Scan` handles long numerals and large exponents without overrunning
  its buffers or overflowing while checking input. `Texts.WriteString` handles
  strings longer than 32767 characters. Left shifts use unsigned C operands
  where needed to avoid undefined behaviour on negative values.
- Decimal real constants avoid repeated intermediate rounding. Generated
  constants preserve their values when read back; `Out.Real` and `Out.LongReal`
  handle rounding that carries into the exponent.
- Sign and range-reduction errors in `Math` and `MathL` have been fixed, along
  with scaling, rounding and square-root errors in the oo2c real libraries.
- Directory-stream offsets use the host's address size in both type models.

## Libraries

The model-2 library adds `StringBase64`, `bdStrings` (Bron-Dijkstra strings),
`strutils`, `List`/`StringList`, the `opts` command-line parser and a permissive
`TOML` reader. It also includes the experimental `Json` parser and printer from
ssqJson. These ports include fixes for bounds checking, linking and argument
handling.

Unix builds include the `Kbd` keyboard and mouse decoder in the model-2
library. It reads terminal escape sequences without terminfo or termcap;
applications handle terminal setup and cleanup. `LineEditor`, `termios` and
`UnixTermios` are available in both conventional type models as well as the
modular runtime. The sts-q editor modules and utilities are in
[`src/examples/libraries/sts-q/editor`](../src/examples/libraries/sts-q/editor/readme.md).

Linux networking libraries provide TCP/IP, HTTP/HTTPS, TLS 1.3 and Gemini.
Source examples include `fetch`, the DCS Gemini/Spartan client, Agena (a Gemini
server) and Cobweb (an HTTP/HTTPS server).

The oo2c libraries are now under `src/ports/ooc`. Most modules now
use short names such as `IntStr`. `oocFiles`, `oocStrings` and `oocRandomNumbers`
keep their prefixes to avoid clashes. Integer/string conversions handle the
full 32-bit and 64-bit `LONGINT` range, including the minimum negative value.

Most Ulm and ETH System 3 modules also use unprefixed names. Conflicting
interfaces keep their prefixes, including `ethSets`, `ethStrings` and
`ethReals`. `RandomNumbers` is ETH's implementation; `oocRandomNumbers` is oo2c's.
Ulm Unix file and terminal streams now connect to the host platform.

Polpo's archive commands are available in `hresh`:

- `gzip.Compress`, `gzip.Decompress`
- `zip.Directory`, `zip.Add`, `zip.Extract`, `zip.Delete`

Decompression and extraction validate temporary output before replacing the
target files. ZIP additions update the archive in place. ZIP64, encryption and
concatenated gzip members are not supported.

ETH's `BIT` and `DES` modules are in `src/ports/s3`.

Norayr Chilingarian's libraries are LGPL v3 and his programs are GPL v3.
Third-party code has its own licence terms. In particular, sts-q's `Json` and
`Kbd` are GPL v3 without VOC's runtime exception. See the licence files in each
package.

## Examples and source directories

Libraries from other projects are grouped by author or collection under
`src/ports`, with source revisions and porting changes in `PORT.toml`.
Ofront's `Args` and `Console` are in `src/library`; the Unix terminal modules
are in `src/library/terminal`.

Programs are in `src/examples`, including games, GUI demos, servers and teaching
examples. New examples demonstrate Carlos Une's Cairo, IPv4 and astronomy
modules, and include Tigran Martirosyan's raylib-based Snake game, Odzik.

Build an example after building VOC at the repository root:

```sh
make -C src/examples/network/ip
make -C src/examples/network/ip run ARGS='1.2.3.4/22'
```

Example Makefiles use the compiler and libraries in `install/` and put output
under `build/examples`. Examples are built separately from the compiler.
See the [examples index](../src/examples/readme.md) for dependencies and usage.

## Building and upgrading

`make` builds the conventional compiler and libraries and runs the confidence
tests. Unix installations support separate binary, data and library
directories, with `DESTDIR` for package staging.

For shared modules and shell tools, use `make modular-library` after `make`.
X11, Cairo and raylib bindings are built separately with
`make modular-library-bindings`; see their
[development-package requirements](../src/ports/readme.md#graphics-bindings).

The full library collection uses the default Oberon-2 type model. Minimal
modular runtimes also support the C and V type models. Conventional libraries
are combined in `libvoc-O2.a` and the platform's shared library; the modular
build produces a library for each module, such as `libvoc-strUtils-O2.so`.

When upgrading:

- Rebuild the modular core and all module libraries together. Do not mix them
  with the conventional combined runtime in one process.
- Update old oo2c imports: use `IntStr` instead of `oocIntStr` or `ooc2IntStr`,
  for example. The forwarding modules are no longer supplied. Rebuild symbol
  files, generated C and libraries together.
- Check fixed-array value arguments. They must have the declared parameter
  type. Use an open-array parameter to accept arrays of different lengths.
  String constants are still accepted and safely padded. Ordinary array
  assignment rules have not changed.

See the [module tutorial](ModuleTutorial.md) for a first shared-module program
and [Shared modules and hresh](SharedModules.md) for compiler options and
loading rules.

## Platforms and limitations

Shared modules target ELF Unix. Checked unloading works on Linux with glibc;
on musl, libraries remain mapped. The loader has not been verified on BSD and
does not support Windows DLLs or macOS dynamic libraries. Conventional
compilation does not have these loader restrictions.

The runtime core and dependencies linked at startup cannot be replaced in a
running process. If cleanup fails or the native loader keeps an old module
image, the affected module is disabled and the host must be restarted.

Commands share the host's address space and permissions. Load only trusted
modules. HALT, failed assertions and faults still terminate the host. `hresh`
has no Unix pipelines, job control or process isolation.

## Acknowledgments

Thanks to [T. Kurt Bond (@tkurtbond)](https://github.com/tkurtbond) for reporting
compiler and library bugs, providing reproducing examples and proposing fixes
for this release.
