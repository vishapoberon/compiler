# XML for VOC

This package provides Michael van Acken's ooc-libxml 3.2.0 XML parser, DTD
validator, namespace builders, Unicode codecs and XML writer for VOC's
Oberon-2 (`-O2`) model. It also provides canonical output, callback traces and
application-object construction through the Basic element interfaces.
`XMLStream` supplies bounded, byte-fed element streams with retained namespace
context and exact event boundaries for long-lived protocols such as XMPP.

## Building and testing

VOC's model-2 library and modular-library builds include these modules after
the shared ooc package. With an installed VOC compiler and matching runtime,
build and test this package from the VOC repository root:

```sh
make -C src/ports/xml test conformance limits fuzz
```

The isolated build rebuilds the shared ooc dependencies in
`build/ports/xml/2`, forces local symbol/object selection and runs both packages'
regression programs. Override `VOC`, `BUILD`, `CC` or `CFLAGS` as needed.
`make xml` rebuilds XML and its ooc dependencies in the conventional model-2
build directory. `make modular-library` builds the loadable XML modules;
`make modular-library-test` includes XML consumer tests and module loading.

The source-build tests cover 14 XML programs, 114 original codec vectors in
two output-buffer configurations, seven shared ooc programs and 77 original
URI fixtures. Conformance checks cover 2,687 XML, namespace, DTD, protocol and
reference-output cases. The resource suite has 53 process-bounded hostile
inputs; deterministic truncation/mutation testing adds 2,655 invocations.
The element-stream program adds 232 chunk-size runs, 486 malformed-input
mutations, lifetime-budget checks and restart/consumption regressions.
These pass with GCC/C23, Clang/C23, TCC and Clang ASan/UBSan on Linux.
The model-2 modular-library test also passes with networking disabled,
including all bundled module-loading checks and XML consumer programs.
Full compiler-image and native-Windows release validation is tracked
separately from these source-build results.
Use a matching rebuilt compiler and runtime installation, such as VOC 4.0.2,
when testing changes to the shared ooc dependencies.

## Using the library

Import `XMLUnicodeCodecImportAll` to register ASCII, Latin-1, UTF-8 and UTF-16.
Names and character data use `oocUnicode.LONGCHAR`: UTF-16 code units stored
as `LONGINT`, with surrogate pairs for supplementary characters. Positions
and lengths count code units.

Extend `XMLBuilder.BuilderDesc` for parser callbacks and call
`XMLBuilder.Init` when constructing the builder. Create an `XMLLimits` budget
and pass the builder and budget to `XMLParser.NewReaderLimited`,
`NewChannelLimited`, `NewURILimited` or `NewFileLimited`. Configure
`parser.followExternalRef` explicitly before `ParseDocument` and inspect
`parser.errList` before consuming results. Original constructors remain
available with their original unlimited resource behavior.

For namespaces, wrap the application builder with
`XMLBuilderNamespaces.New` and enable `parser.enforceQNames`. For DTD
validation, wrap that builder with `XMLBuilderValidation.New`, set
`parser.validating` and enable external references when needed by the DTD.
Validation precedes namespace transformation in the callback chain.

Use **trusted XML** while the broader adversarial review remains unfinished.
Applications must bound their own resolver, channel and builder behavior.
The limited APIs preserve the existing public constructor signatures and
callbacks while adding parser and built-in builder accounting. See:

- [Input policy and resource limits](doc/Security.md)
- [Conformance coverage and historical fixture corrections](doc/Conformance.md)
- [Writing XML](doc/WritingXML.md)
- [Basic element objects and callback traces](doc/BasicElements.md)
- [Incremental XML element streams](doc/Streaming.md)

`make -C src/ports/xml xmlcheck` builds `build/ports/xml/2/XMLCheck`.
It disables external references by default and accepts `--namespaces`,
`--validate`, `--external`, `--canonical`, `--second` and `--protocol`.
Validation enables external references. Exit codes are 0 for success, 1 for
XML/resource diagnostics and 2 for usage, opening or output errors.

## Source records

The implementation is imported from
[voc-ooc-xml, commit 8d1b5c0](https://github.com/norayr/voc-ooc-xml/tree/8d1b5c0).
That repository preserves the complete CVS ancestry, original branches and
release tags. The 24 implementation files are copied unchanged, with flattened
file paths recorded in [PORT.toml](PORT.toml). The additive `XMLStream` module
is included in that source revision. Reusable strings, Unicode types,
diagnostics, channels, memory files and URI implementations live in
[`../ooc`](../ooc/README.md).

The test runners and XML fixtures retain their standalone layout. The codec
runner reads the preserved original driver from `tests/upstream/TestCodecs.Mod`.
The package Makefile builds the flattened module names; documentation commands
use VOC's repository layout. Original copyright, LGPL and third-party
fixture/archive notices are retained. `COPYING` supplies the GNU LGPL 2.1
text under the source files' version-2-or-later terms. Test attributes retain
the original fixture bytes, including line endings, across checkouts.
