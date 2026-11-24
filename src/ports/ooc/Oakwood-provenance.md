# Oakwood modules from oo2c

`OakOut` provides basic formatted standard output, and `OakStrings` provides
zero-terminated string manipulation. Both originate in the `lib` directory of
the oo2c 1.5.9 source distribution and retain their LGPL-2.0-or-later notices.

| Source | CVS revision | SHA-256 of original source |
| --- | --- | --- |
| `lib/OakOut.Mod` | 1.4, 1999-09-02, Michael van Acken | `32e48721a0a45c81a4c9e3d4f1f8b9b8a7897d6bbdc7c1a9cae19cd3582a63e4` |
| `lib/OakStrings.Mod` | 1.3, 1999-10-03, ooc-devel | `005f8ca6559dfb03069a2768e831e43794fe52ab8644f66fb3365b4fd18838d2` |

## Port adaptations

- `OakOut` uses standard Oberon-2 module and parameter declarations.
- Its string dependency is imported as `Strings := oocStrings`.
- Standard output uses VOC's existing `Out` module, flushing after every
  operation and preserving the explicit `Open` initialization contract.
- Numeric conversion uses the original `RealStr` and `LRealStr` algorithms.
  LONGREAL exponents are padded to three digits, including single-digit
  nonzero exponents.
- `LowLReal` reads and modifies IEEE exponent and fraction fields through
  32-bit `SET` words, preserving conversion behavior with 64-bit `LONGINT`.
- `OakStrings.Extract` limits the copied length to `LEN(dst)-1`, preserving
  the terminating zero when the requested length equals the destination size.
- `OakStrings.Cap` and the shared `oocStrings.Capitalize` convert only ASCII
  lowercase letters, preserving punctuation, digits and high-bit bytes.

`TestOakStrings.mod` exercises all exported string operations.
`TestOakNumbers.mod` checks the low-level LONGREAL operations and real-to-string
conversions independently of output capture.
`TestOakOut.mod` and `tests/check-oakout.py` cover initialization, repeated
opening, character and string output, integer limits, field widths, mantissa
trimming and exponent padding in both VOC type models.
