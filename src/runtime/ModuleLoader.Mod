MODULE ModuleLoader;

  (* Native module loading shared by command hosts and generated launchers.
     No command discovery, editor or application libraries are needed here. *)
  IMPORT SYSTEM, Platform, Heap, Modules, NativeModules, NativeLibraries;

  TYPE
    Module* = Modules.Module;
    ModuleBody = NativeLibraries.Body;
    Loaded = POINTER TO LoadedDesc;
    LoadedDesc = RECORD
      next: Loaded; owner: Module; pin: NativeLibraries.Pin;
      error: ARRAY 256 OF CHAR
    END;
    SavedImport = POINTER TO SavedImportDesc;
    SavedImportDesc = RECORD next: SavedImport; name: Modules.ModuleName END;

  VAR
    path*: ARRAY 4096 OF CHAR;
    res*: INTEGER;
    resMsg*: ARRAY 1024 OF CHAR;
    model: ARRAY 3 OF CHAR;
    loaded: Loaded;
    freeing, damaged: BOOLEAN;

  PROCEDURE Registered(owner: Module; initializer: SYSTEM.ADDRESS);
    VAR l: Loaded;
  BEGIN
    NEW(l); l.owner := owner;
    IF ~NativeLibraries.Acquire(initializer, l.pin, l.error) THEN
      (* Without its own native reference, an import's registered GC roots
         could be unmapped when a client is unloaded. *)
      Modules.Halt(-15)
    END;
    l.next := loaded; loaded := l
  END Registered;

  PROCEDURE First*(): Module;
  BEGIN RETURN SYSTEM.VAL(Module, Heap.modules)
  END First;

  PROCEDURE ThisMod*(name: ARRAY OF CHAR): Module;
    VAR m: Module; handle: SYSTEM.ADDRESS; body: ModuleBody; closed: BOOLEAN;
  BEGIN
    m := Modules.ThisMod(name);
    IF (m # NIL) & (Heap.ModuleState(m) > 2) THEN
      res := 1; resMsg := "module is terminating or disabled; restart the host"; RETURN NIL
    END;
    IF m = NIL THEN
      Platform.CommandCritical(TRUE); (* An initializer must finish or terminate the host, not unwind. *)
      handle := NativeLibraries.Open(name, path, model, resMsg);
      IF handle = 0 THEN res := 1; Platform.CommandCritical(FALSE); RETURN NIL END;
      body := NativeLibraries.Initializer(handle, name);
      m := SYSTEM.VAL(Module, body());
      IF (m = NIL) OR (m.name # name) THEN
        (* Initializers may leave live GC roots even when they fail. *)
        res := 1; resMsg := "initializer did not register the requested module";
        Platform.CommandCritical(FALSE);
        RETURN NIL
      END;
      (* The modular core pins every registration before its user initializer.
         Imports add separate references; the loader must not add a second pin. *)
      closed := NativeModules.Close(handle); (* Registered owns a native reference for every import too. *)
      Platform.CommandCritical(FALSE)
    END;
    res := 0; resMsg := "";
    RETURN m
  END ThisMod;

  PROCEDURE Failure(message: ARRAY OF CHAR);
  BEGIN res := 1; COPY(message, resMsg)
  END Failure;

  PROCEDURE OwnsImport(owner: Module): BOOLEAN;
    VAR l: Loaded;
  BEGIN
    IF (owner.name = "Heap") OR (owner.name = "PlatformNative") OR
        (owner.name = "Platform") OR (owner.name = "Modules") THEN
      RETURN TRUE
    END;
    l := loaded;
    WHILE (l # NIL) & (l.owner # owner) DO l := l.next END;
    RETURN (l # NIL) & (l.pin # NIL)
  END OwnsImport;

  PROCEDURE FreeOne(name: ARRAY OF CHAR; VAR imports: SavedImport): BOOLEAN;
    VAR m, imported: Module; l, current, previous: Loaded; i: INTEGER;
      saved: SavedImport; status: INTEGER;
  BEGIN
    m := Modules.ThisMod(name);
    IF m = NIL THEN Failure("module not found"); RETURN FALSE END;
    status := Heap.CheckModule(m);
    CASE status OF
    | 0:
    | 1: Failure("core or untracked module cannot be unloaded"); RETURN FALSE
    | 2: Failure("module is initializing, terminating or disabled"); RETURN FALSE
    | 3: Failure("loaded clients import this module"); RETURN FALSE
    | 4: Failure("module code is active"); RETURN FALSE
    | 5: Failure("retained references to this module exist"); RETURN FALSE
    | 6: Failure("heap collection or finalization is active"); RETURN FALSE
    ELSE Failure("invalid module lifetime state"); RETURN FALSE
    END;
    l := loaded;
    WHILE (l # NIL) & (l.owner # m) DO l := l.next END;
    IF l = NIL THEN Failure("module has no native ownership record"); RETURN FALSE END;
    IF l.pin = NIL THEN Failure(l.error); RETURN FALSE END;
    IF ~NativeLibraries.Unloadable(l.pin, resMsg) THEN res := 1; RETURN FALSE END;
    i := 0; imported := Heap.Imported(m, i);
    WHILE imported # NIL DO
      IF ~OwnsImport(imported) THEN
        Failure("an imported module has no independent native ownership; rebuild the complete modular profile");
        RETURN FALSE
      END;
      INC(i); imported := Heap.Imported(m, i)
    END;
    IF Heap.LiveTypes(m) THEN Failure("live objects use this module's type descriptors"); RETURN FALSE END;
    i := 0; imported := Heap.Imported(m, i);
    WHILE imported # NIL DO
      NEW(saved); COPY(imported.name, saved.name); saved.next := imports; imports := saved;
      INC(i); imported := Heap.Imported(m, i)
    END;
    Heap.BeginFree(m);
    Heap.DetachCallbacks(m); Heap.FINALMOD(m);
    IF ~Heap.CollectModule(m) OR Heap.HasFinalizers(m) OR ~Heap.Finishable(m) THEN
      Heap.DisableModule(m); damaged := TRUE;
      Failure("cleanup left live objects, callbacks or references; module is disabled; restart the host");
      RETURN FALSE
    END;
    IF ~NativeLibraries.Close(l.pin, resMsg) THEN
      Heap.DisableModule(m); damaged := TRUE; res := 1; RETURN FALSE
    END;
    Heap.CommitFree(m);
    (* Cleanup may have loaded an unrelated module at the head of this list. *)
    current := loaded; previous := NIL;
    WHILE (current # NIL) & (current # l) DO previous := current; current := current.next END;
    ASSERT(current = l);
    IF previous = NIL THEN loaded := l.next ELSE previous.next := l.next END;
    l.owner := NIL; l.pin := NIL; l.next := NIL;
    res := 0; resMsg := "";
    RETURN TRUE
  END FreeOne;

  PROCEDURE FreeTree(name: ARRAY OF CHAR; all: BOOLEAN);
    VAR imports: SavedImport; m: Module;
  BEGIN
    IF FreeOne(name, imports) & all THEN
      WHILE imports # NIL DO
        m := Modules.ThisMod(imports.name);
        IF (m # NIL) & (Heap.CheckModule(m) = 0) THEN FreeTree(imports.name, TRUE) END;
        (* Preserve res and resMsg if recursive cleanup disabled an import.
           The host must be restarted before reloading the root module. *)
        IF damaged THEN RETURN END;
        imports := imports.next
      END;
      (* Recursive freeing is best-effort: shared/core imports remain loaded. *)
      res := 0; resMsg := ""
    END
  END FreeTree;

  PROCEDURE Free*(name: ARRAY OF CHAR; all: BOOLEAN);
  BEGIN
    IF freeing THEN
      Failure("nested unloading is not permitted");
      Modules.res := res; COPY(resMsg, Modules.resMsg); RETURN
    END;
    Platform.CommandCritical(TRUE); freeing := TRUE; damaged := FALSE;
    FreeTree(name, all);
    freeing := FALSE; Platform.CommandCritical(FALSE);
    Modules.res := res; COPY(resMsg, Modules.resMsg)
  END Free;

  PROCEDURE Append(s: ARRAY OF CHAR; VAR target: ARRAY OF CHAR): BOOLEAN;
    VAR i, j: LONGINT;
  BEGIN
    i := 0; j := 0;
    WHILE target[j] # 0X DO INC(j) END;
    WHILE s[i] # 0X DO
      IF j + 1 >= LEN(target) THEN RETURN FALSE END;
      target[j] := s[i]; INC(i); INC(j); target[j] := 0X
    END;
    RETURN TRUE
  END Append;

  PROCEDURE Error(s: ARRAY OF CHAR);
    VAR n: LONGINT; error: Platform.ErrorCode;
  BEGIN
    n := 0; WHILE s[n] # 0X DO INC(n) END;
    error := Platform.Write(Platform.StdErr, SYSTEM.ADR(s[0]), n)
  END Error;

  PROCEDURE Run*(name: ARRAY OF CHAR);
    VAR env, search: ARRAY 4096 OF CHAR; m: Module; valid: BOOLEAN;
  BEGIN
    (* A launcher finds its application beside the executable, regardless of
       the current directory. An explicit module path overrides this default. *)
    Platform.GetEnv("VOC_MODULE_PATH", env);
    valid := TRUE;
    IF (env = "") & (Modules.BinaryDir # "") THEN
      COPY(Modules.BinaryDir, search);
      valid := Append(":", search) & Append(path, search);
      IF valid THEN COPY(search, path) END
    END;
    IF valid THEN m := ThisMod(name)
    ELSE m := NIL; res := 1; resMsg := "module search path is too long"
    END;
    IF m = NIL THEN
      Error(name); Error(": "); Error(resMsg); Error(Platform.NL);
      Heap.FINALL(); Platform.Exit(1)
    END
  END Run;

BEGIN
  IF SIZE(INTEGER) = 2 THEN model := "O2"
  ELSIF SIZE(SHORTINT) = 2 THEN model := "OC"
  ELSE model := "OV"
  END;
  NativeLibraries.DefaultPath(path);
  Heap.SetModuleNotifier(Registered);
  Modules.InstallFreeHandler(Free)
END ModuleLoader.
