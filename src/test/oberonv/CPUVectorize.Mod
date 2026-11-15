MODULE CPUVectorize;
IMPORT SYSTEM;
VAR input*, output*: ARRAY 64, 128 OF REAL;
  values*: ARRAY 4096 OF SYSTEM.INT64;
  factor*, bias*: REAL;

PROCEDURE Grid*;
BEGIN
  ALL row = 0 .. 63, col = 0 .. 127 DO
    output[row, col] := input[row, col] * factor + bias
  END
END Grid;

PROCEDURE Grid16*;
BEGIN
  ALL row = 0 .. 63, col = 0 .. 127 WITH t: REAL DO
    t := input[row, col];
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    t := t * factor + bias; t := t * factor + bias;
    output[row, col] := t
  END
END Grid16;

PROCEDURE Sum*(): SYSTEM.INT64;
BEGIN
  RETURN SUM([i = 0 .. 4095: values[i]])
END Sum;

END CPUVectorize.
