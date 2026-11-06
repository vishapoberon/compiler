# Hexadecimal output with Out

`Out` provides two hexadecimal output procedures. Both use uppercase letters.

```oberon
PROCEDURE Hex(i: LONGINT);
PROCEDURE HexDigits(x, n: HUGEINT);
```

`Hex` follows ETH Oberon's interface: it writes one blank followed by exactly
eight digits representing the low 32 bits. Negative values use two's complement.
The result remains 32 bits wide in models where `LONGINT` is 64 bits.

| Call | Output |
| --- | --- |
| `Out.Hex(10)` | ` 0000000A` |
| `Out.Hex(255)` | ` 000000FF` |
| `Out.Hex(-1)` | ` FFFFFFFF` |

`HexDigits` writes the unsigned 64-bit representation of `x`, with leading
zeros to a minimum width of `n`. A nonpositive width means eight. It writes all
digits needed by the value, even when the requested width is smaller; negative
values therefore need 16 digits. Widths above 16 add leading zeros.

| Call | Output |
| --- | --- |
| `Out.HexDigits(10, 2)` | `0A` |
| `Out.HexDigits(4096, 2)` | `1000` |
| `Out.HexDigits(10, 0)` | `0000000A` |
| `Out.HexDigits(10, 16)` | `000000000000000A` |
| `Out.HexDigits(-1, 2)` | `FFFFFFFFFFFFFFFF` |

## Updating callers

Replace the former two-argument `Out.Hex(x, n)` calls with
`Out.HexDigits(x, n)`. For byte dumps, use `Out.HexDigits(ORD(byte), 2)`.
Remove any manual single-digit zero padding. A negative width now selects the
default eight digits; use a positive width for fixed-width byte output.

Rebuild the compiler, libraries, dependent programs and shared modules
together: the exported `Out.Hex` signature has changed. The implementation is
Oberon code in `src/library/Out.Mod`.

The output fixture in `src/test/confidence/out` checks both integer size models,
including low-32-bit truncation, negative values, default and large widths,
and the minimum and maximum `HUGEINT` values.
