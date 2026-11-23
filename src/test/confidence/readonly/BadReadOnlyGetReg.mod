MODULE BadReadOnlyGetReg;
IMPORT SYSTEM, ReadOnlyData;
BEGIN
  SYSTEM.GETREG(0, ReadOnlyData.scalar);
  SYSTEM.GETREG(0, ReadOnlyData.array[0]);
  SYSTEM.GETREG(0, SYSTEM.VAL(LONGINT, ReadOnlyData.record.value))
END BadReadOnlyGetReg.
