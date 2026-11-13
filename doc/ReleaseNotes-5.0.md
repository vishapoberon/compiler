# Vishap Oberon 5.0 — release preview

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.0 adds
experimental Oberon-V array statements with sequential, multicore CPU and
GPU execution. It also brings together the networking, text, image and
development tools added during the 4.0 series.

## Independent calculations on CPU cores and GPUs

An `ALL` statement describes assignments which can be carried out
independently. Each iteration works on its own array element. For example:

```oberon
ALL i = 0 .. LEN(values)-1 WITH t: REAL DO
  t := values[i] * factor;
  values[i] := t
END
```

The bounds are inclusive. `WITH` gives each iteration a private temporary.
The programmer is responsible for keeping iterations independent, including
when parameters refer to the same storage.

Choose an execution mode when compiling:

| Options | Execution |
| --- | --- |
| `-j` | Sequential array assignments |
| `-jP` | OpenMP execution across CPU threads |
| `-jG` | Synchronous OpenMP target execution on a GPU |

For a main program, add `-m`. CPU OpenMP uses a compatible C compiler and
runtime; `OMP_NUM_THREADS=4` requests four CPU threads. GPU execution needs
an offload compiler, a device runtime and a supported driver. `CC`,
`VOC_OPENMP_CFLAGS` and `VOC_OPENMP_LDFLAGS` select that toolchain.

The direct GPU backend accepts one-dimensional numerical arrays, scalar
captures and private scalar temporaries. It checks supported array bounds
on the calling thread before launching the device calculation. More complex
array views, multidimensional iteration and reductions remain future work.

Start with [A gentle introduction to GPU programming](GPUTutorial.md),
which builds an array example, uses a separately compiled module and
explains the tested AMD setup. The
[numerical examples](../src/examples/language/gpu/readme.md) include checks
and reproducible benchmarks.

### HALD colour conversion

The [HaldClut library](../src/ports/norayr/hald-clut/readme.md) applies a
three-dimensional colour lookup table to RGBA pixels. Its Oberon source
defines the interpolation and public interface. A dedicated, source-checked
generated-C backend supplies the GPU kernel for this indirect-lookup
algorithm. Importing applications call `HaldClut.Apply` in every build.

The [HaldCmd example](../src/examples/utilities/hald/readme.md) reads a JPEG
or PNG photograph, applies a HALD PNG and writes the result. It includes
sequential, CPU OpenMP and GPU builds, pixel-reference tests and a conversion
benchmark. Integer rounding and source alpha are preserved.

### Published measurements

[CPU and GPU measurements](ParallelBenchmarks.md) gives the hardware,
compiler settings, methods and complete tables. CPU results cover one
sequential thread and four or sixteen OpenMP threads on a Ryzen 9 9950X.
GPU results cover its integrated Radeon (`gfx1036`) and a Radeon RX 5600 XT
(`gfx1010`), using optimized Clang 19 offloading.

The multicore CPU was fastest on the numerical-array tests. For HALD, the
RX 5600 XT took 1.597 ms at 1080p, 4.978 ms for a 3264×2448 photograph and
5.175 ms at 4K. These conversion times include device transfers. They give
1.9–2.3× the speed of the best tested sixteen-thread CPU control using the
same streamlined interpolation kernel. Image reading and writing are
outside the timed conversion.

## IRC and its client example

The [IRC client library](../src/ports/norayr/irc/README.md) provides parsed
message callbacks, registration, CAP negotiation, SASL authentication,
bounded outgoing queues and reconnect handling. `IRCTCP` supplies TCP
transport; `IRCTLS` supplies verified TLS 1.3 through the bundled Oberon TLS
library. These modules are included in the Linux model-2 networking profile.

The [vocbot IRC client example](../src/examples/network/irc-bot/readme.md)
joins a channel, keeps a message log and answers private `help`, `last n`
and `search [n] pattern` commands. Replies are paced while incoming traffic
continues to be processed. On restart, it restores its history from the log.

After building VOC on Linux:

```sh
make -C src/examples/network/irc-bot
make -C src/examples/network/irc-bot test
```

The example's README explains server selection, TLS, credentials and log
storage. Tests use local peers and synthetic credentials.

## Further additions from the 4.0 series

### XML, Unicode and Internet names

The [XML library](../src/ports/xml/README.md) supplies parsing, DTD
validation, namespace-aware builders, writing and incremental stream
framing. oo2c string and channel interfaces provide UTF-16 text and encoding
support. [Punycode and IDNA preparation](../src/ports/punycode/README.md)
add Unicode NFC normalization and checked internationalized host names.
Use trusted XML while broader security validation remains pending.

### XMPP clients and publishing

The [XMPP library](../src/ports/xmpp/README.md) supports Unicode JIDs,
TLS/SASL sessions, IQ request handling, presence, rosters, PubSub/PEP and
multi-user chat. It includes bounded room tracking, legacy account
registration and negotiated file sending and reception through in-band
bytestreams. SOCKS5 negotiation and a nonblocking TCP connector provide
foundations for a future SOCKS5 file-transfer adapter.

[Caller-driven connections](../src/ports/xmpp/doc/AsyncClient.md) let an
event loop advance connection setup and established I/O. DNS lookup and
certificate verification retain synchronous work. The
[publishing example](../src/examples/network/xmpp-publish/readme.md)
demonstrates PEP/Atom microblog publication and retrieval.

### Images and memory files

[Polpo's native Oberon codecs](../src/ports/polpo/README.md) read and write
PNG, JPEG and GIF. Bounded memory APIs work with encoded data in arrays;
`Files` provides fixed-capacity and growable memory files. Limits cover
pixel counts and encoded output sizes, and applications should also budget
for decoder workspace and pixel buffers.

### Editing and development tools

The `none` terminal editor runs as a standalone application and as
`none.Open` inside `hresh`. The
[shared-module tutorial](ModuleTutorial.md) introduces command modules,
module state and independently replaceable application libraries.
`hresh` supplies command history, completion, a compiler command and a
definition browser. PICL and Coco/R sources are also included.

### Compiler, runtime and platforms

The release includes corrected numeric scanning and decimal conversion,
ETH-compatible `Out.Hex`, unsigned minimum-width `Out.HexDigits`, memory-file
support, and installation-path fixes. Windows status buffers and install
discovery have been corrected. FreeBSD and NetBSD builds received header,
linking and test-runner fixes during the 4.0 series.

The [4.0 release history](ReleaseNotes-4.0.md) records the individual updates
and their platform coverage.

## Building and upgrading

Run `make` to build the compiler and conventional libraries and run the
confidence tests. Unix builds leave a local installation image in `install/`.
See [installation](Installation.md) for dependencies and system installation.

Rebuild symbol files, generated C and libraries with the new compiler. Keep
the modular core and its module libraries from the same build together.
The modular-linking option is now `-L`; `-l` builds an individual module
library. GPU objects must use a matching C compiler, target architecture,
type model and offload runtime throughout compilation and linking.

Shared-module loading is tested on Linux ELF, with checked unloading on
glibc. The conventional compiler also has Windows, BSD and macOS platform
implementations. The platform summaries in the 4.0 history describe earlier
tests; the 5.0 validation summary below lists the fresh release checks.

The IRC and XMPP transports inherit the bundled TLS library's security
limits: its arithmetic has variable timing, and independent cryptographic
validation remains pending. Packages under `src/ports` carry their own
licence terms and source records; consult those before redistribution.

## Release validation

Fresh GCC and Clang builds pass the confidence tests on 64-bit Linux.
All five bootstrap source sets are regenerated. CPU OpenMP, shared modules,
`hresh`, IRC, XMPP, image codecs and the packaged examples pass their release
checks. A staged `/opt/voc` installation built with Clang runs the tutorial's
three execution modes using the installed compiler's default backend.

Optimized AMD device tests use Clang 19 with mandatory offloading and an
execution-location probe.
Both AMD GPUs pass the numerical and HALD checks, including all seven
full-photo LUT comparisons. HALD CPU controls also pass in type models 2
and C.

Optimized GCC 14 offloading on `gfx1036` remains affected by
`HSA_STATUS_ERROR_INVALID_ISA`, reproduced in standalone C. GCC `-O0`
passes; Clang 19 is the validated optimized AMD path.
