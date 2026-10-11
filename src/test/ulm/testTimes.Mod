MODULE testTimes;
  IMPORT Times := ulmTimes, Scales := ulmScales, Out;
  VAR time: Times.Time; scale: Scales.Scale; unit: Scales.Unit;
    name: Scales.UnitName; count: INTEGER;
BEGIN
  Times.Create(time, Times.absolute);
  Scales.GetScale(time, scale);
  Scales.TraverseUnits(scale);
  count := 0;
  WHILE Scales.NextUnit(scale, unit) DO
    Scales.GetName(unit, name);
    ASSERT(count < 3);
    IF count = 0 THEN ASSERT(name = "epoch")
    ELSIF count = 1 THEN ASSERT(name = "second")
    ELSE ASSERT(name = "usec")
    END;
    INC(count)
  END;
  ASSERT(count = 3);
  Out.String("time unit names passed"); Out.Ln
END testTimes.
