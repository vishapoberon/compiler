MODULE TestReadOnly;
IMPORT SYSTEM, Out, ReadOnlyData;
VAR value, input, checks: LONGINT;
  real, realInput: REAL;
  pointer: ReadOnlyData.Buffer;
  command: ReadOnlyData.Command;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN
    Out.String("TestReadOnly: "); Out.Int(checks, 0); Out.String(" checks, 1 failed"); Out.Ln;
    HALT(100)
  END
END Check;

PROCEDURE Load(VAR destination: LONGINT);
BEGIN SYSTEM.GET(SYSTEM.ADR(input), destination) END Load;

PROCEDURE Copy(value-: LONGINT);
  VAR destination: LONGINT;
BEGIN
  SYSTEM.PUT(SYSTEM.ADR(destination), value); Check(destination = 37);
  SYSTEM.PUT(SYSTEM.ADR(destination), SYSTEM.VAL(LONGINT, value)); Check(destination = 37)
END Copy;

BEGIN
  Check(ReadOnlyData.scalar = 37);
  Check(ReadOnlyData.array[0] = 37);
  Check(ReadOnlyData.record.value = 37);
  Check(ReadOnlyData.record.protected = 37);
  Check(ReadOnlyData.writableRecord.protected = 37);
  input := 73;
  SYSTEM.GET(SYSTEM.ADR(input), value); Check(value = input);
  SYSTEM.GET(SYSTEM.ADR(input), ReadOnlyData.writable); Check(ReadOnlyData.writable = input);
  SYSTEM.GET(SYSTEM.ADR(input), ReadOnlyData.writableArray[0]); Check(ReadOnlyData.writableArray[0] = input);
  SYSTEM.GET(SYSTEM.ADR(input), ReadOnlyData.writableRecord.value); Check(ReadOnlyData.writableRecord.value = input);
  realInput := 1.5;
  SYSTEM.GET(SYSTEM.ADR(realInput), SYSTEM.VAL(SYSTEM.INT32, real)); Check(real = realInput);
  Load(ReadOnlyData.writableArray[1]); Check(ReadOnlyData.writableArray[1] = input);
  SYSTEM.GET(SYSTEM.ADR(input), ReadOnlyData.pointer[1]); Check(ReadOnlyData.pointer[1] = input);
  SYSTEM.PUT(SYSTEM.ADR(value), ReadOnlyData.scalar); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(value), ReadOnlyData.array[0]); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(value), ReadOnlyData.record.value); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(value), ReadOnlyData.record.protected); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(value), ReadOnlyData.writableRecord.protected); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(value), SYSTEM.VAL(LONGINT, ReadOnlyData.scalar)); Check(value = 37);
  SYSTEM.PUT(SYSTEM.ADR(pointer), ReadOnlyData.pointer); Check(pointer = ReadOnlyData.pointer);
  SYSTEM.PUT(SYSTEM.ADR(command), ReadOnlyData.command);
  command(); Check(ReadOnlyData.writable = input+1);
  Copy(ReadOnlyData.scalar);
  Out.String("TestReadOnly: "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END TestReadOnly.
