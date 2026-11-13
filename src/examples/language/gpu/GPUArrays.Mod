MODULE GPUArrays;

PROCEDURE Scale*(VAR values: ARRAY OF REAL; factor: REAL);
BEGIN
  ALL i = 0 .. LEN(values)-1 WITH t: REAL DO
    t := values[i] * factor;
    values[i] := t
  END
END Scale;

END GPUArrays.
