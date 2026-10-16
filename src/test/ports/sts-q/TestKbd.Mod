MODULE TestKbd;
IMPORT Kbd, Modules, Platform, Out;
VAR count, i, start: LONGINT;
  key: Kbd.KEY;
BEGIN
  Modules.GetIntArg(1, count);
  Out.String('ready'); Out.Ln;
  IF count = 0 THEN ASSERT(Kbd.NextKey() = 0); ASSERT(~Kbd.HasKey()) END;
  i := 0; start := Platform.Time();
  WHILE (i < count) & (Platform.Time() - start < 5000) DO
    key := Kbd.NextKey();
    IF key # 0 THEN
      Out.Int(key, 0); Out.Ln; INC(i)
    ELSE Platform.Delay(1)
    END
  END;
  ASSERT(i = count)
END TestKbd.
