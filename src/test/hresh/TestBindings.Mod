MODULE TestBindings;
(* Inspect selected native binding libraries without calling their initializers
   or opening a display. Base-library regressions have their own test target. *)
IMPORT SYSTEM, Modules, Files, Out, NativeLibraries, NativeModules;
VAR list: Files.File; reader: Files.Rider; ch: CHAR;
  filename, search: ARRAY 4096 OF CHAR; name: ARRAY 64 OF CHAR;
  error: ARRAY 1024 OF CHAR; length, count: INTEGER;

PROCEDURE Check;
  VAR handle: SYSTEM.ADDRESS;
BEGIN
  name[length] := 0X;
  IF length > 0 THEN
    handle := NativeLibraries.Open(name, search, "O2", error);
    IF handle = 0 THEN Out.String(name); Out.String(": "); Out.String(error); Out.Ln END;
    ASSERT(handle # 0); ASSERT(NativeModules.Close(handle)); INC(count)
  END;
  length := 0
END Check;

BEGIN
  ASSERT(Modules.ArgCount = 3);
  Modules.GetArg(1, filename); Modules.GetArg(2, search);
  list := Files.Old(filename); ASSERT(list # NIL); Files.Set(reader, list, 0);
  Files.Read(reader, ch);
  WHILE ~reader.eof DO
    IF ch = 0AX THEN Check
    ELSIF ch # 0DX THEN ASSERT(length < LEN(name) - 1); name[length] := ch; INC(length)
    END;
    Files.Read(reader, ch)
  END;
  IF length > 0 THEN Check END;
  Out.Int(count, 0); Out.String(" selected binding libraries passed ABI/load checks"); Out.Ln
END TestBindings.
