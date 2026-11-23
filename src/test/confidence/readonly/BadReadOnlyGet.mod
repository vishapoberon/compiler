MODULE BadReadOnlyGet;
IMPORT SYSTEM, ReadOnlyData;

PROCEDURE References(value-: LONGINT; values-: ARRAY OF LONGINT; item-: ReadOnlyData.Item);
BEGIN
  SYSTEM.GET(0, value);
  SYSTEM.GET(0, values[0]);
  SYSTEM.GET(0, item.value);
  SYSTEM.GET(0, SYSTEM.VAL(LONGINT, value))
END References;

BEGIN
  SYSTEM.GET(0, ReadOnlyData.scalar);
  SYSTEM.GET(0, ReadOnlyData.array[0]);
  SYSTEM.GET(0, ReadOnlyData.record.value);
  SYSTEM.GET(0, ReadOnlyData.record.protected);
  SYSTEM.GET(0, ReadOnlyData.writableRecord.protected);
  SYSTEM.GET(0, ReadOnlyData.pointer);
  SYSTEM.GET(0, ReadOnlyData.command);
  SYSTEM.GET(0, SYSTEM.VAL(LONGINT, ReadOnlyData.scalar));
  SYSTEM.GET(0, SYSTEM.VAL(LONGINT, ReadOnlyData.array[0]));
  SYSTEM.GET(0, SYSTEM.VAL(LONGINT, ReadOnlyData.writableRecord.protected))
END BadReadOnlyGet.
