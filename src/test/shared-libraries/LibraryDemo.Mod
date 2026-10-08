MODULE LibraryDemo;
  IMPORT oocStrings, ooc2IntStr, Math, Out, Oberon, Texts;
  VAR calls: LONGINT;

  PROCEDURE Run*;
    VAR text: ARRAY 64 OF CHAR; number: ARRAY 32 OF CHAR;
  BEGIN
    text := "native"; oocStrings.Capitalize(text);
    oocStrings.Append(" MODULES", text);
    ASSERT(text = "NATIVE MODULES");
    ooc2IntStr.IntToStr(42, number); ASSERT(number = "42");
    ASSERT(ABS(Math.sqrt(16.0) - 4.0) < 0.001);
    Out.String(text); Out.Ln;
    Out.String("sqrt(16) = "); Out.Int(ENTIER(Math.sqrt(16.0)), 0); Out.Ln;
    Out.String("integer = "); Out.String(number); Out.Ln;
    INC(calls); Out.String("calls: "); Out.Int(calls, 0); Out.Ln
  END Run;

  PROCEDURE Echo*;
    VAR reader: Texts.Reader; ch: CHAR;
  BEGIN
    Texts.OpenReader(reader, Oberon.Par.text, Oberon.Par.pos);
    WHILE ~reader.eot DO Texts.Read(reader, ch); IF ~reader.eot THEN Out.Char(ch) END END;
    Out.Ln
  END Echo;
END LibraryDemo.
