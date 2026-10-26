MODULE TestPunycode;
IMPORT Punycode, UnicodeNFC, Out;
VAR scalars, decoded: ARRAY 1024 OF LONGINT; bytes: ARRAY 4096 OF CHAR;
  written, count, result, i: LONGINT; ok: BOOLEAN;
  small: ARRAY 2 OF CHAR; smallScalars: ARRAY 2 OF LONGINT;
  single: ARRAY 1 OF CHAR; large: ARRAY 4097 OF LONGINT;

PROCEDURE Case(text: ARRAY OF CHAR; count: LONGINT);
  VAR j: LONGINT;
BEGIN
  Punycode.Encode(scalars, count, bytes, written, result);
  ASSERT(result = 0); ASSERT(bytes = text);
  Punycode.Decode(bytes, written, decoded, written, result);
  ASSERT((result = 0) & (written = count));
  FOR j := 0 TO count-1 DO ASSERT(decoded[j] = scalars[j]) END
END Case;

BEGIN
  Case("", 0);
  scalars[0] := ORD("a"); scalars[1] := ORD("b"); scalars[2] := ORD("c"); Case("abc-", 3);
  scalars[0] := 0E9H; Case("9ca", 1);
  scalars[0] := 56EH; scalars[1] := 578H; scalars[2] := 581H; Case("cbbu1a", 3);
  scalars[0] := 1F600H; Case("e28h", 1);
  FOR i := 0 TO 1023 DO scalars[i] := 10FFFFH END;
  Punycode.Encode(scalars, 1024, bytes, written, result); ASSERT(result = 0);
  Punycode.Decode(bytes, written, decoded, count, result); ASSERT((result = 0) & (count = 1024));
  Punycode.Decode("999999999999999999999999999999999999", 36, decoded, count, result); ASSERT((result # 0) & (count = 0));
  scalars[0] := 0D800H; Punycode.Encode(scalars, 1, bytes, written, result); ASSERT((result # 0) & (written = 0));
  scalars[0] := ORD("e"); scalars[1] := 301H;
  UnicodeNFC.Normalize(scalars, 2, decoded, count, ok); ASSERT(ok & (count = 1) & (decoded[0] = 0E9H));
  scalars[0] := 1100H; scalars[1] := 1161H; scalars[2] := 11A8H;
  UnicodeNFC.Normalize(scalars, 3, decoded, count, ok); ASSERT(ok & (count = 1) & (decoded[0] = 0AC01H));
  scalars[0] := ORD("a"); scalars[1] := ORD("b"); scalars[2] := ORD("c");
  Punycode.Encode(scalars, -1, bytes, written, result); ASSERT((result = Punycode.invalid) & (written = 0) & (bytes[0] = 0X));
  Punycode.Encode(scalars, 1025, bytes, written, result); ASSERT((result = Punycode.invalid) & (written = 0));
  Punycode.Encode(scalars, 3, small, written, result); ASSERT((result = Punycode.noRoom) & (written = 0) & (small[0] = 0X));
  Punycode.Encode(scalars, 0, single, written, result); ASSERT((result = 0) & (written = 0) & (single[0] = 0X));
  Punycode.Encode(scalars, 1, single, written, result); ASSERT((result = Punycode.noRoom) & (written = 0));
  Punycode.Decode("abc-", 4, smallScalars, count, result); ASSERT((result = Punycode.noRoom) & (count = 0));
  Punycode.Decode("a", 2, decoded, count, result); ASSERT((result = Punycode.invalid) & (count = 0));
  Punycode.Decode("a", -1, decoded, count, result); ASSERT((result = Punycode.invalid) & (count = 0));
  Punycode.Decode("a!", 2, decoded, count, result); ASSERT((result = Punycode.invalid) & (count = 0));
  Punycode.Decode("9CA", 3, decoded, count, result); ASSERT((result = 0) & (count = 1) & (decoded[0] = 0E9H));
  scalars[0] := -1; Punycode.Encode(scalars, 1, bytes, written, result); ASSERT((result = Punycode.invalid) & (written = 0));
  scalars[0] := 110000H; Punycode.Encode(scalars, 1, bytes, written, result); ASSERT((result = Punycode.invalid) & (written = 0));
  UnicodeNFC.Normalize(scalars, 1, decoded, count, ok); ASSERT(~ok & (count = 0));
  UnicodeNFC.Normalize(scalars, -1, decoded, count, ok); ASSERT(~ok & (count = 0));
  FOR i := 0 TO 4096 DO large[i] := ORD("a") END;
  UnicodeNFC.Normalize(large, 4097, large, count, ok); ASSERT(~ok & (count = 0));
  UnicodeNFC.Normalize(large, 4096, large, count, ok); ASSERT(ok & (count = 4096));
  FOR i := 0 TO 4095 DO large[i] := 0AC01H END;
  UnicodeNFC.Normalize(large, 4096, large, count, ok); ASSERT(~ok & (count = 0));
  scalars[0] := ORD("a"); scalars[1] := ORD("b"); scalars[2] := ORD("c");
  smallScalars[0] := -123;
  UnicodeNFC.Normalize(scalars, 3, smallScalars, count, ok); ASSERT(~ok & (count = 0) & (smallScalars[0] = -123));
  Out.String("Punycode and Unicode NFC checks passed"); Out.Ln
END TestPunycode.
