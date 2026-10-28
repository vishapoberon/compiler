MODULE PictureArgs;

IMPORT Args;

TYPE Reader* = RECORD next: INTEGER END;

VAR first: INTEGER;

PROCEDURE Start*(index: INTEGER);
BEGIN IF index < 1 THEN first := 1 ELSE first := index END END Start;

PROCEDURE OpenArgs*(VAR reader: Reader);
BEGIN reader.next := first END OpenArgs;

PROCEDURE Arg*(VAR reader: Reader; VAR value: ARRAY OF CHAR): BOOLEAN;
  VAR input: ARRAY 4096 OF CHAR; length, i: LONGINT;
BEGIN
  IF LEN(value) = 0 THEN RETURN FALSE END;
  IF reader.next = MAX(INTEGER) THEN value[0] := 0X; RETURN FALSE END;
  input[0] := 0X; Args.Get(reader.next, input); INC(reader.next);
  length := 0; WHILE input[length] # 0X DO INC(length) END;
  IF (length = 0) OR (length >= LEN(value)) THEN value[0] := 0X; RETURN FALSE END;
  FOR i := 0 TO length DO value[i] := input[i] END;
  RETURN TRUE
END Arg;

BEGIN first := 1
END PictureArgs.
