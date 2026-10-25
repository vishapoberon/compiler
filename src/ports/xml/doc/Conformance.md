# XML conformance coverage

Run the bundled fixtures with Python 3.12 or newer and a matching VOC ooc build:

```sh
make -C src/ports/xml conformance
```

The runners extract archives into `BUILD/conformance/`. Source fixtures stay
unchanged. Reports include exclusions, expectation corrections and failures.
Each process has a five-second timeout. A negative fixture must return XML
diagnostics (exit 1); opening errors, traps and sanitizer errors fail the test.

| Checks | Included cases |
| --- | ---: |
| James Clark XML well-formedness | 360 |
| Original namespace well-formedness | 24 |
| James Clark DTD validation | 359 |
| IBM DTD validation | 932 |
| Sun DTD validation | 171 |
| OASIS DTD validation | 346 |
| James Clark canonical output | 163 |
| IBM canonical output | 148 |
| Sun canonical output | 28 |
| Original parser/namespace protocol checks | 30 |
| Original local XML regressions | 124 |
| Original bulk canonical outputs | 2 |

All 2,687 included checks pass, also under Clang ASan/UBSan. The archived DTD
total is 1,808; 339 archive cases compare canonical output byte-for-byte. James Clark
uses the first canonical form; IBM and Sun use the second form, which includes
sorted notation declarations.
The local XML suite adds 70 well-formedness checks and 54 validation checks;
98 local/bulk runs compare canonical output bytes. Protocol checks compare
callback traces and locator positions with 14 original successful snapshots,
including nine namespace snapshots. The other 16 protocol checks require an
XML diagnostic for malformed input. Integration tests also reparse diagnostic
traces produced for malformed input.

## Upstream exclusions

The original test scripts exclude these fixtures. The runners preserve and
report those exclusions:

- James Clark `valid/sa/065.xml`: malformed entity replacement text.
- James Clark `valid/not-sa/022.xml`: improper conditional-section/parameter-
  entity nesting; excluded from validation only.
- IBM `valid/P02/ibm02v01.xml`: encoding errors in the fixture.
- IBM `valid/P58/ibm58v01.xml`: duplicate NOTATION tokens.

Sun fixtures are selected by the archive's four catalog fragments rather than
directory globs, which would also run copies of the catalogs as XML documents.

## Historical expectation corrections

`tests/voc/check-validation.py` records these corrections explicitly:

- IBM `valid/P45/ibm45v01.xml`, `valid/P47/ibm47v01.xml` and Sun
  `valid/optional.xml` contain non-deterministic content models. The validator
  reports the compatibility error specified by XML section 3.2.1, including
  models for element types unused in the document.
- IBM `valid/P57/ibm57v01.xml` and OASIS `p57pass1.xml`, `p58pass1.xml` declare
  NOTATION attributes on EMPTY elements, forbidden by XML section 3.3.1.
- Sun `valid/sa02.xml` and `valid/not-sa02.xml` contain character-reference
  CR/LF in NMTOKENS. These remain after attribute normalization; token
  separators must be spaces, as clarified by Second Edition erratum E20.
  Their reference outputs incorrectly collapse these references. The output
  runner expects `&#13;&#10;` at that attribute position and records the exact
  correction. All other reference bytes must match unchanged.
- Sun `invalid/attr11.xml` and `invalid/attr12.xml` use valid explicit ENTITY
  attributes while leaving semantically invalid defaults unused. Erratum E9
  requires only syntactic correctness for unused defaults.
- Sun `invalid/pe01.xml` contains a literal percent sign in an attribute
  default. Parameter entity references are not expanded there.
- Sun `not-wf/lang01.xml` through `lang06.xml` declare `xml:lang` as CDATA.
  Their language metadata does not impose additional XML well-formedness or
  DTD-validity constraints.
- Local `miscxml/valid/sa/046.xml` declares `((a?,b)|(a?,c))`, and its own
  comment identifies this as non-deterministic. It remains well-formed and its
  canonical output matches; validation must report the XML section 3.2.1
  compatibility error.

## Original driver coverage

The upstream `tests/Makefile` groups codec, URI, archived conformance, local
XML, bulk, protocol and namespace tests. VOC's runners use the preserved
fixtures directly. Negative local fixtures check diagnostic exit status;
their historical error-text snapshots are retained as references. Positive
XML/protocol output is compared byte-for-byte.

| Original driver or suite | VOC coverage and follow-up |
| --- | --- |
| `src/TestParser.Mod` | `tools/XMLCheck.Mod` supplies well-formedness, DTD validation, namespaces, first/second canonical forms and protocol modes. All archived and local XML fixture groups now run in `make conformance`. |
| `src/TestCodecs.Mod`, `tests/codecs` | `make test` replays all 114 original hex-vector cases with full and bounded output buffers, checking exact bytes/code units and error counts. `TestUnicodeCodecs` and `TestMemoryBuffers` add Unicode/range/streaming regressions. |
| `src/TestURI.Mod`, `tests/uri` | VOC's ooc package replays all 77 original parsing, malformed-reference and relative-conversion fixtures, including HTTP authority/query parsing through a test prototype. Its runner documents query-only and escaped-dot historical output corrections. |
| `src/TestGet.Mod`, `src/TestServer.Mod` | Optional HTTP/socket examples depend on the preserved network support modules. Review these with that dependency package. |
| `src/libxml.Mod` | Upstream oo2c library manifest. The VOC `makefile` lists and builds the XML modules against the shared ooc package. |

Specification references: [XML 1.0 Second Edition](https://www.w3.org/TR/2000/REC-xml-20001006/)
and its [errata](https://www.w3.org/XML/xml-V10-2e-errata).
