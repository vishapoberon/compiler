# VOC 4.0.2 release validation

VOC translates Oberon-2 into C and builds programs with a native C compiler.
The 4.0.2 release was checked on x86-64 Gentoo Linux on 25 October 2026 with
GCC 14.3.1, Clang 22.1.8 and TCC 0.9.28rc.

## Conventional compiler and libraries

Clean builds from the bundled bootstrap C sources passed with all three C
compilers, including the model-2 library, Component Pascal type-model runtime
and terminal libraries, and the full confidence suite:

```sh
make CC=clang WITH_NETWORK=0
make CC=tcc WITH_NETWORK=0
make CC=gcc
```

The GCC build also passed the default Linux networking profile, including
36 TLS test programs and local TLS/HTTP regressions. The checkout compiler and
`install/bin/voc` both report version 4.0.2. The conventional `make xml` target
also passed with the rebuilt checkout compiler.

These commands create a local `install/` image. System installation remains a
separate operation.

## Terminal editor

`none.Open` is the editor's single exported command. The same source builds the
standalone `none file` executable. The conventional installation image includes
`install/bin/none`, and modular builds include both the loadable module and a
standalone executable using the modular runtime.

Pseudo-terminal tests check loading without starting an editing session,
command discovery, editing and saving plain files with spaces in their names,
preserving LF/CRLF bytes, storing and reopening Oberon texts, usage errors,
non-terminal input, and restoring terminal settings after normal exit.

To test the conventional executable using the local compiler image:

```sh
make none-test VOC="$PWD/install/bin/voc" VOCROOT="$PWD/install"
```

## Shared modules and XML

The model-2 modular runtime, hosted tools, checked unloading/recompilation,
archive commands and all 222 bundled shared-library ABI/load checks passed with
the networking profile disabled:

```sh
make -f src/tools/hresh/Makefile test test-tools test-library \
  VOC="$PWD/install/bin/voc" VOCROOT="$PWD/install" \
  VOCLIBDIR="$PWD/install/lib" \
  BUILD="$PWD/build/release-modular" WITH_NETWORK=0
```

The XML suite passed using the rebuilt local compiler:

```sh
make -C src/ports/xml test conformance limits fuzz \
  VOC="$PWD/install/bin/voc" VOCROOT="$PWD/install" \
  BUILD="$PWD/build/release-xml"
```

Coverage includes 13 XML programs, seven shared-support programs, 114 original
codec vectors in full and bounded output configurations, 77 URI fixtures,
2,687 conformance/output checks, 53 hostile-input checks and 2,655 deterministic
mutation checks. Fixture exclusions and historical expectation corrections are
recorded in [XML conformance](../src/ports/xml/doc/Conformance.md).

## Sanitizers and remaining platform checks

The compiler and hosted-tool modules, including loadable and standalone `none`,
passed the tool tests with Clang ASan/UBSan instrumentation. The conventional
standalone editor also passed ASan/UBSan checks. Conservative GC stack scanning
uses an uninstrumented core runtime: ASan otherwise reports intentional scanning
of stack redzones. Leak checking and stack-use-after-return checking were
disabled, with UBSan configured to halt on errors.

Signed integer-limit regression assertions cover the minimum and maximum of
all four fixed-width integer sizes. The 64-bit maximum calculation avoids the
overflowing signed intermediate detected during sanitizer testing.

Native Windows and other host platforms have not been validated for this
release. XML continues to require trusted input while broader adversarial review
is pending; see [XML security](../src/ports/xml/doc/Security.md).
