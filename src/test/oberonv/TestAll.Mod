MODULE TestAll;
IMPORT Out;
CONST n = 16;
TYPE
  Cell = RECORD value: REAL END;
  Buffer = POINTER TO ARRAY OF REAL;
VAR
  a, b: ARRAY n OF REAL;
  cells: ARRAY n OF Cell;
  ints: ARRAY 8 OF LONGINT;
  huge: ARRAY 2 OF HUGEINT;
  narrowRange: ARRAY 65536 OF LONGINT;
  matrix: ARRAY 3, 4 OF INTEGER;
  p: Buffer;
  i, lo, hi, calls, boundsLog: INTEGER;
  scalar: LONGINT;
  wideLow, wideHigh: HUGEINT;

PROCEDURE Bound(value: INTEGER): INTEGER;
BEGIN
  INC(calls);
  boundsLog := boundsLog * 10 + value;
  RETURN value
END Bound;

PROCEDURE Scale(VAR values: ARRAY OF REAL);
BEGIN
  ALL r = 0 .. LEN(values)-1 DO values[r] := values[r] * 3 END
END Scale;

PROCEDURE Enclosing;
VAR local: INTEGER;
  PROCEDURE Inner;
    PROCEDURE Innermost;
    BEGIN
      ALL r = 1 .. 3 DO ints[r] := r + local END
    END Innermost;
  BEGIN
    ALL r = local .. local+2 DO ints[r] := r END;
    Innermost
  END Inner;
BEGIN
  local := 1; Inner;
  ASSERT(ints[1] = 2); ASSERT(ints[3] = 4)
END Enclosing;

BEGIN
  i := 77;
  ALL i = 0 .. n-1 DO a[i] := i; b[i] := a[i] * 2 END;
  ASSERT(i = 77);
  FOR i := 0 TO n-1 DO ASSERT(a[i] = i); ASSERT(b[i] = i * 2) END;
  Scale(a);
  ALL i = 0 .. n-1 DO cells[i].value := a[i] END;
  FOR i := 0 TO n-1 DO ASSERT(cells[i].value = i * 3) END;
  ALL i = -3 .. 3 DO ints[i+3] := i END;
  FOR i := 0 TO 6 DO ASSERT(ints[i] = i-3) END;
  ALL r = -3 .. 3 DO ints[r+3] := ABS(LONG(r)) END;
  ASSERT(ints[0] = 3); ASSERT(ints[3] = 0); ASSERT(ints[6] = 3);
  lo := -3; hi := 3;
  ALL r = lo .. hi DO ints[r+3] := r END;
  ASSERT(ints[0] = -3); ASSERT(ints[3] = 0); ASSERT(ints[6] = 3);
  calls := 0; boundsLog := 0;
  ALL r = Bound(1) .. Bound(3) DO ints[r] := r * 2 END;
  ASSERT(calls = 2); ASSERT(boundsLog = 13); ASSERT(ints[1] = 2); ASSERT(ints[3] = 6);
  calls := 0; boundsLog := 0;
  ALL r = Bound(3) .. Bound(1) DO ints[r] := 100 END;
  ASSERT(calls = 2); ASSERT(boundsLog = 31); ASSERT(ints[1] = 2); ASSERT(ints[3] = 6);
  ALL r = 1000 .. 999 DO a[r] := 0 END;
  ALL r = 0 .. 0 DO END;
  ALL r = 5 .. 5 DO scalar := r END;
  ASSERT(scalar = 5);
  lo := 1; hi := 3;
  ALL lo = lo .. hi DO ints[lo] := lo END;
  ASSERT(lo = 1); ASSERT(hi = 3); ASSERT(ints[3] = 3);
  ALL r = MAX(INTEGER)-1 .. MAX(INTEGER) DO ints[r-(MAX(INTEGER)-1)] := r END;
  ASSERT(ints[0] = MAX(INTEGER)-1); ASSERT(ints[1] = MAX(INTEGER));
  ALL r = -32768 .. 32767 DO narrowRange[LONG(r)+32768] := r END;
  ASSERT(narrowRange[0] = -32768); ASSERT(narrowRange[32768] = 0); ASSERT(narrowRange[65535] = 32767);
  ALL r = MAX(HUGEINT)-1 .. MAX(HUGEINT) DO huge[r-(MAX(HUGEINT)-1)] := r END;
  ASSERT(huge[0] = MAX(HUGEINT)-1); ASSERT(huge[1] = MAX(HUGEINT));
  ALL r = MIN(HUGEINT) .. MIN(HUGEINT)+1 DO huge[r-MIN(HUGEINT)] := r END;
  ASSERT(huge[0] = MIN(HUGEINT)); ASSERT(huge[1] = MIN(HUGEINT)+1);
  wideLow := MIN(HUGEINT); wideHigh := wideLow + 1;
  ALL r = wideLow .. wideHigh DO huge[r-wideLow] := r END;
  ASSERT(huge[0] = wideLow); ASSERT(huge[1] = wideHigh);
  wideHigh := MAX(HUGEINT); wideLow := wideHigh - 1;
  ALL r = wideLow .. wideHigh DO huge[r-wideLow] := r END;
  ASSERT(huge[0] = wideLow); ASSERT(huge[1] = wideHigh);
  ALL r = MAX(HUGEINT) .. MIN(HUGEINT) DO huge[0] := r END;
  ALL r = 0 .. 2 DO matrix[r, 0] := r END;
  ASSERT(matrix[2, 0] = 2);
  NEW(p, 4);
  ALL r = 0 .. LEN(p^)-1 DO p[r] := r END;
  ASSERT(p[0] = 0); ASSERT(p[3] = 3);
  Enclosing;
  scalar := 99;
  ALL r = 0 .. n-1 WITH scalar, t: LONGINT; v: REAL; yes: BOOLEAN; c: CHAR; bits: SET DO
    scalar := r + 1; t := scalar * 2; v := t; yes := v > 0; c := CHR(ORD("A") + r);
    bits := {0}; a[r] := v; b[r] := ORD(c)
  END;
  ASSERT(scalar = 99);
  FOR i := 0 TO n-1 DO ASSERT(a[i] = (i+1)*2); ASSERT(b[i] = ORD("A")+i) END;
  lo := 0; hi := 7;
  ALL r = lo .. hi WITH t: LONGINT DO t := r * 3; ints[r] := t; t := t+1; ints[r] := t END;
  FOR i := 0 TO 7 DO ASSERT(ints[i] = i*3+1) END;
  ALL r = 3 .. 3 WITH t: LONGINT DO t := r; scalar := t END;
  ASSERT(scalar = 3);
  ALL r = 1 .. 0 WITH t: LONGINT DO t := r; ints[r] := t END;
  Out.String("ALL tests passed"); Out.Ln
END TestAll.
