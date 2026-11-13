MODULE TestReductions;
IMPORT Out, SYSTEM;
VAR a, b: ARRAY 1024 OF LONGINT;
  reals: ARRAY 1024 OF REAL;
  doubles: ARRAY 16 OF LONGREAL;
  tiny: ARRAY 3 OF SYSTEM.INT8;
  small: ARRAY 3 OF SYSTEM.INT16;
  words: ARRAY 3 OF SYSTEM.INT32;
  huge: ARRAY 3 OF HUGEINT;
  i, total, factor, low, high: LONGINT;
  h: HUGEINT;
  r: REAL;
  d: LONGREAL;
  invoked: BOOLEAN;

PROCEDURE Energy(VAR x: ARRAY OF REAL; scale: REAL): REAL;
BEGIN
  RETURN SUM([k = 0 .. LEN(x)-1: x[k] * x[k] * scale])
END Energy;

PROCEDURE Capture(VAR scale: LONGINT): LONGINT;
VAR local: ARRAY 4 OF LONGINT;
  start, finish: LONGINT;

  PROCEDURE Nested(): LONGINT;
  BEGIN RETURN SUM([k = start .. finish: local[k] * scale]) END Nested;

BEGIN
  local[0] := 1; local[1] := 2; local[2] := 3; local[3] := 4;
  start := 1; finish := 3;
  RETURN Nested()
END Capture;

PROCEDURE Argument(x: LONGINT): LONGINT;
BEGIN RETURN x + 1 END Argument;

PROCEDURE EmptyCaptures(): LONGINT;
VAR skipped: LONGINT;
BEGIN
  RETURN SUM([i = 1 .. 0: skipped]) + PROD([i = 1 .. 0: skipped])
END EmptyCaptures;

PROCEDURE Explode(): BOOLEAN;
BEGIN invoked := TRUE; RETURN TRUE END Explode;

BEGIN
  FOR i := 0 TO 1023 DO a[i] := 1; b[i] := 2; reals[i] := 0.5 END;
  ASSERT(SUM([k = 0 .. 1023: a[k]]) = 1024);
  ASSERT(SUM([k = 0 .. 1023: a[k] * b[k]]) = 2048);
  ASSERT(PROD([k = 0 .. 9: b[k]]) = 1024);
  ASSERT(SUM([k = -3 .. 3: k]) = 0);
  ASSERT(PROD([k = -3 .. -1: k]) = -6);
  ASSERT(SUM([k = 3 .. 2: a[k]]) = 0);
  ASSERT(PROD([k = 3 .. 2: a[k]]) = 1);
  ASSERT(EmptyCaptures() = 1);
  ASSERT(SUM([k = MAX(HUGEINT) .. MAX(HUGEINT): k]) = MAX(HUGEINT));
  ASSERT(SUM([k = MIN(HUGEINT) .. MIN(HUGEINT): k]) = MIN(HUGEINT));
  ASSERT(SUM([k = MAX(HUGEINT)-1 .. MAX(HUGEINT): k]) = -3);
  ASSERT(PROD([k = MAX(HUGEINT)-1 .. MAX(HUGEINT): k]) = -9223372036854775806);
  ASSERT(SUM([k = MIN(HUGEINT) .. MIN(HUGEINT)+1: k]) = 1);
  low := 4; high := 7; total := SUM([k = low .. high: k]); ASSERT(total = 22);
  i := 41; ASSERT(SUM([i = i .. i+1: i]) = 83); ASSERT(i = 41);
  ASSERT(Argument(SUM([k = 1 .. 4: k])) = 11);
  CASE SUM([k = 1 .. 4: k]) OF
    10: total := 100
  ELSE total := 0
  END;
  ASSERT(total = 100);
  a[SUM([k = 0 .. 0: k])] := 3;
  ASSERT(a[0] = 3); a[0] := 1;
  ASSERT(SUM([k = 1 .. 4: k]) + PROD([k = 1 .. 4: k]) = 34);
  total := 0;
  WHILE total < SUM([k = 1 .. 2: k]) DO INC(total) END;
  ASSERT(total = 3);
  invoked := FALSE;
  ASSERT((SUM([k = 1 .. 2: k]) = 3) OR Explode()); ASSERT(~invoked);
  ASSERT((1 = 2) OR (SUM([k = 1 .. 2: k]) = 3));
  ASSERT(~((1 = 2) & (SUM([k = -1 .. 0: a[k]]) = 0)));
  ASSERT(~(invoked & (SUM([k = -1 .. 0: a[k]]) = 0)));
  total := 0;
  WHILE SUM([k = 0 .. 0: total]) < 3 DO INC(total) END;
  REPEAT DEC(total) UNTIL SUM([k = 0 .. 0: total]) = 0;
  factor := 3; ASSERT(Capture(factor) = 27);
  ASSERT(Energy(reals, 2) = 512);
  r := SUM([k = 0 .. 1023: reals[k]]); ASSERT(r = 512);
  r := PROD([k = 0 .. 9: reals[k]]); ASSERT(r = 0.0009765625);
  r := SUM([k = 2 .. 1: reals[k]]); ASSERT(r = 0);
  r := PROD([k = 2 .. 1: reals[k]]); ASSERT(r = 1);
  FOR i := 0 TO 15 DO doubles[i] := 0.25 END;
  d := SUM([k = 0 .. 15: doubles[k]]); ASSERT(d = 4);
  d := PROD([k = 0 .. 3: doubles[k]]); ASSERT(d = 0.00390625);
  doubles[0] := 1.0D308; doubles[1] := doubles[0];
  d := SUM([k = 0 .. 1: doubles[k]]); ASSERT(d > doubles[0]);
  doubles[0] := d; doubles[1] := -d;
  d := SUM([k = 0 .. 1: doubles[k]]); ASSERT(d # d);
  doubles[1] := 0;
  d := PROD([k = 0 .. 1: doubles[k]]); ASSERT(d # d);
  tiny[0] := 127; tiny[1] := 1; tiny[2] := -1;
  ASSERT(SUM([k = 0 .. 1: tiny[k]]) = -128);
  ASSERT(SUM([k = 0 .. 2: tiny[k]]) = 127);
  tiny[0] := -128; ASSERT(PROD([k = 0 .. 2: tiny[k]]) = -128);
  small[0] := 32767; small[1] := 1; small[2] := -1;
  ASSERT(SUM([k = 0 .. 1: small[k]]) = -32768);
  small[0] := 32767; small[1] := 32767;
  ASSERT(PROD([k = 0 .. 1: small[k]]) = 1);
  words[0] := 2147483647; words[1] := 1; words[2] := -1;
  ASSERT(SUM([k = 0 .. 1: words[k]]) = -2147483648);
  words[0] := 65535; words[1] := 65535;
  ASSERT(PROD([k = 0 .. 1: words[k]]) = -131071);
  huge[0] := MAX(HUGEINT); huge[1] := 1; huge[2] := -1;
  h := SUM([k = 0 .. 1: huge[k]]); ASSERT(h = MIN(HUGEINT));
  h := PROD([k = 0 .. 2: huge[k]]); ASSERT(h = -MAX(HUGEINT));
  Out.String("SUM and PROD tests passed"); Out.Ln
END TestReductions.
