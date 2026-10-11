MODULE system;

  IMPORT Modules, SharedModules, Heap, Texts, Oberon, Out, Platform;

  PROCEDURE ShowModules*;
    VAR m: Modules.Module;
  BEGIN
    Out.String("Loaded modules (import references plus runtime pin):"); Out.Ln;
    m := SharedModules.First();
    WHILE m # NIL DO
      Out.String("  "); Out.String(m.name); Out.String("  "); Out.Int(m.refcnt, 0); Out.Ln;
      IF Heap.Retained(m) # 0 THEN
        Out.String("    retained references: "); Out.Int(Heap.Retained(m), 0); Out.Ln
      END;
      IF Heap.ModuleState(m) = 4 THEN
        Out.String("    finalized and disabled (restart required)"); Out.Ln
      END;
      m := m.next
    END
  END ShowModules;

  PROCEDURE WriteCommand(name: ARRAY OF CHAR);
  BEGIN Out.String("  "); Out.String(name); Out.Ln
  END WriteCommand;

  PROCEDURE ShowCommands*;
    VAR scanner: Texts.Scanner; done: BOOLEAN;
  BEGIN
    Texts.OpenScanner(scanner, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(scanner);
    IF ((scanner.class = Texts.Name) OR (scanner.class = Texts.String)) &
        (scanner.len < LEN(scanner.s) - 1) THEN
      done := SharedModules.EnumerateCommands(scanner.s, WriteCommand);
      IF ~done THEN Out.String(SharedModules.resMsg); Out.Ln END
    ELSE Out.String("usage: system.ShowCommands module"); Out.Ln
    END
  END ShowCommands;

  PROCEDURE Free*;
    VAR scanner: Texts.Scanner; count: INTEGER;
  BEGIN
    Texts.OpenScanner(scanner, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(scanner);
    count := 0;
    WHILE (scanner.class = Texts.Name) OR (scanner.class = Texts.String) DO
      IF scanner.len >= LEN(scanner.s) - 1 THEN
        Out.String("system.Free: module name is too long"); Out.Ln; RETURN
      END;
      Modules.Free(scanner.s, FALSE);
      Out.String(scanner.s); Out.String(": ");
      IF Modules.res = 0 THEN Out.String("freed") ELSE Out.String(Modules.resMsg) END;
      Out.Ln; INC(count); Texts.Scan(scanner)
    END;
    IF (count = 0) OR (~scanner.eot & ((scanner.class # Texts.Char) OR (scanner.c # "~"))) THEN
      Out.String("usage: system.Free module [module ...] [~]"); Out.Ln
    END
  END Free;

  PROCEDURE Collect*;
  BEGIN
    Heap.GC(TRUE);
    Out.String("Heap bytes in use: "); Out.Int(Heap.allocated, 0); Out.Ln
  END Collect;

  PROCEDURE Directory*;
    VAR scanner: Texts.Scanner; path, name: ARRAY 256 OF CHAR;
      directory: Platform.DirectoryHandle; error: Platform.ErrorCode; done: BOOLEAN;
  BEGIN
    Texts.OpenScanner(scanner, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(scanner);
    path := ".";
    IF (scanner.class = Texts.Name) OR (scanner.class = Texts.String) THEN
      IF scanner.len >= LEN(scanner.s) - 1 THEN
        Out.String("system.Directory: directory name is too long"); Out.Ln; RETURN
      END;
      COPY(scanner.s, path)
    ELSIF ~scanner.eot OR (scanner.class # Texts.Char) OR (scanner.c # 0X) THEN
      Out.String("usage: system.Directory [directory]"); Out.Ln; RETURN
    END;
    Platform.CommandCritical(TRUE);
    error := Platform.OpenDirectory(path, directory);
    IF error # 0 THEN
      Platform.CommandCritical(FALSE); Out.String("system.Directory: cannot open directory"); Out.Ln; RETURN
    END;
    REPEAT
      error := Platform.ReadDirectory(directory, name, done);
      IF (error = 0) & ~done THEN Out.String(name); Out.Ln END
    UNTIL done OR (error # 0);
    error := Platform.CloseDirectory(directory);
    Platform.CommandCritical(FALSE)
  END Directory;

END system.
