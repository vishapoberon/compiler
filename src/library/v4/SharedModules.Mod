MODULE SharedModules;

  (* Module loading and command discovery for Unix command hosts. ModuleLoader
     uses VOC's registry and keeps initialized libraries mapped for GC safety. *)

  IMPORT SYSTEM, Platform, Modules, ModuleLoader, CommandSymbols;

  TYPE
    Module* = Modules.Module;
    Command* = Modules.Command;
    Visitor* = CommandSymbols.Visitor;
    CommandRef* = POINTER TO CommandRefDesc;
    CommandRefDesc = RECORD
      command: Command; retention: Modules.Retention
    END;

  VAR
    path*: ARRAY 4096 OF CHAR;
    res*: INTEGER;
    resMsg*: ARRAY 1024 OF CHAR;
    model: ARRAY 3 OF CHAR;

  PROCEDURE -AInclude '#include "SharedModulesSupport.h"';

  PROCEDURE -DiskModules(search, model: ARRAY OF CHAR; visit: Visitor)
    'VOCShared_modules((char*)search, (char*)model, visit)';

  PROCEDURE -FindSymbol(name, search, model: ARRAY OF CHAR;
      VAR filename: ARRAY OF CHAR): BOOLEAN
    'VOCShared_symbol((char*)name, (char*)search, (char*)model, (char*)filename, filename__len)';

  PROCEDURE SymbolFile*(name: ARRAY OF CHAR; VAR filename: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN FindSymbol(name, path, model, filename)
  END SymbolFile;

  PROCEDURE First*(): Module;
  BEGIN RETURN ModuleLoader.First()
  END First;

  PROCEDURE ThisMod*(name: ARRAY OF CHAR): Module;
    VAR m: Module;
  BEGIN
    COPY(path, ModuleLoader.path); m := ModuleLoader.ThisMod(name);
    res := ModuleLoader.res; COPY(ModuleLoader.resMsg, resMsg);
    RETURN m
  END ThisMod;

  PROCEDURE ThisCommand*(m: Module; name: ARRAY OF CHAR): Command;
    VAR cmd: Command;
  BEGIN
    IF m = NIL THEN res := 1; resMsg := "module not loaded"; RETURN NIL END;
    cmd := Modules.ThisCommand(m, name);
    res := Modules.res; COPY(Modules.resMsg, resMsg);
    RETURN cmd
  END ThisCommand;

  PROCEDURE AcquireCommand*(m: Module; name: ARRAY OF CHAR): CommandRef;
    VAR r: CommandRef; retention: Modules.Retention; command: Command;
  BEGIN
    Platform.CommandCritical(TRUE);
    retention := Modules.Retain(m);
    IF retention # NIL THEN
      command := ThisCommand(m, name);
      IF command # NIL THEN
        NEW(r); r.command := command; r.retention := retention
      ELSE Modules.Release(retention) END
    ELSE res := Modules.res; COPY(Modules.resMsg, resMsg)
    END;
    Platform.CommandCritical(FALSE);
    RETURN r
  END AcquireCommand;

  PROCEDURE Invoke*(r: CommandRef);
  BEGIN
    IF (r # NIL) & (r.command # NIL) THEN res := 0; resMsg := ""; r.command
    ELSE res := 1; resMsg := "command reference has been released"
    END
  END Invoke;

  PROCEDURE ReleaseCommand*(VAR r: CommandRef);
  BEGIN
    Platform.CommandCritical(TRUE);
    IF r # NIL THEN
      r.command := NIL;
      IF r.retention # NIL THEN Modules.Release(r.retention) END;
      r := NIL
    END;
    Platform.CommandCritical(FALSE)
  END ReleaseCommand;

  PROCEDURE EnumerateModules*(visit: Visitor);
    VAR m: Module;
  BEGIN
    m := First();
    WHILE m # NIL DO visit(m.name); m := m.next END;
    DiskModules(path, model, visit)
  END EnumerateModules;

  PROCEDURE EnumerateCommands*(name: ARRAY OF CHAR; visit: Visitor): BOOLEAN;
    VAR m: Module; c: Modules.Cmd; filename: ARRAY 8192 OF CHAR; valid: BOOLEAN;
  BEGIN
    m := Modules.ThisMod(name);
    IF m # NIL THEN
      c := m.cmds;
      WHILE c # NIL DO visit(c.name); c := c.next END;
      res := 0; resMsg := ""; RETURN TRUE
    ELSE
      (* Read symbols, without dlopen or module initialization. *)
      IF SymbolFile(name, filename) THEN
        valid := CommandSymbols.Enumerate(filename, name, visit);
        IF valid THEN res := 0; resMsg := ""; RETURN TRUE END;
        resMsg := "invalid or unsupported symbol file"
      ELSE
        resMsg := "symbol file not found (set VOC_SYM_PATH if symbols are elsewhere)"
      END
    END;
    res := 1; RETURN FALSE
  END EnumerateCommands;

BEGIN
  IF SIZE(INTEGER) = 2 THEN model := "O2"
  ELSIF SIZE(SHORTINT) = 2 THEN model := "OC"
  ELSE model := "OV"
  END;
  COPY(ModuleLoader.path, path)
END SharedModules.
