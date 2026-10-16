MODULE TestIntStr;
  IMPORT IntStr, IntConv, Out;
  VAR power: LONGINT;
    guarded: RECORD before: CHAR; text: ARRAY 4 OF CHAR; after: CHAR END;

  PROCEDURE Check(value: LONGINT; expected: ARRAY OF CHAR);
    VAR text: ARRAY 32 OF CHAR; small: POINTER TO ARRAY OF CHAR;
      parsed: LONGINT; result: IntStr.ConvResults; n, i, j: INTEGER;
  BEGIN
    IntStr.IntToStr(value, text); ASSERT(text = expected);
    IntStr.StrToInt(text, parsed, result);
    ASSERT(result = IntStr.strAllRight); ASSERT(parsed = value);
    n := IntConv.LengthInt(value); ASSERT(text[n] = 0X);
    IF n > 0 THEN ASSERT(text[n - 1] # 0X) END;
    FOR i := 1 TO n + 1 DO
      NEW(small, i); IntStr.IntToStr(value, small^);
      ASSERT(small[i - 1] = 0X);
      j := 0;
      WHILE j < i - 1 DO ASSERT(small[j] = expected[j]); INC(j) END
    END
  END Check;

  PROCEDURE RoundTrip(value: LONGINT);
    VAR text: ARRAY 32 OF CHAR; parsed: LONGINT; result: IntStr.ConvResults;
  BEGIN
    IntStr.IntToStr(value, text); IntStr.StrToInt(text, parsed, result);
    ASSERT(result = IntStr.strAllRight); ASSERT(parsed = value)
  END RoundTrip;

  PROCEDURE Reject(text: ARRAY OF CHAR; expected: IntStr.ConvResults);
    VAR parsed: LONGINT; result: IntStr.ConvResults;
  BEGIN
    parsed := 123;
    IntStr.StrToInt(text, parsed, result);
    ASSERT(result = expected); ASSERT(parsed = 123)
  END Reject;

BEGIN
  IF SIZE(LONGINT) = 8 THEN
    Check(MIN(LONGINT), "-9223372036854775808");
    Check(MIN(LONGINT) + 1, "-9223372036854775807");
    Check(MAX(LONGINT), "9223372036854775807");
    Check(MAX(LONGINT) - 1, "9223372036854775806");
    Reject("9223372036854775808", IntStr.strOutOfRange);
    Reject("-9223372036854775809", IntStr.strOutOfRange);
    Reject("-9223372036854775810", IntStr.strOutOfRange)
  ELSE
    Check(MIN(LONGINT), "-2147483648");
    Check(MIN(LONGINT) + 1, "-2147483647");
    Check(MAX(LONGINT), "2147483647");
    Check(MAX(LONGINT) - 1, "2147483646");
    Reject("2147483648", IntStr.strOutOfRange);
    Reject("-2147483649", IntStr.strOutOfRange);
    Reject("-2147483650", IntStr.strOutOfRange)
  END;
  Check(0, "0"); Check(1, "1"); Check(-1, "-1");
  Check(10, "10"); Check(-10, "-10"); Check(1234567890, "1234567890");
  Check(-1234567890, "-1234567890");
  Reject("", IntStr.strEmpty); Reject("+", IntStr.strWrongFormat);
  Reject("--1", IntStr.strWrongFormat); Reject("12x", IntStr.strWrongFormat);
  FOR power := -1000 TO 1000 DO RoundTrip(power) END;
  power := 1;
  LOOP
    RoundTrip(power); RoundTrip(-power);
    RoundTrip(power - 1); RoundTrip(1 - power);
    RoundTrip(power + 1); RoundTrip(-power - 1);
    IF power > MAX(LONGINT) DIV 10 THEN EXIT END;
    power := power * 10
  END;
  guarded.before := "L"; guarded.after := "R";
  IntStr.IntToStr(MIN(LONGINT), guarded.text);
  IF SIZE(LONGINT) = 8 THEN ASSERT(guarded.text = "-92")
  ELSE ASSERT(guarded.text = "-21") END;
  ASSERT(guarded.before = "L"); ASSERT(guarded.after = "R");
  Out.String("oo2c integer string tests passed"); Out.Ln
END TestIntStr.
