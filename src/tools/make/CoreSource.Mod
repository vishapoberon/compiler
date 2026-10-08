MODULE CoreSource;
  (* Prepare the modular Heap source without changing the compatibility Heap.
     The two registry constants are checked so a changed template fails loudly. *)
  IMPORT SYSTEM, Files, Modules, Platform, Out;
  VAR input, output: Files.File; reader, writer: Files.Rider;
    source, target: ARRAY 4096 OF CHAR; line: ARRAY 2048 OF CHAR;
    ch: CHAR; length, modules, commands: INTEGER;

  PROCEDURE Fail(message: ARRAY OF CHAR);
  BEGIN Out.String(message); Out.Ln; Platform.Exit(1) END Fail;

  PROCEDURE WriteLine;
    VAR i: INTEGER;
  BEGIN
    line[length] := 0X;
    IF line = "    ModNameLen    = 20;" THEN
      line := "    ModNameLen    = 64;"; INC(modules)
    ELSIF line = "    CmdNameLen    = 24;" THEN
      line := "    CmdNameLen    = 64;"; INC(commands)
    END;
    i := 0; WHILE line[i] # 0X DO Files.Write(writer, line[i]); INC(i) END;
    Files.Write(writer, 0AX);
    IF writer.res # 0 THEN Fail("Cannot write modular Heap source.") END;
    length := 0
  END WriteLine;

BEGIN
  IF Modules.ArgCount # 3 THEN Fail("Usage: CoreSource input-Heap.Mod output-Heap.Mod") END;
  Modules.GetArg(1, source); Modules.GetArg(2, target);
  IF source = target THEN Fail("The modular source must not overwrite the compatibility source.") END;
  input := Files.Old(source); IF input = NIL THEN Fail("Cannot read Heap source.") END;
  output := Files.New(target); IF output = NIL THEN Fail("Cannot create modular Heap source.") END;
  Files.Set(reader, input, 0); Files.Set(writer, output, 0);
  Files.Read(reader, ch);
  WHILE ~reader.eof DO
    IF ch = 0AX THEN WriteLine
    ELSIF ch # 0DX THEN
      IF length >= LEN(line) - 1 THEN Fail("Heap source line is too long.") END;
      line[length] := ch; INC(length)
    END;
    Files.Read(reader, ch)
  END;
  IF length > 0 THEN WriteLine END;
  IF (modules # 1) OR (commands # 1) THEN Fail("Heap registry constants changed; update CoreSource.") END;
  Files.Register(output)
END CoreSource.
