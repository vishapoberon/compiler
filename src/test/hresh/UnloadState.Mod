MODULE UnloadState;
  IMPORT SYSTEM;
  TYPE BaseDesc* = RECORD marker*: INTEGER END;
  VAR saved*: SYSTEM.PTR;
    initialized*, stopped*, finalized*, terminated*, selfFree*, stopFree*: INTEGER;
END UnloadState.
