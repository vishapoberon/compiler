MODULE TestMultiAll;
IMPORT Out;
VAR matrix, copy: ARRAY 4, 5 OF LONGINT;
  square: ARRAY 4, 4 OF LONGINT;
  cube: ARRAY 2, 3, 4 OF LONGINT;
  wide: ARRAY 2, 2 OF HUGEINT;
  i, j, k, calls, boundsLog, low, high: LONGINT;
  scalar, unused: LONGINT;

PROCEDURE Bound(value: LONGINT): LONGINT;
BEGIN
  INC(calls); boundsLog := boundsLog * 10 + value;
  RETURN value
END Bound;

PROCEDURE Process(VAR values: ARRAY OF ARRAY OF LONGINT);
BEGIN
  ALL row = 0 .. LEN(values)-1, col = 0 .. LEN(values, 1)-1 DO
    values[row, col] := row * 10 + col
  END
END Process;

PROCEDURE Enclosing;
VAR rows, cols, amount: LONGINT;

  PROCEDURE Inner;
  BEGIN
    ALL row = 0 .. rows-1, col = 0 .. cols-1 WITH t: LONGINT DO
      t := row * 10 + col + amount; copy[row, col] := t
    END
  END Inner;

BEGIN
  rows := 4; cols := 5; amount := 100; Inner
END Enclosing;

BEGIN
  i := 2; j := 3;
  ALL i = 0 .. 3, j = 0 .. 4 DO matrix[i, j] := i*10+j END;
  ASSERT(i = 2); ASSERT(j = 3);
  ALL row = 0 .. 3, col = 0 .. 4 WITH t: LONGINT DO
    t := matrix[row, col] * 2; copy[row, col] := t
  END;
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 4 DO ASSERT(matrix[i, j] = i*10+j); ASSERT(copy[i, j] = (i*10+j)*2) END
  END;
  ALL row = 0 .. 3, col = 0 .. 4 DO matrix[row, col] := matrix[row, col]+1 END;
  ASSERT(matrix[3, 4] = 35);
  ALL row, col = 0 .. 3 DO square[row, col] := row*10+col END;
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 3 DO ASSERT(square[i, j] = i*10+j) END
  END;
  ALL plane = 0 .. 1, row = 0 .. 2, col = 0 .. 3 DO
    cube[plane, row, col] := plane*100+row*10+col
  END;
  FOR i := 0 TO 1 DO
    FOR j := 0 TO 2 DO
      FOR k := 0 TO 3 DO ASSERT(cube[i, j, k] = i*100+j*10+k) END
    END
  END;
  calls := 0; boundsLog := 0;
  ALL row = Bound(1) .. Bound(2), col = Bound(3) .. Bound(4) DO
    matrix[row, col] := row*10+col
  END;
  ASSERT(calls = 4); ASSERT(boundsLog = 1234); ASSERT(matrix[2, 4] = 24);
  calls := 0; boundsLog := 0;
  ALL row, col = Bound(1) .. Bound(2) DO square[row, col] := row*10+col END;
  ASSERT(calls = 2); ASSERT(boundsLog = 12); ASSERT(square[2, 2] = 22);
  calls := 0; boundsLog := 0;
  ALL plane, row = Bound(0) .. Bound(1), col = Bound(2) .. Bound(3) DO
    cube[plane, row, col] := cube[plane, row, col]+1
  END;
  ASSERT(calls = 4); ASSERT(boundsLog = 123);
  ASSERT(cube[1, 1, 3] = 114); ASSERT(cube[0, 2, 3] = 23);
  calls := 0; boundsLog := 0;
  ALL row = Bound(2) .. Bound(1), col = Bound(3) .. Bound(4) DO matrix[row, col] := unused END;
  ASSERT(calls = 4); ASSERT(boundsLog = 2134); ASSERT(matrix[2, 4] = 24);
  ALL row = 0 .. 3, col = 100 .. 99 DO matrix[row, col] := unused END;
  ALL row = 100 .. 99, col = 0 .. 4 DO matrix[row, col] := unused END;
  ALL row = 0 .. 0, col = 0 .. 0 DO END;
  ALL row = 2 .. 2, col = 3 .. 3 DO scalar := row*10+col END;
  ASSERT(scalar = 23);
  low := -1; high := 1;
  ALL row = low .. high, col = -2 .. 2 DO matrix[row+1, col+2] := row*10+col END;
  ASSERT(matrix[0, 0] = -12); ASSERT(matrix[2, 4] = 12);
  i := 1; j := 2;
  ALL i = i .. j, j = i .. j DO square[i, j] := i*10+j END;
  ASSERT(i = 1); ASSERT(j = 2); ASSERT(square[2, 2] = 22);
  ALL row = MAX(HUGEINT)-1 .. MAX(HUGEINT), col = MIN(HUGEINT) .. MIN(HUGEINT)+1 DO
    wide[row-(MAX(HUGEINT)-1), col-MIN(HUGEINT)] := row
  END;
  ASSERT(wide[0, 0] = MAX(HUGEINT)-1); ASSERT(wide[1, 1] = MAX(HUGEINT));
  ALL row = MIN(HUGEINT) .. MIN(HUGEINT)+1, col = MAX(HUGEINT)-1 .. MAX(HUGEINT) DO
    wide[row-MIN(HUGEINT), col-(MAX(HUGEINT)-1)] := col
  END;
  ASSERT(wide[0, 0] = MAX(HUGEINT)-1); ASSERT(wide[1, 1] = MAX(HUGEINT));
  Process(matrix); Enclosing;
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 4 DO ASSERT(matrix[i, j] = i*10+j); ASSERT(copy[i, j] = i*10+j+100) END
  END;
  Out.String("multidimensional ALL tests passed"); Out.Ln
END TestMultiAll.
