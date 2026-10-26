# Punycode and internationalized host names

Native Oberon-2 modules for RFC 3492 Punycode, Unicode NFC and checked UTF-8
DNS host names. XMPP and the `agena` Gemini server use the same domain-name
preparation. The modules use the VOC runtime and need no additional libraries.

## Build and test

From a VOC checkout with a matching compiler/runtime installation:

```sh
make -C src/ports/punycode test VOC="$PWD/install/bin/voc"
make -C src/ports/punycode conformance VOC="$PWD/install/bin/voc"
```

`MODEL`, `BUILD`, `CC` and `CFLAGS` can be overridden. The modules are also
included in normal VOC library builds. The isolated tests support models `2`
and `C`. The conformance target uses Python 3.14's Unicode 16.0 tables,
bundled fixtures and pinned reference code; it performs no network access.

For the scalar codec alone, compile `Punycode.Mod`; it has no module imports.
For checked host names, compile `Punycode`, `IDNAMapping`, `IDNAData`,
`UnicodeNFC` and `IDNA` in that order. Retain the license and data notices when
redistributing these sources.

## Host names

```oberon
IMPORT IDNA;
VAR unicode, ascii: IDNA.String; result: LONGINT;

IDNA.Names("ԾՈՑ.ՀԱՅ", unicode, ascii, result);
(* result = 0, unicode^ = "ծոց.հայ", ascii^ = "xn--cbbu1a.xn--y9a3aq" *)
```

The input is a zero-terminated UTF-8 DNS host name. On success, both outputs
are newly allocated, zero-terminated byte arrays. On failure they are `NIL`
and `result = IDNA.invalidName`.

The preparation policy is:

- Strict UTF-8 decoding and Unicode 16.0 non-transitional UTS #46 mapping.
  Case, width and recognized dot variants are mapped; sharp-s remains sharp-s.
- NFC normalization and IDNA2008 validity, including ContextJ and ContextO.
- RFC 5893 bidirectional checks across every label in a bidi domain.
- Canonical A-label decoding and re-encoding, including NFC and context checks.
- DNS label syntax, 63-byte A-label and 253-byte complete-name limits.
- A 1,023-byte input limit and bounded 4,096-scalar preparation buffers.
- Rejection of empty labels, trailing root dots, controls and address delimiters.
  Full-width delimiters must also pass validation after mapping.

Use the Unicode output for application identities and the ASCII output for
DNS lookup, TLS SNI and certificate matching. Username and resource preparation
are handled by their calling protocols.

## Scalar codec and NFC

`Punycode.Encode(input, count, output, written, result)` accepts Unicode scalar
values in a `LONGINT` array and produces ASCII bytes. `Decode(input, length,
output, count, result)` reverses the operation. Counts and lengths are explicit;
the scalar codec permits ASCII controls as basic values, so callers must use
the returned lengths. `IDNA` supplies the host-name validation above.

The codec accepts at most 1,024 scalars. It checks arithmetic, scalar ranges
and destination capacity. Results are `done`, `invalid`, `noRoom` or `overflow`.
On failure the returned output count is zero; encoding also clears the first
destination byte when available. Decoding publishes the destination only on
success. It never replaces a malformed value or truncates a successful result.

`UnicodeNFC.Normalize(input, count, output, written, ok)` normalizes at most
4,096 scalar values. It reports invalid scalars, preparation-buffer exhaustion
and undersized destinations through `ok = FALSE`, with `written = 0`.

## Data and coverage

`IDNAMapping` and `IDNAData` are generated Oberon constant tables. Regenerate
them with `python3 src/ports/punycode/tools/generate.py`, using Python 3.14
(Unicode 16.0.0). The generator checks the pinned source hashes first.

The conformance target checks 47,844 cases: all 6,389 Unicode 16.0 IDNA fixtures,
2,531 additional domain/UTF-8 cases, 38 RFC 3492 sample encode/decode checks,
2,716 Punycode differential cases and 36,170 NFC comparisons. Of the nominally
valid UTS #46 fixtures, 160 are rejected by the stricter host-name profile:
IDNA2008 validity, ContextO checks and the root-dot/address-delimiter policy.
Every fixture is checked; `vectors/profile-rejections.json` records these cases
under the build directory.
The 38 existing IDNA regressions also pass. GCC/C23, Clang/C23, TCC and Clang
ASan/UBSan pass these checks on x86-64 Linux.

The encoder comes from Norayr Chilingarian's `agena`, with decoding and checked
bounds added here. It retains agena's GPL version 3 license in `LICENSE`.
Unicode/IDNA data and the Python test reference have their notices in
`NOTICE`, `NOTICE-IDNA` and `NOTICE-UNICODE`.
