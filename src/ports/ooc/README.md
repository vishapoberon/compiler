# oo2c support for VOC

This package provides oo2c-compatible strings, diagnostics, channels, file and
memory I/O, numeric conversions and riders. It is built as part of VOC's
standard library in both the Oberon-2 and Component Pascal type models.

## Unicode strings and messages

`oocUnicode.LONGCHAR` represents one UTF-16 code unit in the range 0..65535.
It uses `LONGINT` storage so VOC's Oberon-2 model preserves the unsigned
16-bit range. Supplementary characters use surrogate pairs. Positions and
lengths count code units, independently of the storage width.

`LongStrings` copies, edits and searches these strings. `Equal8` compares
UTF-16 code units with Latin-1 bytes without narrowing. `Msg.GetLText`
preserves their code units in diagnostic attributes and expanded templates;
`Msg.GetText` converts to Latin-1 with replacement for unrepresentable units.
`Channel`, `TextRider` and `oocFiles` widen their narrow error templates
explicitly. `IOMemory` provides growable, seekable memory files using the
same channel interfaces.

Applications and libraries, including XML, import these shared modules from
the ooc package. When updating `Msg.LChar`, rebuild the ooc package and its
users together because this changes exported array element types.

## Building and testing

At the VOC repository root, `make` builds the libraries and runs confidence
tests. `make ooc` rebuilds the ooc modules in the Oberon-2 build directory.
`make confidence` runs the installed-image tests. The library tests cover
Unicode strings and messages, memory channels, file diagnostics, text and
binary riders, and command-line channels. `make modular-library-test` also
checks the shared-library build.

For an isolated rebuild and the seven ooc regression programs, use an installed
VOC compiler with matching runtime libraries:

```sh
make -C src/ports/ooc test
```

This creates `build/ports/ooc/2`. Override `VOC`, `BUILD`, `CC` or `CFLAGS`
as needed. XML can use this directory's symbol files, headers and objects
directly while testing from source.
The isolated build forces local symbol files so executables link these rebuilt
objects even when installed modules have identical interfaces.

`IntConv` and `IntStr` scan decimal input using `LONGINT` positions. Numeric
tests include 70,000-character leading-zero and whitespace sequences, trailing
invalid characters and the full signed integer range. Conversion failures leave
the caller's value unchanged.

## URI references

`URIParser` parses RFC 2396 URI references and resolves relative paths.
The `URI` types expose components, cloning and serialization. `URIString`
and `URICharClass` use `LONGINT` byte offsets for the Oberon-2 model.
`URISchemeFile`, `URISchemeMemory` and `URISchemeMailTo` register their
schemes when imported. File channels use `oocFiles` and `FilesHost`;
memory channels use `IOMemory`.

File access accepts local authorities (empty host or `localhost`) and
checks path capacity before opening. URI parsing rejects `%00`, since
decoded components use zero-terminated strings. `URISchemeFile.ToURI`
escapes file names, including relative names containing spaces or URI
delimiters. Source provenance is recorded in [URI-provenance.md](URI-provenance.md).

`TestOocURI` covers RFC relative-resolution examples, percent escapes,
malformed input, cloning, 40,000-byte URIs, and file/memory channels.
Character-class checks use explicit ASCII ranges so high-bit UTF-8 bytes
remain percent-escaped under VOC's `CAP` semantics.

The isolated `test` target also replays all 77 preserved ooc-libxml URI
fixtures: 50 parsing/resolution cases, nine malformed references and 18
absolute-to-relative conversions. Positive cases compare component traces and
serialized references byte-for-byte. The runner records two historical output
corrections: query-only references preserve the base path, and escaped dot
segments retain their escapes when serialized. Its test-only HTTP prototype
exercises server-based authorities and queries using the shared component
parsers. These fixture checks perform no network access.

## Optional internationalized DNS names

`IDNA.Names(input, unicodeName, asciiName, result)` accepts a zero-terminated
UTF-8 domain name and returns both its canonical UTF-8 U-labels and ASCII
A-labels. It uses libidn2's non-transitional UTS #46 mapping, normalization
and IDNA2008 validation. The module additionally checks DNS label syntax,
the 63-byte label limit and the 253-byte name limit. Input is limited to
1,023 bytes. Trailing root dots and address delimiters are rejected.

On success `result = 0` and both outputs are Oberon-owned arrays. On failure
both outputs are `NIL`; `result` is a libidn2 error or `IDNA.invalidName`.
The interface always uses UTF-8, independently of the process locale.
Mapped punctuation is checked before acceptance, including full-width address
delimiters, so malformed input cannot silently lose those delimiters.

Build and test this optional module with libidn2 development files and
`pkg-config` installed:

```sh
make -C src/ports/ooc test-idna VOC="$PWD/install/bin/voc"
```

The normal ooc build retains its existing dependencies. Programs using `IDNA`
link with `LDLIBS="$(pkg-config --libs libidn2)"`; `IDNA_CFLAGS`, `IDNA_LIBS`
and `PKG_CONFIG` can be overridden for the isolated target. Its 38 checks cover
Armenian domains, A-label round trips, case/NFC mapping, non-transitional sharp-s,
Chinese labels, invalid UTF-8, contextual/bidirectional rules and bounded input.

## Source provenance

The Unicode-safe support implementations and their regression tests were
ported and tested in
[voc-ooc-xml, commit 083e443](https://github.com/norayr/voc-ooc-xml/tree/083e443).
The following paths identify the source before its transfer into this package:

| Module | Source path |
| --- | --- |
| `oocUnicode` | `src/XML/Unicode.Mod`, previously named `XMLUnicode` |
| `LongStrings` | `src/oo2c/LongStrings.Mod` |
| `Msg` | `src/oo2c/Msg.Mod` |
| `Channel` | `src/oo2c/Channel.Mod` |
| `IOMemory` | `src/IO/Memory.Mod` |

The unchanged oo2c support baselines came from
[Spirit-of-Oberon/oo2c, commit ff5627208e1489b5dd0a0ff6c6e135d84b06a703](https://github.com/Spirit-of-Oberon/oo2c/tree/ff5627208e1489b5dd0a0ff6c6e135d84b06a703/lib/src).
Their revision and checksum records remain in
[the XML repository's support provenance](https://github.com/norayr/voc-ooc-xml/blob/083e443/history/oo2c-support.md).
`IOMemory` originated in the preserved ooc-libxml CVS history. Original
copyright and licence notices remain in each source file.
