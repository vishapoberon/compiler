MODULE CommandArgs;

IMPORT Texts, Oberon;

TYPE Reader* = RECORD
  text: Texts.Reader;
  ch: CHAR;
  valid-: BOOLEAN
END;

PROCEDURE OpenArgs*(VAR r: Reader);
BEGIN
  Texts.OpenReader(r.text, Oberon.Par.text, Oberon.Par.pos);
  Texts.Read(r.text, r.ch); r.valid := TRUE
END OpenArgs;

PROCEDURE Arg*(VAR r: Reader; VAR value: ARRAY OF CHAR): BOOLEAN;
VAR n: LONGINT; quote: CHAR;
BEGIN
  IF LEN(value) = 0 THEN r.valid := FALSE; RETURN FALSE END;
  value[0] := 0X;
  IF ~r.valid THEN RETURN FALSE END;
  WHILE (r.ch # 0X) & (r.ch <= " ") DO Texts.Read(r.text, r.ch) END;
  IF r.ch = 0X THEN RETURN FALSE END;
  quote := 0X; n := 0;
  IF (r.ch = 22X) OR (r.ch = 27X) THEN
    quote := r.ch; Texts.Read(r.text, r.ch)
  END;
  WHILE (r.ch # 0X) & (((quote = 0X) & (r.ch > " ")) OR
      ((quote # 0X) & (r.ch # quote))) DO
    IF n >= LEN(value) - 1 THEN r.valid := FALSE; RETURN FALSE END;
    value[n] := r.ch; INC(n); Texts.Read(r.text, r.ch)
  END;
  value[n] := 0X;
  IF quote # 0X THEN
    IF r.ch # quote THEN r.valid := FALSE; RETURN FALSE END;
    Texts.Read(r.text, r.ch);
    IF r.ch > " " THEN r.valid := FALSE; RETURN FALSE END
  END;
  IF n = 0 THEN r.valid := FALSE; RETURN FALSE END;
  RETURN TRUE
END Arg;

END CommandArgs.
