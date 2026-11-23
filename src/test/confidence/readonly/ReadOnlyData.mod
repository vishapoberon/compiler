MODULE ReadOnlyData;
IMPORT SYSTEM;
TYPE
  Item* = RECORD value*: LONGINT; protected-: LONGINT END;
  Buffer* = POINTER TO ARRAY 2 OF LONGINT;
  Command* = PROCEDURE;
VAR
  scalar-: LONGINT;
  array-: ARRAY 2 OF LONGINT;
  record-: Item;
  pointer-: Buffer;
  command-: Command;
  writable*: LONGINT;
  writableArray*: ARRAY 2 OF LONGINT;
  writableRecord*: Item;
  initial: LONGINT;

PROCEDURE Run;
BEGIN INC(writable) END Run;

BEGIN
  initial := 37;
  SYSTEM.GET(SYSTEM.ADR(initial), scalar);
  SYSTEM.GET(SYSTEM.ADR(initial), array[0]);
  SYSTEM.GET(SYSTEM.ADR(initial), record.value);
  SYSTEM.GET(SYSTEM.ADR(initial), record.protected);
  SYSTEM.GET(SYSTEM.ADR(initial), writableRecord.protected);
  NEW(pointer); pointer[0] := initial;
  command := Run
END ReadOnlyData.
