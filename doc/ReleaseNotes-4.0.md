# Vishap Oberon 4.0

## 4.0.3

The Oberon-2 library now includes native XMPP modules for UTF-8 XML streams,
session negotiation, messages, presence and explicit subscriptions. Bounded
per-resource presence tracking, correlated IQ requests, ping, software version,
service discovery, rosters and PubSub/PEP operations provide reusable client
interfaces. The Linux transport supports verified STARTTLS and direct TLS;
SASL PLAIN requires explicit opt-in after TLS verification. See the
[XMPP library](../src/ports/xmpp/README.md) for APIs and examples.

The [microblog publisher](../src/examples/network/xmpp-publish/readme.md)
publishes escaped UTF-8 Atom entries through XMPP. Its reusable interfaces
support caller-selected item IDs and exact-item retrieval to verify stored
text. Configuration and credentials stay in a local file or environment;
publication has no automatic retry.

Shared native Oberon modules provide bounded Punycode, Unicode NFC and
IDNA2008/Unicode 16.0 non-transitional UTS #46 host-name preparation. XMPP and
the `agena` Gemini server use the same implementation. Unicode identities stay
in XML while checked ASCII host names are used for DNS and TLS. See
[host-name preparation](../src/ports/punycode/README.md) for the policy and
47,844-case conformance suite.

The XML library adds a bounded, byte-fed element-stream interface with
namespace context, restart handling and explicit input-consumption results.
Namespace validation accepts relative URI names such as `vcard-temp` in memory
documents without fetching or replacing them. Existing parser and builder
interfaces remain available; see [XML streams](../src/ports/xml/doc/Streaming.md).

Automatic XMPP SRV discovery, SCRAM and complete username/resource preparation
remain pending. The XMPP and publisher packages record unresolved upstream
licensing; review their source records before redistribution. Continue using
trusted XML while broader adversarial review remains pending.

See [release validation](ReleaseValidation-4.0.3.md) for reproducible commands,
coverage and platform limitations.

## 4.0.2

The terminal editor is renamed from `xxs` to `none`, with the single exported
command `none.Open`; the `Fit` alias has been removed.
It also builds independently as `none file`: run `make none` with an installed
VOC compiler. Full Unix builds include the executable in `install/bin/`.

The bundled Oberon-2 library now includes the native Oberon XML parser, DTD
validator, namespace processing, writer and canonical output, together with
shared Unicode codecs and URI support. Additive limited constructors provide
resource budgets for parser and built-in builder work. Continue using trusted
XML while broader adversarial review remains pending; see
[XML security](../src/ports/xml/doc/Security.md) and
[conformance coverage](../src/ports/xml/doc/Conformance.md).

Shared oo2c support now includes Unicode code-unit types, long strings, channels,
diagnostics, memory files and URI component parsers. Regression coverage includes
the preserved codec, URI and XML fixtures, bounded hostile inputs and deterministic
XML mutations.

The compiler's signed integer-limit calculation now avoids an overflowing
intermediate when determining the 64-bit maximum.

Clean GCC, Clang and TCC builds pass the confidence suite on Linux x86-64;
the editor also has pseudo-terminal and sanitizer coverage. See
[release validation](ReleaseValidation-4.0.2.md) for commands, coverage and
remaining platform checks.

## 4.0.1

The Linux modular library profile now includes Norayr's `pipes` and `xattr`
modules, using the bundled runtime libraries instead of separate packages.

Vishap Oberon 4.0 adds shared Oberon modules and `hresh`, a command shell
where modules keep their state between calls. Programs can also load shared
modules without using the shell. VOC still translates Oberon-2 to C; normal
`-m` and `-M` compilation works as before.

## hresh and shared modules

`hresh` provides line editing, command history, and completion of command and
file names. It includes a compiler (`compiler.Compile`), definition browser
(`browser.ShowDef`) and text editor (`none.Open`). The editor supports selection,
block editing, search, copy/paste, and plain or rich text.

Modules can be unloaded, edited and recompiled without restarting the shell:

```text
> system.Free Commands
> none.Open Commands.Mod
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
