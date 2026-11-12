MODULE ParallelArrays;
IMPORT Out, Platform;
CONST n = 8388608; repeats = 64;
VAR
  a, b: ARRAY n OF REAL;
  i, pass, start, elapsed: LONGINT;
BEGIN
  FOR i := 0 TO n-1 DO a[i] := i MOD 16; b[i] := i MOD 7 + 1 END;
  start := Platform.Time();
  FOR pass := 1 TO repeats DO
    ALL r = 0 .. n-1 DO a[r] := a[r] + b[r]; b[r] := b[r] + 1 END
  END;
  elapsed := Platform.Time() - start;
  FOR i := 0 TO n-1 DO
    ASSERT(a[i] = i MOD 16 + repeats * (i MOD 7 + 1) + repeats * (repeats-1) DIV 2);
    ASSERT(b[i] = i MOD 7 + 1 + repeats)
  END;
  Out.String("array elapsed ms: "); Out.Int(elapsed, 0); Out.Ln;
  Out.String("parallel array tests passed"); Out.Ln
END ParallelArrays.
