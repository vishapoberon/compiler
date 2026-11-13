MODULE UseGPU;
IMPORT GPUArrays, Out;
VAR values: ARRAY 1024 OF REAL; i: LONGINT;
BEGIN
  FOR i := 0 TO LEN(values)-1 DO values[i] := i END;
  GPUArrays.Scale(values, 2);
  FOR i := 0 TO LEN(values)-1 DO ASSERT(values[i] = i * 2) END;
  Out.String("array results passed"); Out.Ln
END UseGPU.
