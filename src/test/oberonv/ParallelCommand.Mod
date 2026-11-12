MODULE ParallelCommand;
IMPORT Out;
CONST n = 8388608;
VAR a: ARRAY n OF REAL;

PROCEDURE Run*;
VAR pass: LONGINT;
BEGIN
  Out.String("parallel command started"); Out.Ln;
  FOR pass := 1 TO 1024 DO
    ALL i = 0 .. n-1 DO a[i] := a[i] + 1 END
  END;
  Out.String("parallel command finished"); Out.Ln
END Run;

PROCEDURE Check*;
VAR i: LONGINT;
BEGIN
  ALL r = 0 .. n-1 WITH t: LONGINT DO t := r MOD 16; a[r] := t END;
  FOR i := 0 TO n-1 DO ASSERT(a[i] = i MOD 16) END;
  Out.String("parallel command recovered"); Out.Ln
END Check;

END ParallelCommand.
