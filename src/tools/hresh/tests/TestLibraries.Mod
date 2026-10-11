MODULE TestLibraries;
  (* Check every bundled .so's relocations and ABI without running arbitrary
     initializers (notably the graphical modules), then exercise a long name. *)
  IMPORT SYSTEM, Modules, ModuleLoader, Files, Heap, Out;
  VAR list: Files.File; reader: Files.Rider; ch: CHAR;
    filename: ARRAY 4096 OF CHAR; name: ARRAY 64 OF CHAR;
    error: ARRAY 1024 OF CHAR; model: ARRAY 3 OF CHAR;
    length, count: INTEGER; handle: SYSTEM.ADDRESS; m: Modules.Module;
    command: Modules.Command;

  PROCEDURE -AInclude '#include "SharedModulesSupport.h"';
  PROCEDURE -Open(name, path, model: ARRAY OF CHAR;
      ss, is, ls, sets: SYSTEM.INT32; VAR error: ARRAY OF CHAR): SYSTEM.ADDRESS
    'VOCShared_open((char*)name, (char*)path, (char*)model, ss, is, ls, sets, (char*)error, error__len)';

  PROCEDURE Check;
  BEGIN
    name[length] := 0X;
    IF length > 0 THEN
      handle := Open(name, ModuleLoader.path, model, SIZE(SHORTINT), SIZE(INTEGER),
        SIZE(LONGINT), SIZE(SET), error);
      IF handle = 0 THEN Out.String(name); Out.String(": "); Out.String(error); Out.Ln END;
      ASSERT(handle # 0); INC(count)
    END;
    length := 0
  END Check;

BEGIN
  ASSERT(Modules.ArgCount = 4);
  Modules.GetArg(1, filename); Modules.GetArg(2, ModuleLoader.path);
  IF SIZE(INTEGER) = 2 THEN model := "O2"
  ELSIF SIZE(SHORTINT) = 2 THEN model := "OC" ELSE model := "OV" END;
  list := Files.Old(filename); ASSERT(list # NIL); Files.Set(reader, list, 0);
  Files.Read(reader, ch);
  WHILE ~reader.eof DO
    IF ch = 0AX THEN Check
    ELSIF ch # 0DX THEN ASSERT(length < LEN(name) - 1); name[length] := ch; INC(length)
    END;
    Files.Read(reader, ch)
  END;
  IF length > 0 THEN Check END;
  ASSERT(count > 100);
  m := ModuleLoader.ThisMod("ulmPersistentDisciplines");
  IF m = NIL THEN Out.String(ModuleLoader.resMsg); Out.Ln END;
  ASSERT(m # NIL); ASSERT(m.name = "ulmPersistentDisciplines");
  ASSERT(ModuleLoader.ThisMod("ulmPersistentDisciplines") = m);
  Modules.GetArg(3, ModuleLoader.path);
  m := ModuleLoader.ThisMod("LongModuleRegistryNames"); ASSERT(m # NIL);
  ASSERT(m.name = "LongModuleRegistryNames");
  command := Modules.ThisCommand(m, "LongCommandRegistryNamesAreNotTruncated");
  ASSERT(command # NIL); command();
  Heap.GC(TRUE);
  Out.Int(count, 0); Out.String(" bundled shared libraries passed ABI/load checks"); Out.Ln
END TestLibraries.
