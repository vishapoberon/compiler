MODULE ModuleLoader;

  (* Native module loading shared by command hosts and generated launchers.
     No command discovery, editor or application libraries are needed here. *)
  IMPORT SYSTEM, Platform, Heap, Modules;

  TYPE
    Module* = Modules.Module;
    ModuleBody = PROCEDURE(): SYSTEM.PTR;

  VAR
    path*: ARRAY 4096 OF CHAR;
    res*: INTEGER;
    resMsg*: ARRAY 1024 OF CHAR;
    model: ARRAY 3 OF CHAR;

  PROCEDURE -AInclude '#include "SharedModulesSupport.h"';

  PROCEDURE -DefaultPath(VAR search: ARRAY OF CHAR)
    'VOCShared_default_path((char*)search, search__len)';

  PROCEDURE -Open(name, search, model: ARRAY OF CHAR;
      shortSize, intSize, longSize, setSize: SYSTEM.INT32;
      VAR error: ARRAY OF CHAR): SYSTEM.ADDRESS
    'VOCShared_open((char*)name, (char*)search, (char*)model, shortSize, intSize, longSize, setSize, (char*)error, error__len)';

  PROCEDURE -Body(handle: SYSTEM.ADDRESS; name: ARRAY OF CHAR): ModuleBody
    '(ModuleLoader_ModuleBody)VOCShared_body(handle, (char*)name)';

  PROCEDURE First*(): Module;
  BEGIN RETURN SYSTEM.VAL(Module, Heap.modules)
  END First;

  PROCEDURE ThisMod*(name: ARRAY OF CHAR): Module;
    VAR m: Module; handle: SYSTEM.ADDRESS; body: ModuleBody;
  BEGIN
    m := Modules.ThisMod(name);
    IF m = NIL THEN
      handle := Open(name, path, model, SIZE(SHORTINT), SIZE(INTEGER),
        SIZE(LONGINT), SIZE(SET), resMsg);
      IF handle = 0 THEN res := 1; RETURN NIL END;
      body := Body(handle, name);
      m := SYSTEM.VAL(Module, body());
      IF (m = NIL) OR (m.name # name) THEN
        (* Initializers may leave live GC roots even when they fail. *)
        res := 1; resMsg := "initializer did not register the requested module";
        RETURN NIL
      END;
      Heap.INCREF(m) (* Pin registry roots; code and descriptors remain mapped. *)
    END;
    res := 0; resMsg := "";
    RETURN m
  END ThisMod;

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
  DefaultPath(path)
END ModuleLoader.
