MODULE TestSsqInput;
IMPORT Sys := ssqSys, Types := ssqTypes, Int;
VAR mode, value: ARRAY 32 OF CHAR; line: ARRAY 8 OF CHAR; result: Types.Integer;
BEGIN
  ASSERT(Sys.Argv(mode, 1));
  IF mode = 'badfd' THEN result := Sys.ReadKeys(line); ASSERT(result < 0)
  ELSIF mode = 'eof' THEN result := Sys.ReadKeys(line); ASSERT(result = 0)
  ELSE
    result := Sys.ReadLine(line);
    Int.Show(value, result, 0); Sys.Out(value); Sys.OutChr(0AX);
    Sys.Out(line); Sys.OutChr(0AX)
  END
END TestSsqInput.
