# VOC 4.0.3 release validation

VOC translates Oberon-2 into C and builds programs with a native C compiler.
The commands below check the compiler, conventional and shared libraries,
terminal tools, XML streams, internationalized host names, XMPP and the
microblog publisher. Run them from a clean checkout of `v4.0.3`.

## Results

On x86-64 Gentoo Linux, GCC 14.3.1, Clang 22.1.8 and TCC 0.9.28rc pass clean
compiler/library builds, the confidence suite, editor tests and all XML,
Punycode/NFC/IDNA, XMPP, publisher and shared TLS suites below. XML/XMPP/publisher
consumers also pass against each conventional installation image.

The GCC shared-module profiles pass the runtime, hosted-tool, editor and library
tests, including 250 ABI/load checks with networking disabled and 299 with it
enabled. Shared-module XMPP passes all 26 local TLS cases; the publisher passes
21 payload/configuration checks, 22 configuration/XML cases and 24 TLS cases
against the same networking profile.

The editor, XML, both Punycode type models, XMPP, publisher and shared TLS
suites also pass Clang ASan/UBSan with the conservative-core and generated-C
function-check exclusions described below.

## Conventional compiler and libraries

Use a separate checkout or worktree for each C compiler:

```sh
make CC=gcc INSTALLDIR="$PWD/install" WITH_NETWORK=1
```

Repeat with `CC=clang` and `CC=tcc`. A full build bootstraps the compiler,
builds the Oberon-2 and Component Pascal type-model libraries, creates a local
`install/` image and runs the confidence suite. The checkout compiler and
`install/bin/voc` must both report version 4.0.3.

Select that image for the source-build tests, including its shared runtime:

```sh
export VOCROOT="$PWD/install"
export VOCLIBDIR="$VOCROOT/lib"
export LD_LIBRARY_PATH="$VOCLIBDIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CC=gcc
export CFLAGS=-std=c23
```

Use `CC=clang` for Clang. For TCC, set `CC=tcc` and unset `CFLAGS`.
These commands build local images; system installation is a separate operation.

## XML and host-name preparation

```sh
make -C src/ports/xml test conformance limits fuzz VOC="$VOCROOT/bin/voc"
make -C src/ports/punycode test conformance VOC="$VOCROOT/bin/voc" MODEL=2
make -C src/ports/punycode test conformance VOC="$VOCROOT/bin/voc" MODEL=C
```

The XML suite includes 14 XML programs, seven shared-support programs,
114 original codec vectors, 77 URI fixtures, 2,687 conformance/output checks,
53 bounded hostile-input checks and 2,655 deterministic mutations. Stream
coverage adds 232 chunk-size runs, 486 malformed-input mutations, namespace
inheritance/isolation, relative namespace names, restarts and consumption limits.

The Punycode/NFC/IDNA suite checks 47,844 cases in each type model, using
bundled Unicode 16.0 fixtures and pinned reference code. It also runs the
existing 38 IDNA conversion/rejection checks. The conformance runner requires
Python 3.14 with Unicode 16.0 tables and performs no network access.

## XMPP and microblog publishing

```sh
make -C src/ports/xmpp test network-test tls-regression VOC="$VOCROOT/bin/voc"
make -C src/ports/norayr/xmpp-publish test network-test VOC="$VOCROOT/bin/voc"
```

Six offline XMPP programs cover XML streams, Unicode stanzas, client
negotiation, peer-checked IQ requests, rosters, PubSub/PEP and presence tracking.
Source checks verify all 88 preserved upstream files. The 26 local Python/OpenSSL
cases exercise verified STARTTLS and direct TLS, Unicode accounts/domains,
messages, subscription stanzas, certificate rejection, spoofed replies,
deadlines and protocol errors. The shared TLS regressions include 36 TLS
programs, HTTP/TLS loopback cases and 40 Gemini checks.

The publisher has 21 payload/configuration checks, 22 configuration/XML cases
and 24 TLS loopback cases, including caller-selected IDs and exact-item
read-back verification. Test accounts and services are synthetic local peers.
The publisher probe is compiled but these commands do not run it against a
public service.

## Shared modules and terminal tools

```sh
make -C src/tools/none test VOC="$VOCROOT/bin/voc"
make -f src/tools/hresh/Makefile test test-tools test-library \
  VOC="$VOCROOT/bin/voc" VOCROOT="$VOCROOT" VOCLIBDIR="$VOCLIBDIR" \
  BUILD="$PWD/build/release-modular-1" WITH_NETWORK=1 CFLAGS=-std=gnu23
make -f src/tools/hresh/Makefile test test-tools test-library \
  VOC="$VOCROOT/bin/voc" VOCROOT="$VOCROOT" VOCLIBDIR="$VOCLIBDIR" \
  BUILD="$PWD/build/release-modular-0" WITH_NETWORK=0 CFLAGS=-std=gnu23
make -C src/examples/network/xmpp-publish native-test \
  VOC="$VOCROOT/bin/voc" VOCROOT="$VOCROOT" VOCLIBDIR="$VOCLIBDIR" \
  HRESH_BUILD="$PWD/build/release-modular-1" \
  BUILD="$PWD/build/release-publisher-native" WITH_NETWORK=1 CFLAGS=-std=gnu23
```

Shared-library checks cover ABI compatibility, loading/unloading, library
consumers, hosted compilation, archives and the loadable and standalone `none`
editor. Pseudo-terminal tests check editing, saving and reopening plain and
Oberon text files, command discovery, errors and terminal-state restoration.
GNU C23 enables the POSIX interfaces used by the Unix library profile.
The publisher's shared-module checks use the same local fixtures as its
conventional build.

## Sanitizers and limitations

Use the uninstrumented Clang compiler/runtime image above and a fresh `BUILD`
directory for each test package. Compile the editor and XML, Punycode, XMPP,
publisher and shared TLS test modules with:

```sh
export CC=clang
export CFLAGS='-std=c23 -fsanitize=address,undefined -fno-sanitize=function -fno-omit-frame-pointer'
export ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0
export UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
```

The conservative core runtime stays uninstrumented because its stack scanner
intentionally reads stack regions that ASan marks as redzones. These checks
therefore instrument the application and library modules rather than that core.
Clang's function-type check is excluded for generated C: it rejects generated
method-dispatch calls involving anonymous open-array pointer types. ASan and
the other enabled undefined-behavior checks remain active; this profile does
not establish function-type sanitizer compatibility for generated method calls.

Native Windows and other host platforms remain unvalidated for this release.
Broader XML and XMPP adversarial review and server interoperability remain
pending. Continue using trusted XML; see [XML security](../src/ports/xml/doc/Security.md)
and [XMPP status](../src/ports/xmpp/doc/PortStatus.md). The source records document
the unresolved original XMPP and publisher licensing.
