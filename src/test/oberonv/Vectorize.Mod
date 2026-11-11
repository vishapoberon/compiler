MODULE Vectorize;
CONST n = 1048576;
VAR a*, b*: ARRAY n OF REAL;

PROCEDURE Scale*;
BEGIN
  ALL i = 0 .. n-1 DO a[i] := b[i] * 2 END
END Scale;

END Vectorize.
