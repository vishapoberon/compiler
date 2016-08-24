MODULE TestLanguage;

IMPORT SYSTEM, Console;

PROCEDURE Shift;
VAR c: CHAR; b: SYSTEM.BYTE; s,t,u: SHORTINT; h,i,j,k: INTEGER; l,m,n: LONGINT;
(*
  Aritmetic shift always returns type LONGINT. Defined as x * 2**n.
  LSH and ROT produces results of the same type as the value being shifted.
*)
BEGIN
  (* Positive LSH shifts and ROTs without overflow *)

  i := 0; m := 1;
  WHILE i < SIZE(LONGINT)*8 DO
    l := 1; l := SYSTEM.LSH(l,i); ASSERT(l = m, 16);
    l := 1; l := SYSTEM.ROT(l,i); ASSERT(l = m, 17);
    m := m * 2; INC(i);
  END;

  i := 0; k := 1;
  WHILE i < SIZE(INTEGER)*8 DO
    j := 1; j := SYSTEM.LSH(j,i); ASSERT(j = k, 23);
    j := 1; j := SYSTEM.ROT(j,i); ASSERT(j = k, 24);
    k := k * 2; INC(i);
  END;

  i := 0; t := 1;
  WHILE i < SIZE(SHORTINT)*8 DO
    s := 1; s := SYSTEM.LSH(s,i); ASSERT(s = t, 30);
    s := 1; s := SYSTEM.ROT(s,i); ASSERT(s = t, 31);
    t := t * 2; INC(i);
  END;

  (* Negative LSH shifts and ROTs without overflow *)

  i := -1; m := 1; m := SYSTEM.LSH(m, SIZE(LONGINT)*8 - 2); n := m*2;
  WHILE i > -SIZE(LONGINT)*8 DO
    l := n; l := SYSTEM.LSH(l,i); ASSERT(l = m, 39);
    l := n; l := SYSTEM.ROT(l,i); ASSERT(l = m, 40);
    m := m DIV 2; DEC(i);
  END;

  i := -1; k := 1; k := SYSTEM.LSH(k, SIZE(INTEGER)*8 - 2); h := k*2;
  WHILE i > -SIZE(INTEGER)*8 DO
    j := h; j := SYSTEM.LSH(j,i); ASSERT(j = k, 46);
    j := h; j := SYSTEM.ROT(j,i); ASSERT(j = k, 47);
    k := k DIV 2; DEC(i);
  END;

  i := -1; t := 1; t := SYSTEM.LSH(t, SIZE(SHORTINT)*8 - 2); u := t*2;
  WHILE i > -SIZE(SHORTINT)*8 DO
    s := u; s := SYSTEM.LSH(s,i); ASSERT(s = t, 53);
    s := u; s := SYSTEM.ROT(s,i); ASSERT(s = t, 54);
    t := t DIV 2; DEC(i);
  END;

  (* Positive ASHs of a negative number *)

  i := 0; m := 1; m := SYSTEM.LSH(m, SIZE(LONGINT)*8 - 1); n := m;
  WHILE i > -SIZE(LONGINT)*8 DO
    l := n; l := ASH(l,i); ASSERT(l = m, 62);
    m := m DIV 2; DEC(i);
  END;

  i := 0; j := 1; j := SYSTEM.LSH(j, SIZE(INTEGER)*8 - 1); k := j;
  WHILE i > -SIZE(INTEGER)*8 DO
    l := ASH(j,i); ASSERT(l = LONG(k), 68);
    k := k DIV 2; DEC(i);
  END;

  i := 0; s := 1; s := SYSTEM.LSH(s, SIZE(SHORTINT)*8 - 1); t := s;
  WHILE i > -SIZE(SHORTINT)*8 DO
    l := ASH(s,i); ASSERT(l = LONG(LONG(t)), 74);
    t := t DIV 2; DEC(i);
  END;

  (* Positive ASHs of a positive number *)

  i := 0; m := 1; m := SYSTEM.LSH(m, SIZE(LONGINT)*8 - 2); n := m;
  WHILE i > 1-SIZE(LONGINT)*8 DO
    l := n; l := ASH(l,i); ASSERT(l = m, 82);
    m := m DIV 2; DEC(i);
  END;



  (* Also need tests that bits that are shifted / rotated off the end
     are zeroed or wrapped correctly. *)

  (* Also need full tests for CHAR, and poossibly SYSTEM.BYTE. Here's a simple one *)

  c := 1X; c := SYSTEM.LSH(c,2); c := SYSTEM.ROT(c,-2); ASSERT(c=1X, 93);
  b := 1;  b := SYSTEM.LSH(b,2); b := SYSTEM.ROT(b,-2); ASSERT(SYSTEM.VAL(CHAR,b)=1X, 94);

END Shift;


PROCEDURE TestValue(v,e: LONGINT; name: ARRAY OF CHAR);
BEGIN
  IF v # e THEN
    Console.String(name);
    Console.String(" = ");
    Console.Int(v,1);
    Console.String(", expected ");
    Console.Int(e,1);
    Console.Ln;
  END
END TestValue;

PROCEDURE IntSize;
  VAR l: LONGINT;
BEGIN
  TestValue(MIN(SHORTINT), -80H, "MIN(SHORTINT)");
  TestValue(MAX(SHORTINT),  7FH, "MAX(SHORTINT)");
  IF SIZE(INTEGER) = 2 THEN (* 32 bit machine *)
    TestValue(MIN(INTEGER),      -7FFFH - 1, "MIN(INTEGER)");
    TestValue(MAX(INTEGER),       7FFFH,     "MAX(INTEGER)");
    TestValue(MIN(LONGINT),  -7FFFFFFFH - 1, "MIN(LONGINT)");
    TestValue(MAX(LONGINT),   7FFFFFFFH,     "MAX(LONGINT)");
  ELSIF SIZE(INTEGER) = 4 THEN (* 64 bit machine *)
    TestValue(MIN(INTEGER),          -7FFFFFFFH - 1, "MIN(INTEGER)");
    TestValue(MAX(INTEGER),           7FFFFFFFH,     "MAX(INTEGER)");
    (* Since we need to be compilable on 32 bit machines we cannot use
       a 64 bit constant, so use arithmetic. *)
    l := 1; l := SYSTEM.LSH(l, 63); l := l-1;  (* Generate l = 7FFFFFFFFFFFFFFFH *)
    TestValue(MIN(LONGINT),  -l - 1, "MIN(LONGINT)");
    TestValue(MAX(LONGINT),   l,     "MAX(LONGINT)");
  ELSE
    Console.String("SIZE(INTEGER) = ");
    Console.Int(SIZE(INTEGER),1);
    Console.String(", expected 2 or 4.");
    Console.Ln;
  END;
END IntSize;

BEGIN
  Shift;
  IntSize;
  Console.String("Language tests successful."); Console.Ln;
END TestLanguage.
