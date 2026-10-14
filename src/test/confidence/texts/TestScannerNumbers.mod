MODULE TestScannerNumbers;
  IMPORT SYSTEM, Texts, Out;
  VAR text: Texts.Text; writer: Texts.Writer; scanner: Texts.Scanner;
    number, reference: ARRAY 50032 OF CHAR; formatted: ARRAY 128 OF CHAR;
    seed, bits64: SYSTEM.INT64; bits32: SYSTEM.INT32;
    source: REAL; sourceL: LONGREAL; count: LONGINT;

  PROCEDURE -IncludeStdlib '#include <stdlib.h>';
  PROCEDURE -IncludeStdio '#include <stdio.h>';
  PROCEDURE -Real(text: ARRAY OF CHAR): REAL 'strtof((const char*)text, 0)';
  PROCEDURE -LongReal(text: ARRAY OF CHAR): LONGREAL 'strtod((const char*)text, 0)';
  PROCEDURE -FormatReal(value: REAL; VAR text: ARRAY OF CHAR)
    'snprintf((char*)text, text__len, "%.9e", (double)value)';
  PROCEDURE -FormatLongReal(value: LONGREAL; VAR text: ARRAY OF CHAR)
    'snprintf((char*)text, text__len, "%.17e", value)';

  PROCEDURE Check(value: ARRAY OF CHAR; class: INTEGER; integer: LONGINT);
    VAR i: LONGINT; x: REAL; y: LONGREAL;
  BEGIN
    COPY(value, reference); i := 0;
    WHILE reference[i] # 0X DO
      IF reference[i] = "D" THEN reference[i] := "E" END; INC(i)
    END;
    Texts.OpenWriter(writer); Texts.WriteString(writer, value);
    Texts.WriteString(writer, " next");
    NEW(text); Texts.Open(text, ""); Texts.Append(text, writer.buf);
    Texts.OpenScanner(scanner, text, 0); Texts.Scan(scanner);
    ASSERT(scanner.class = class);
    IF class = Texts.Real THEN
      x := Real(reference); ASSERT(SYSTEM.VAL(SYSTEM.INT32, scanner.x) = SYSTEM.VAL(SYSTEM.INT32, x))
    ELSIF class = Texts.LongReal THEN
      y := LongReal(reference); ASSERT(SYSTEM.VAL(SYSTEM.INT64, scanner.y) = SYSTEM.VAL(SYSTEM.INT64, y))
    ELSIF class = Texts.Int THEN ASSERT(scanner.i = integer)
    END;
    Texts.Scan(scanner); ASSERT((scanner.class = Texts.Name) & (scanner.s = "next"));
    Texts.Scan(scanner); ASSERT((scanner.class = Texts.Char) & (scanner.c = 0X))
  END Check;

  PROCEDURE Repeat(prefix: ARRAY OF CHAR; repeated: CHAR; n: LONGINT; suffix: ARRAY OF CHAR);
    VAR i, j: LONGINT;
  BEGIN
    COPY(prefix, number); i := 0; WHILE number[i] # 0X DO INC(i) END;
    FOR j := 1 TO n DO number[i] := repeated; INC(i) END;
    j := 0; REPEAT number[i] := suffix[j]; INC(i); INC(j) UNTIL suffix[j-1] = 0X
  END Repeat;

  PROCEDURE Normalize(long: BOOLEAN);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE formatted[i] # 0X DO
      IF formatted[i] = "e" THEN
        IF long THEN formatted[i] := "D" ELSE formatted[i] := "E" END
      END;
      INC(i)
    END
  END Normalize;

  PROCEDURE Next;
  BEGIN seed := seed*48271 MOD 2147483647 END Next;

BEGIN
  Check("3.14159265358979323846264338327950288", Texts.Real, 0);
  Check("3.14159265358979323846264338327950288D0", Texts.LongReal, 0);
  Check("0.001D310", Texts.LongReal, 0); Check("1000.0D-310", Texts.LongReal, 0);
  Check("0.001E40", Texts.Real, 0); Check("1000.0E-40", Texts.Real, 0);
  Check("1.0D40000", Texts.LongReal, 0); Check("1.0D-40000", Texts.LongReal, 0);
  Check("-0.0D40000", Texts.LongReal, 0); Check("1.06E7", Texts.Real, 0);
  Check("1.00000000000000011102230246251565404236316680908203125D0", Texts.LongReal, 0);
  Check("1.000000059604644775390625E0", Texts.Real, 0);
  Check("4.9406564584124654D-324", Texts.LongReal, 0);
  Check("2.4703282292062327D-324", Texts.LongReal, 0);
  Check("-1.0D-40000", Texts.LongReal, 0);
  Check("1.7976931348623157D308", Texts.LongReal, 0);
  Check("1.7976931348623159D308", Texts.LongReal, 0);
  Check("3.4028234663852886E38", Texts.Real, 0);
  Check("1.4012984643248171E-45", Texts.Real, 0);
  Check("1.0D9223372036854775807", Texts.LongReal, 0);
  Check("1.0D9223372036854775808", Texts.Inval, 0);
  Check("1.0D+", Texts.Inval, 0); Check("1A.0D3", Texts.Inval, 0);
  Check("0FFFFFFFFH", Texts.Int, -1); Check("000000001", Texts.Int, 1);
  Check("0H", Texts.Int, 0); Check("0000", Texts.Int, 0);
  IF SIZE(LONGINT) = 4 THEN
    Check("2147483647", Texts.Int, MAX(LONGINT)); Check("-2147483648", Texts.Int, MIN(LONGINT));
    Check("2147483648", Texts.Inval, 0); Check("-2147483649", Texts.Inval, 0)
  ELSE
    Check("9223372036854775807", Texts.Int, MAX(LONGINT)); Check("-9223372036854775808", Texts.Int, MIN(LONGINT));
    Check("9223372036854775808", Texts.Inval, 0); Check("-9223372036854775809", Texts.Inval, 0)
  END;
  Repeat("", "1", 40000, ""); Check(number, Texts.Inval, 0);
  Repeat("", "0", 40000, "1.0"); Check(number, Texts.Real, 0);
  Repeat("1", "0", 40000, ".0D-40000"); Check(number, Texts.LongReal, 0);
  Repeat("0.", "0", 40000, "1D40001"); Check(number, Texts.LongReal, 0);
  Repeat("0.", "0", 40000, "1"); Check(number, Texts.Real, 0);
  Repeat("1.00000000000000011102230246251565404236316680908203125", "0", 40000, "1D0");
  Check(number, Texts.LongReal, 0);
  Repeat("1.000000059604644775390625", "0", 40000, "1E0"); Check(number, Texts.Real, 0);
  Repeat("1.0D", "9", 40000, ""); Check(number, Texts.Inval, 0);
  seed := 1;
  FOR count := 1 TO 2000 DO
    Next; bits32 := SHORT(seed);
    IF bits32 DIV 8388608 < 255 THEN
      source := SYSTEM.VAL(REAL, bits32); FormatReal(source, formatted); Normalize(FALSE);
      Check(formatted, Texts.Real, 0); ASSERT(SYSTEM.VAL(SYSTEM.INT32, scanner.x) = bits32);
      FormatReal(-source, formatted); Normalize(FALSE); Check(formatted, Texts.Real, 0)
    END;
    Next; bits64 := seed*4294967296; Next; INC(bits64, seed);
    IF bits64 DIV 4503599627370496 < 2047 THEN
      sourceL := SYSTEM.VAL(LONGREAL, bits64); FormatLongReal(sourceL, formatted); Normalize(TRUE);
      Check(formatted, Texts.LongReal, 0); ASSERT(SYSTEM.VAL(SYSTEM.INT64, scanner.y) = bits64);
      FormatLongReal(-sourceL, formatted); Normalize(TRUE); Check(formatted, Texts.LongReal, 0)
    END
  END;
  Out.String("bounded scanner number tests passed"); Out.Ln
END TestScannerNumbers.
