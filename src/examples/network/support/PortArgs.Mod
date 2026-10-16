MODULE PortArgs;
(* Keep standalone argv intact, including blanks. Hosted commands use the
   command text supplied by hresh, not the shell host's process arguments. *)
IMPORT Modules, Texts, Oberon;
TYPE Reader* = RECORD
  text: Texts.Reader;
  ch: CHAR;
  next: INTEGER;
  valid: BOOLEAN
END;
VAR first: INTEGER;

PROCEDURE FromCLI*(start: INTEGER);
BEGIN first := start
END FromCLI;

PROCEDURE OpenArgs*(VAR reader: Reader);
BEGIN
  reader.valid := TRUE; reader.next := first;
  IF first = 0 THEN
    Texts.OpenReader(reader.text, Oberon.Par.text, Oberon.Par.pos);
    Texts.Read(reader.text, reader.ch)
  END
END OpenArgs;

PROCEDURE Arg*(VAR reader: Reader; VAR value: ARRAY OF CHAR): BOOLEAN;
VAR n: LONGINT; quote: CHAR;
BEGIN
  IF LEN(value) = 0 THEN reader.valid := FALSE; RETURN FALSE END;
  value[0] := 0X;
  IF ~reader.valid THEN RETURN FALSE END;
  IF first # 0 THEN
    IF reader.next >= Modules.ArgCount THEN RETURN FALSE END;
    Modules.GetArg(reader.next, value); INC(reader.next); RETURN TRUE
  END;
  WHILE (reader.ch # 0X) & (reader.ch <= " ") DO Texts.Read(reader.text, reader.ch) END;
  IF reader.ch = 0X THEN RETURN FALSE END;
  quote := 0X; n := 0;
  IF (reader.ch = 22X) OR (reader.ch = 27X) THEN quote := reader.ch; Texts.Read(reader.text, reader.ch) END;
  WHILE (reader.ch # 0X) & (((quote = 0X) & (reader.ch > " ")) OR ((quote # 0X) & (reader.ch # quote))) DO
    IF n >= LEN(value) - 1 THEN reader.valid := FALSE; RETURN FALSE END;
    value[n] := reader.ch; INC(n); Texts.Read(reader.text, reader.ch)
  END;
  value[n] := 0X;
  IF quote # 0X THEN
    IF reader.ch # quote THEN reader.valid := FALSE; RETURN FALSE END;
    Texts.Read(reader.text, reader.ch);
    IF reader.ch > " " THEN reader.valid := FALSE; RETURN FALSE END
  END;
  RETURN TRUE
END Arg;

BEGIN first := 0
END PortArgs.
