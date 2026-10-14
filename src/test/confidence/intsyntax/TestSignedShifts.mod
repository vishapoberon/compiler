MODULE TestSignedShifts;
  IMPORT SYSTEM, Out;
  VAR value: SYSTEM.INT64;
BEGIN
  value := -1; ASSERT(value*16 = -16); ASSERT(ASH(value, 4) = -16);
  value := -576460752303423488;
  ASSERT(value*16 = MIN(SYSTEM.INT64)); ASSERT(ASH(value, 4) = MIN(SYSTEM.INT64));
  value := -9; ASSERT(ASH(value, -1) = -5);
  value := MIN(SYSTEM.INT64); ASSERT(ASH(value, 1) = 0);
  value := MAX(SYSTEM.INT64); ASSERT(ASH(value, 1) = -2);
  Out.String("signed shift tests passed"); Out.Ln
END TestSignedShifts.
