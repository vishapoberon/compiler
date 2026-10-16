MODULE TestUnloadNative;
  IMPORT SYSTEM, NativeModules, Modules;
  TYPE Command* = Modules.Command;
  PROCEDURE -address(command: Command): SYSTEM.ADDRESS '(ADDRESS)command';

  PROCEDURE Hold*(command: Command): SYSTEM.ADDRESS;
    VAR base: SYSTEM.ADDRESS; path: ARRAY 4096 OF CHAR;
  BEGIN
    IF ~NativeModules.Locate(address(command), base, path) THEN RETURN 0 END;
    RETURN NativeModules.Pin(path)
  END Hold;

  PROCEDURE Release*(handle: SYSTEM.ADDRESS);
    VAR closed: BOOLEAN;
  BEGIN IF handle # 0 THEN closed := NativeModules.Close(handle) END
  END Release;

  (* Volatile stores prevent optimization from removing the stack scrub. This
     overwrites only this helper's own frame, never live callers' storage. *)
  PROCEDURE -store(address: SYSTEM.ADDRESS) '*(volatile ADDRESS*)address = 0';
  PROCEDURE Scrub*(): SYSTEM.ADDRESS;
    VAR discarded: ARRAY 32768 OF SYSTEM.ADDRESS; i: LONGINT;
  BEGIN
    FOR i := 0 TO LEN(discarded) - 1 DO store(SYSTEM.ADR(discarded[i])) END;
    RETURN discarded[0]
  END Scrub;

END TestUnloadNative.
