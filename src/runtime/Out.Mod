MODULE Out; (* DCW Brown. 2016-09-27 *)

IMPORT SYSTEM, Platform, Strings;

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

PROCEDURE Ln*;
BEGIN String(Platform.NL)
END Ln;


(* Real and Longreal display *)

PROCEDURE digit(n: HUGEINT; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
BEGIN
  DEC(i); s[i] := CHR(n MOD 10 + 48);
END digit;

PROCEDURE prepend(t: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
  VAR j, l: INTEGER;
BEGIN
  l := Strings.Length(t); IF l > i THEN l := i END;
  DEC(i, l); j := 0;
  WHILE j < l DO s[i+j] := t[j]; INC(j) END
END prepend;


PROCEDURE Ten*(e: INTEGER): REAL;
VAR r, power: LONGREAL;
BEGIN r := 1.0; power := 10.0;
  WHILE e > 0 DO
    IF ODD(e) THEN r := r*power END;
    power := power*power; e := e DIV 2
  END;
  RETURN SHORT(r)
END Ten;

PROCEDURE -Entier32(x: REAL): SYSTEM.INT32 "(int32)(x)";

PROCEDURE Real*(x: REAL; n: INTEGER);

(* Real(x, n) writes the real number x to the end of the output stream using an
   exponential form. If the textual representation of x requires m characters (including  a
   two-digit signed exponent), x is right adjusted in a ﬁeld of Max(n, m) characters padded
   with blanks at the left end. A plus sign of the mantissa is not written.
   REAL is 1/sign, 8/exponent, 23/significand *)

CONST
  maxsigdigits = 8;     (* Max significant digits to display from mantissa *)

VAR
  e:  INTEGER;          (* Exponent field *)
  f:  SYSTEM.INT32;     (* Fraction field *)
  s:  ARRAY 30 OF CHAR; (* Buffer built backwards *)
  i:  INTEGER;          (* Index into s *)
  x0: REAL;
  nn: BOOLEAN;          (* Number negative *)
  en: BOOLEAN;          (* Exponent negative *)
  m:  SYSTEM.INT32;     (* Mantissa digits *)
  d:  INTEGER;          (* Significant digit count to display *)

BEGIN
  nn := SYSTEM.VAL(SYSTEM.INT32, x) < 0; IF nn THEN DEC(n) END;
  e  := SYSTEM.VAL(INTEGER, (SYSTEM.VAL(SYSTEM.INT32, x) DIV 800000H) MOD 100H);
  f  := SYSTEM.VAL(SYSTEM.INT32, x) MOD 800000H;

  i := LEN(s);
  IF e = 0FFH THEN (* NaN / Infinity *)
    IF f = 0 THEN prepend("Infinity", s, i) ELSE prepend("NaN", s, i) END
  ELSE
    IF e = 0 THEN prepend("E+00", s, i); m := 0;
    ELSE
      IF nn THEN x := -x END;

      (* Scale e to be an exponent of 10 rather than 2 *)
      e := (e - 127) * 77 DIV 256;
      IF e >= 0 THEN x := x / Ten(e) ELSE x := Ten(-e) * x END ;
      IF x >= 10.0 THEN x := 0.1 * x; INC(e) END;

      (* Generate the exponent digits *)
      en := e < 0; IF en THEN e := - e END;
      d := 2; WHILE d > 0 DO digit(e, s, i); e := e DIV 10; DEC(d) END;
      IF en THEN prepend("E-", s, i) ELSE prepend("E+", s, i) END;

      (* Scale x to 8 significant digits *)
      x0 := Ten(maxsigdigits-1);  x  := x0*x + 0.5;
      IF x >= 10.0*x0 THEN x := 0.1*x; INC(e) END;
      m := Entier32(x)
    END;

    (* Drop trailing zeroes where we don't have room *)
    d := maxsigdigits;
    WHILE (d > 2) & (d > n-5) & (m MOD 10 = 0) DO m := m DIV 10; DEC(d) END;

    (* Render significant digits *)
    WHILE d > 1 DO digit(m, s, i); m := m DIV 10; DEC(d) END;
    DEC(i); s[i] := '.';
    digit(m, s, i);
  END;

  (* Generate leading padding *)
  DEC(n, LEN(s)-i); WHILE n > 0 DO Char(" "); DEC(n) END;

  (* Render prepared number from right end of buffer s *)
  IF nn THEN Char("-") END;
  WHILE i < LEN(s) DO Char(s[i]); INC(i) END
END Real;


PROCEDURE TenL(e: INTEGER): LONGREAL;
  VAR r, power: LONGREAL;
BEGIN r := 1.0; power := 10.0;
  WHILE e > 0 DO
    IF ODD(e) THEN r := r*power END;
    power := power*power; e := e DIV 2;
  END;
  RETURN r
END TenL;

PROCEDURE -Entier64(x: LONGREAL): SYSTEM.INT64 "(int64)(x)";

PROCEDURE LongReal*(x: LONGREAL; n: INTEGER);

(* LongReal(x, n) writes the long real number x to the end of the output stream using an
   exponential form. If the textual representation of x requires m characters (including  a
   three-digit signed exponent), x is right adjusted in a ﬁeld of Max(n, m) characters padded
   with blanks at the left end. A plus sign of the mantissa is not written.
   LONGREAL is 1/sign, 11/exponent, 52/significand *)

CONST
  maxsigdigits = 16; (* Max significant digits to display from mantissa *)

VAR
  e:  INTEGER;          (* Exponent field *)
  f:  HUGEINT;          (* Fraction field *)
  s:  ARRAY 30 OF CHAR; (* Buffer built backwards *)
  i:  INTEGER;          (* Index into s *)
  x0: LONGREAL;
  nn: BOOLEAN;          (* Number negative *)
  en: BOOLEAN;          (* Exponent negative *)
  m:  HUGEINT;          (* Mantissa digits *)
  d:  INTEGER;          (* Significant digit count to display *)

BEGIN
  nn := SYSTEM.VAL(HUGEINT, x) < 0; IF nn THEN DEC(n) END;
  e  := SYSTEM.VAL(INTEGER, (SYSTEM.VAL(HUGEINT, x) DIV 10000000000000H) MOD 800H);
  f  := SYSTEM.VAL(HUGEINT, x) MOD 10000000000000H;

  i := LEN(s);
  IF e = 7FFH THEN (* NaN / Infinity *)
    IF f = 0 THEN prepend("Infinity", s, i) ELSE prepend("NaN", s, i) END
  ELSE
    IF e = 0 THEN prepend("D+000", s, i); m := 0;
    ELSE
      IF nn THEN x := -x END;

      (* Scale e to be an exponent of 10 rather than 2 *)
      e := SHORT(LONG(e - 1023) * 77 DIV 256);
      IF e >= 0 THEN x := x / TenL(e) ELSE x := TenL(-e) * x END ;
      IF x >= 10.0D0 THEN x := 0.1D0 * x; INC(e) END;

      (* Generate the exponent digits *)
      en := e < 0; IF en THEN e := - e END;
      d := 3; WHILE d > 0 DO digit(e, s, i); e := e DIV 10; DEC(d) END;
      IF en THEN prepend("D-", s, i) ELSE prepend("D+", s, i) END;

      (* Scale x to 15 significant digits *)
      x0 := TenL(maxsigdigits-1);
      x  := x0 * x + 0.5D0;
      IF x >= 10.0D0 * x0 THEN x := 0.1D0 * x; INC(e) END;
      m := Entier64(x)
    END;

    (* Drop trailing zeroes where we don't have room *)
    d := maxsigdigits;
    WHILE (d > 2) & (d > n-6) & (m MOD 10 = 0) DO m := m DIV 10; DEC(d) END;

    (* Render significant digits *)
    WHILE d > 1 DO digit(m, s, i); m := m DIV 10; DEC(d) END;
    DEC(i); s[i] := '.';
    digit(m, s, i);
  END;

  (* Generate leading padding *)
  DEC(n, LEN(s)-i); WHILE n > 0 DO Char(" "); DEC(n) END;

  (* Render prepared number from right end of buffer s *)
  IF nn THEN Char("-") END;
  WHILE i < LEN(s) DO Char(s[i]); INC(i) END
END LongReal;


END Out.
