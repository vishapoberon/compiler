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
  matrix: ARRAY 3, 4 OF INTEGER;
  p: Buffer;
  i, lo, hi, calls, boundsLog: INTEGER;
  scalar: LONGINT;

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
  ALL r = MAX(HUGEINT)-1 .. MAX(HUGEINT) DO huge[r-(MAX(HUGEINT)-1)] := r END;
  ASSERT(huge[0] = MAX(HUGEINT)-1); ASSERT(huge[1] = MAX(HUGEINT));
  ALL r = MIN(HUGEINT) .. MIN(HUGEINT)+1 DO huge[r-MIN(HUGEINT)] := r END;
  ASSERT(huge[0] = MIN(HUGEINT)); ASSERT(huge[1] = MIN(HUGEINT)+1);
  ALL r = MAX(HUGEINT) .. MIN(HUGEINT) DO huge[0] := r END;
  ALL r = 0 .. 2 DO matrix[r, 0] := r END;
  ASSERT(matrix[2, 0] = 2);
  NEW(p, 4);
  ALL r = 0 .. LEN(p^)-1 DO p[r] := r END;
  ASSERT(p[0] = 0); ASSERT(p[3] = 3);
  Enclosing;
  Out.String("ALL tests passed"); Out.Ln
END TestAll.
