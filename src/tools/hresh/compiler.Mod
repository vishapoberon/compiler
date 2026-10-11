MODULE compiler;

  IMPORT Compiler, Texts, Oberon, Files, Strings, Out;

  TYPE Argument = POINTER TO ArgumentDesc;
    ArgumentDesc = RECORD next: Argument; value: ARRAY 256 OF CHAR END;
  VAR first: Argument;
    res*: INTEGER;
    busy: BOOLEAN;
    previousPath: ARRAY 4096 OF CHAR;
    pathSaved: BOOLEAN;

  PROCEDURE Stopped;
  BEGIN
    IF busy THEN
      Compiler.Abort;
      IF pathSaved THEN Files.SetSearchPath(previousPath); pathSaved := FALSE END;
      first := NIL; busy := FALSE; res := 1
    END
  END Stopped;

  PROCEDURE GetArgument(n: INTEGER; VAR value: ARRAY OF CHAR);
    VAR argument: Argument;
  BEGIN
    value[0] := 0X; argument := first;
    WHILE (n > 1) & (argument # NIL) DO DEC(n); argument := argument.next END;
    IF (n = 1) & (argument # NIL) THEN COPY(argument.value, value) END
  END GetArgument;

  PROCEDURE Compile*;
    VAR reader: Texts.Scanner; value: ARRAY 256 OF CHAR;
      argument, last: Argument; count: INTEGER; done, valid: BOOLEAN;
  BEGIN
    IF busy THEN Out.String("compiler.Compile: already compiling"); Out.Ln; RETURN END;
    Oberon.OnStop(Stopped);
    busy := TRUE;
    first := NIL; count := 1; res := 1;
    Texts.OpenScanner(reader, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(reader); valid := TRUE;
    LOOP
      IF reader.eot & (reader.class = Texts.Char) & (reader.c = 0X) THEN EXIT END;
      value := "";
      IF (reader.class = Texts.Char) & (reader.c = "-") THEN
        value := "-"; Texts.Scan(reader)
      END;
      IF (reader.class # Texts.Name) & (reader.class # Texts.String) THEN
        valid := FALSE; EXIT
      END;
      IF reader.len >= LEN(reader.s) - 1 THEN valid := FALSE; EXIT END;
      Strings.Append(reader.s, value);
      IF count = MAX(INTEGER) THEN valid := FALSE; EXIT END;
      NEW(argument); COPY(value, argument.value);
      IF first = NIL THEN first := argument ELSE last.next := argument END;
      last := argument; INC(count); Texts.Scan(reader)
    END;
    IF ~valid THEN
      Out.String("compiler.Compile: invalid or overlong arguments"); Out.Ln
    ELSE
      IF Files.GetSearchPath(previousPath) THEN
        pathSaved := TRUE;
        done := Compiler.CompileArguments(count, GetArgument);
        Files.SetSearchPath(previousPath); pathSaved := FALSE;
        IF done THEN res := 0 END
      ELSE Out.String("compiler.Compile: existing file search path is too long"); Out.Ln
      END
    END;
    first := NIL; busy := FALSE
  END Compile;

END compiler.
