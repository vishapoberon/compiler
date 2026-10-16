MODULE NativeLibraries;

  (* Oberon policy for native module loading and independent ownership of
     imports. Only NativeModules crosses the dynamic-loader API boundary. *)
  IMPORT SYSTEM, Platform, Heap, NativeModules, ModulePaths, ModuleImages;

  TYPE
    Pin* = POINTER TO PinDesc;
    PinDesc = RECORD
      handle, base, initializer: SYSTEM.ADDRESS;
      path: ARRAY 4096 OF CHAR
    END;
    Body* = PROCEDURE(): SYSTEM.PTR;

  PROCEDURE Open*(name, search, model: ARRAY OF CHAR;
                  VAR error: ARRAY OF CHAR): SYSTEM.ADDRESS;
    VAR directory: ARRAY 4096 OF CHAR; file: ARRAY 8192 OF CHAR;
      symbol: ARRAY 128 OF CHAR; cursor: LONGINT; i: INTEGER;
      handle, descriptor, runtime, owner: SYSTEM.ADDRESS;
      expected: ARRAY 9 OF SYSTEM.INT32; value: SYSTEM.INT32;
      identity: Platform.FileIdentity; valid, closed: BOOLEAN;
  BEGIN
    IF NativeModules.CoreValue() # NativeModules.CoreProfile() THEN
      COPY("incompatible host runtime core profile", error); RETURN 0
    END;
    IF ~ModulePaths.Identifier(name) THEN COPY("invalid module name", error); RETURN 0 END;
    cursor := 0; handle := 0; file := "";
    LOOP
      IF ~ModulePaths.Directory(search, cursor, directory) THEN EXIT END;
      IF ModulePaths.Library(directory, name, model, file) & (Platform.IdentifyByName(file, identity) = 0) THEN
        handle := NativeModules.Open(file); EXIT
      END;
      file := ""
    END;
    IF file = "" THEN
      file := "libvoc-";
      valid := ModulePaths.Append(name, file) & ModulePaths.Append("-", file) &
        ModulePaths.Append(model, file) & ModulePaths.Append(".so", file);
      IF ~valid THEN COPY("module filename is too long", error); RETURN 0 END;
      handle := NativeModules.Open(file)
    END;
    IF handle = 0 THEN NativeModules.Error(error); RETURN 0 END;
    COPY(name, symbol); valid := ModulePaths.Append("__voc_abi", symbol);
    descriptor := NativeModules.Symbol(handle, symbol);
    IF descriptor = 0 THEN COPY("missing VOC shared-module ABI descriptor", error)
    ELSE
      expected[0] := NativeModules.ABIFormat(); expected[1] := SIZE(SYSTEM.ADDRESS);
      expected[2] := SIZE(SHORTINT); expected[3] := SIZE(INTEGER);
      expected[4] := SIZE(LONGINT); expected[5] := SIZE(SET);
      expected[6] := SIZE(Heap.ModuleDesc); expected[7] := SIZE(Heap.CmdDesc);
      expected[8] := NativeModules.CoreProfile();
      i := 0;
      LOOP
        SYSTEM.GET(descriptor + i * SIZE(SYSTEM.INT32), value);
        IF value # expected[i] THEN EXIT END;
        INC(i); IF i = LEN(expected) THEN EXIT END
      END;
      IF i # LEN(expected) THEN COPY("incompatible VOC shared-module ABI", error)
      ELSE
        COPY(name, symbol); valid := ModulePaths.Append("__voc_runtime", symbol);
        runtime := NativeModules.Symbol(handle, symbol); owner := 0;
        IF runtime # 0 THEN SYSTEM.GET(runtime, owner) END;
        IF owner # NativeModules.CoreAddress() THEN COPY("module does not use the host's runtime core", error)
        ELSE
          COPY(name, symbol); valid := ModulePaths.Append("__init", symbol);
          IF NativeModules.Symbol(handle, symbol) # 0 THEN error[0] := 0X; RETURN handle END;
          COPY("missing module initializer", error)
        END
      END
    END;
    closed := NativeModules.Close(handle); RETURN 0
  END Open;

  PROCEDURE Initializer*(handle: SYSTEM.ADDRESS; name: ARRAY OF CHAR): Body;
    VAR symbol: ARRAY 128 OF CHAR; valid: BOOLEAN;
  BEGIN
    COPY(name, symbol); valid := ModulePaths.Append("__init", symbol);
    RETURN SYSTEM.VAL(Body, NativeModules.Symbol(handle, symbol))
  END Initializer;

  PROCEDURE Acquire*(initializer: SYSTEM.ADDRESS; VAR pin: Pin;
                     VAR error: ARRAY OF CHAR): BOOLEAN;
    VAR name: ARRAY 4096 OF CHAR; base, handle: SYSTEM.ADDRESS; canonical: BOOLEAN;
  BEGIN
    pin := NIL;
    IF ~NativeModules.Locate(initializer, base, name) THEN
      COPY("cannot identify the module's native library", error); RETURN FALSE
    END;
    IF ModuleImages.Executable(base) THEN COPY("module belongs to the executable", error); RETURN TRUE END;
    canonical := NativeModules.CanonicalPath(name);
    handle := NativeModules.Pin(name);
    IF handle = 0 THEN COPY("cannot pin the module's native library", error); RETURN FALSE END;
    NEW(pin); pin.handle := handle; pin.base := base; pin.initializer := initializer;
    COPY(name, pin.path); error[0] := 0X;
    RETURN TRUE
  END Acquire;

  PROCEDURE Unloadable*(pin: Pin; VAR error: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    IF pin = NIL THEN RETURN FALSE END;
    IF ~NativeModules.CanUnload() THEN
      COPY("checked native unloading requires Linux/glibc (musl keeps libraries mapped)", error);
      RETURN FALSE
    END;
    RETURN ModuleImages.Unloadable(pin.base, error)
  END Unloadable;

  PROCEDURE Close*(pin: Pin; VAR error: ARRAY OF CHAR): BOOLEAN;
    VAR base: SYSTEM.ADDRESS; name: ARRAY 4096 OF CHAR;
  BEGIN
    IF ~NativeModules.Close(pin.handle) THEN NativeModules.Error(error); RETURN FALSE END;
    pin.handle := 0;
    IF NativeModules.Locate(pin.initializer, base, name) & (base = pin.base) THEN
      (* The library is still mapped after cleanup. Reacquire a native
         reference while its GC roots remain registered. *)
      pin.handle := NativeModules.Pin(pin.path);
      IF pin.handle = 0 THEN NativeModules.Abort END;
      COPY("native loader retains the old library; module is finalized and disabled; restart the host", error);
      RETURN FALSE
    END;
    error[0] := 0X; RETURN TRUE
  END Close;

  PROCEDURE DefaultPath*(VAR search: ARRAY OF CHAR);
    VAR image: SYSTEM.ADDRESS; name: ARRAY 4096 OF CHAR; i, slash: LONGINT; valid: BOOLEAN;
  BEGIN
    IF Platform.getEnv("VOC_MODULE_PATH", search) THEN RETURN END;
    COPY(".", search);
    IF NativeModules.Locate(NativeModules.Address(), image, name) THEN
      i := 0; slash := -1;
      WHILE name[i] # 0X DO IF name[i] = "/" THEN slash := i END; INC(i) END;
      IF slash >= 0 THEN
        name[slash] := 0X;
        valid := ModulePaths.Append(":", search) & ModulePaths.Append(name, search);
        IF ~valid THEN COPY(".", search) END
      END
    END
  END DefaultPath;

END NativeLibraries.
