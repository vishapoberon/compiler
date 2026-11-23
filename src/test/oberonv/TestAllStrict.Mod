MODULE TestAllStrict;
IMPORT Out;
TYPE
  Vector = ARRAY 4 OF INTEGER;
  Cell = RECORD left, right: INTEGER END;
  Buffer = POINTER TO Vector;
  State = RECORD input, output: Vector; bias: INTEGER END;
VAR a, b: Vector; cells: ARRAY 4 OF Cell;
  record: State;
  matrix: ARRAY 4, 2 OF INTEGER; p: Buffer;
  i, base, low, high, checks: INTEGER;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN
    Out.String("TestAllStrict: "); Out.Int(checks, 0); Out.String(" checks, 1 failed"); Out.Ln; HALT(100)
  END
END Check;

PROCEDURE Scale(VAR values: ARRAY OF INTEGER; factor: INTEGER);
BEGIN
  ALL r = 0 .. LEN(values)-1 DO values[r] := values[r] * factor END
END Scale;

PROCEDURE Snapshot(VAR dst: ARRAY OF INTEGER; src: ARRAY OF INTEGER);
BEGIN
  ALL r = 0 .. 2 DO dst[r] := src[r+1] END
END Snapshot;

PROCEDURE ReadAliases(VAR x, y: ARRAY OF INTEGER);
  VAR output: Vector; k: INTEGER;
BEGIN
  ALL r = 0 .. 3 DO output[r] := x[r] + y[r] END;
  FOR k := 0 TO 3 DO b[k] := output[k] END
END ReadAliases;

PROCEDURE RecordFields(VAR values: State);
BEGIN
  ALL r = 0 .. 3 DO values.output[r] := values.input[r] + values.bias END
END RecordFields;

PROCEDURE HeapValues(values: Buffer);
BEGIN
  ALL r = 0 .. 3 DO values[r] := values[r]+1 END
END HeapValues;

BEGIN
  ALL r = 0 .. 3 DO a[r] := r; b[r] := a[r]+1 END;
  FOR i := 0 TO 3 DO Check((a[i] = i) & (b[i] = i+1)) END;
  Scale(a, 2);
  FOR i := 0 TO 3 DO Check(a[i] = i*2) END;
  ReadAliases(a, a);
  FOR i := 0 TO 3 DO Check(b[i] = i*4) END;
  Snapshot(a, a);
  Check((a[0] = 2) & (a[1] = 4) & (a[2] = 6) & (a[3] = 6));
  ALL r = 0 .. 3 DO cells[r].left := r; cells[r].right := cells[r].left+10 END;
  ALL r = 0 .. 3 DO cells[r].left := cells[r].right+1 END;
  FOR i := 0 TO 3 DO Check((cells[i].left = i+11) & (cells[i].right = i+10)) END;
  record.bias := 3;
  ALL r = 0 .. 3 DO record.input[r] := r; record.output[r] := record.input[r]+record.bias END;
  FOR i := 0 TO 3 DO Check(record.output[i] = i+3) END;
  RecordFields(record);
  FOR i := 0 TO 3 DO Check(record.output[i] = i+3) END;
  ALL r = 0 .. 3 DO matrix[r, 0] := r; matrix[r, 1] := r+7 END;
  ALL r = 0 .. 3 DO matrix[r, 0] := matrix[r, 1] END;
  FOR i := 0 TO 3 DO Check(matrix[i, 0] = i+7) END;
  ALL r = 0 .. 3 DO a[3-r] := r END;
  ALL r = 0 .. 3 DO a[3-r] := a[3-r]+1 END;
  FOR i := 0 TO 3 DO Check(a[i] = 4-i) END;
  base := -7; low := base; high := base+3;
  ALL r = low .. high DO a[r-base] := r END;
  FOR i := 0 TO 3 DO Check(a[i] = base+i) END;
  NEW(p);
  ALL r = 0 .. 3 DO p[r] := r END;
  ALL r = 0 .. 3 DO p[r] := p[r]+1 END;
  HeapValues(p);
  FOR i := 0 TO 3 DO Check(p[i] = i+2) END;
  Out.String("TestAllStrict: "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END TestAllStrict.
