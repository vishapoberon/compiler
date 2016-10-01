MODULE Out; (* D C W Brown. 2016-09-27 *)

  IMPORT SYSTEM, Platform;

PROCEDURE Open*;
BEGIN
END Open;

PROCEDURE Char*(ch: CHAR);
  VAR error: Platform.ErrorCode;
BEGIN
  error := Platform.Write(Platform.StdOut, SYSTEM.ADR(ch), 1)
END Char;

PROCEDURE String*(str: ARRAY OF CHAR);
  VAR l: LONGINT;  error: Platform.ErrorCode;
BEGIN
  l := 0; WHILE (l < LEN(str)) & (str[l] # 0X) DO INC(l) END;
  error := Platform.Write(Platform.StdOut, SYSTEM.ADR(str), l)
END String;

PROCEDURE Int*(x, n: HUGEINT);
  CONST zero = ORD('0');
  VAR s: ARRAY 22 OF CHAR; i: INTEGER; negative: BOOLEAN;
BEGIN
  negative := x < 0;
  IF x = MIN(HUGEINT) THEN
    s := "8085774586302733229"; i := 19
  ELSE
    IF x < 0 THEN x := - x END;
    s[0] := CHR(zero + (x MOD 10)); x := x DIV 10;
    i := 1; WHILE x # 0 DO
      s[i] := CHR(zero + (x MOD 10));
      x := x DIV 10;
      INC(i)
    END
  END;
  IF negative THEN s[i] := '-'; INC(i) END;
  WHILE n > i DO Char(' '); DEC(n) END;
  WHILE i > 0 DO DEC(i); Char(s[i]) END
END Int;

PROCEDURE Real*(x: REAL; n: INTEGER);
BEGIN
END Real;

PROCEDURE LongReal*(x: LONGREAL; n: INTEGER);
BEGIN
END LongReal;

PROCEDURE Ln*;
BEGIN String(Platform.NL)
END Ln;

END Out.
