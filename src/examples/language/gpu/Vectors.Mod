MODULE Vectors;
IMPORT Out;
VAR values: ARRAY 16 OF REAL; i: LONGINT;
BEGIN
  ALL r = 0 .. LEN(values)-1 DO values[r] := r * 2 END;
  FOR i := 0 TO LEN(values)-1 DO ASSERT(values[i] = i * 2) END;
  Out.String("vector results passed"); Out.Ln
END Vectors.
