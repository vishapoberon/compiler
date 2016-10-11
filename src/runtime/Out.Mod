MODULE Out; (* DCW Brown. 2016-09-27 *)

IMPORT SYSTEM, Platform;

VAR buf: ARRAY 128 OF CHAR; in: INTEGER;

PROCEDURE Flush*;
VAR error: Platform.ErrorCode;
BEGIN
  IF in > 0 THEN error := Platform.Write(Platform.StdOut, SYSTEM.ADR(buf), in) END;
  in := 0;
END Flush;

PROCEDURE Open*;
BEGIN
END Open;

PROCEDURE Char*(ch: CHAR);
BEGIN
  IF in >= LEN(buf) THEN Flush END;
  buf[in] := ch; INC(in);
  IF ch = 0AX THEN Flush END;
END Char;

PROCEDURE Length(VAR s: ARRAY OF CHAR): LONGINT;
VAR l: LONGINT;
BEGIN l := 0; WHILE (l < LEN(s)) & (s[l] # 0X) DO INC(l) END; RETURN l
END Length;

PROCEDURE String*(str: ARRAY OF CHAR);
  VAR l: LONGINT;  error: Platform.ErrorCode;
BEGIN
  l := Length(str);
  IF in + l > LEN(buf) THEN Flush END;
  IF l > LEN(buf) THEN
    (* Doesn't fit buf. Bypass buffering. *)
    error := Platform.Write(Platform.StdOut, SYSTEM.ADR(str), l)
  ELSE
    SYSTEM.MOVE(SYSTEM.ADR(str), SYSTEM.ADR(buf[in]), l); INC(in, SHORT(l));
  END
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
BEGIN String(Platform.NL); Flush;
END Ln;


(* Real and Longreal display *)

PROCEDURE digit(n: HUGEINT; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
BEGIN
  DEC(i); s[i] := CHR(n MOD 10 + 48);
END digit;

PROCEDURE prepend(t: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
  VAR j: INTEGER; l: LONGINT;
BEGIN
  l := Length(t); IF l > i THEN l := i END;
  DEC(i, SHORT(l)); j := 0;
  WHILE j < l DO s[i+j] := t[j]; INC(j) END
END prepend;


PROCEDURE Ten*(e: INTEGER): LONGREAL;
VAR r, power: LONGREAL;
BEGIN r := 1.0D0; power := 1.0D1;
  WHILE e > 0 DO
    IF ODD(e) THEN r := r*power END;
    power := power*power; e := e DIV 2
  END;
  RETURN r
END Ten;

PROCEDURE -Entier64(x: LONGREAL): SYSTEM.INT64 "(int64)(x)";

PROCEDURE RealP(x: LONGREAL; n, exponentdigits, maxsigdigits: INTEGER; exp: CHAR);

(* LongReal(x, n) writes the long real number x to the end of the output stream using an
   exponential form. If the textual representation of x requires m characters (including  a
   three-digit signed exponent), x is right adjusted in a ﬁeld of Max(n, m) characters padded
   with blanks at the left end. A plus sign of the mantissa is not written.
   LONGREAL is 1/sign, 11/exponent, 52/significand *)

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
  dr: INTEGER;          (* Number of insignificant digits that can be dropped *)

BEGIN
  nn := SYSTEM.VAL(HUGEINT, x) < 0; IF nn THEN DEC(n) END;
  e  := SYSTEM.VAL(INTEGER, (SYSTEM.VAL(HUGEINT, x) DIV 10000000000000H) MOD 800H);
  f  := SYSTEM.VAL(HUGEINT, x) MOD 10000000000000H;

  i := LEN(s);
  IF e = 7FFH THEN (* NaN / Infinity *)
    IF f = 0 THEN prepend("Infinity", s, i) ELSE prepend("NaN", s, i) END
  ELSE
    IF e = 0 THEN
      d := i - exponentdigits; WHILE i > d DO DEC(i); s[i] := "0" END;
      DEC(i); s[i] := "+";
      DEC(i); s[i] := exp;
      m := 0;
    ELSE
      IF nn THEN x := -x END;

      (* Scale e to be an exponent of 10 rather than 2 *)
      e := SHORT(LONG(e - 1023) * 77 DIV 256);
      IF e >= 0 THEN x := x / Ten(e) ELSE x := Ten(-e) * x END ;
      IF x >= 10.0D0 THEN x := 0.1D0 * x; INC(e) END;

      (* Generate the exponent digits *)
      en := e < 0; IF en THEN e := - e END;
      d := exponentdigits;
      WHILE d > 0 DO digit(e, s, i); e := e DIV 10; DEC(d) END;
      DEC(i); IF en THEN s[i] := "-" ELSE s[i] := "+" END;
      DEC(i); s[i] := exp;

      (* Todo: generate more than maxsigdigits if we have room for them *)

      (* Scale x to enoughsignificant digits to reliably test for trailing
         zeroes.
         todo or to the amount of space available, if greater. *)
      x0 := Ten(maxsigdigits-1);
      x  := x0 * x + 0.5D0;
      IF x >= 10.0D0 * x0 THEN x := 0.1D0 * x; INC(e) END;
      m := Entier64(x)
    END;

    (* Drop trailing zeroes where we don't have room *)
    d := maxsigdigits;
    dr := n - (exponentdigits + 3); (* 3 for '.', D/E and +/- *)
    IF dr < 2 THEN dr := 2 END;
    WHILE (d > dr) & (m MOD 10 = 0) DO m := m DIV 10; DEC(d) END;

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
END RealP;


PROCEDURE Real*(x: REAL; n: INTEGER);
BEGIN RealP(x, n, 2, 7, "E");
END Real;

PROCEDURE LongReal*(x: LONGREAL; n: INTEGER);
BEGIN RealP(x, n, 3, 16, "D");
END LongReal;

END Out.
