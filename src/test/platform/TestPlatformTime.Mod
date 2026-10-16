MODULE TestPlatformTime;
  (* Unix regression: LONGINT in model 2 is narrower than LP64 time_t.
     Run with TZ=UTC0, in both the conventional and modular runtime. *)
  IMPORT SYSTEM, Platform, PlatformNative, Modules, Out;
  VAR ye, mo, da, ho, mi, se, t, d: LONGINT;
    name: ARRAY 4096 OF CHAR; handle: Platform.FileHandle; error: Platform.ErrorCode;

  PROCEDURE Check(year, month, day, hour, minute, second: LONGINT);
    VAR identity: Platform.FileIdentity; t, d: LONGINT;
  BEGIN
    error := Platform.SetFileMTime(name, year, month, day, hour, minute, second);
    ASSERT(error = 0);
    error := Platform.IdentifyByName(name, identity); ASSERT(error = 0);
    Platform.MTimeAsClock(identity, t, d);
    ASSERT(d = ASH(year MOD 100, 9) + ASH(month, 5) + day);
    ASSERT(t = ASH(hour, 12) + ASH(minute, 6) + second)
  END Check;

BEGIN
  ASSERT(Modules.ArgCount = 2); Modules.GetArg(1, name);
  error := Platform.New(name, handle); ASSERT(error = 0);
  error := Platform.Close(handle); ASSERT(error = 0);
  Check(1970, 1, 1, 0, 0, 0);
  Check(1969, 12, 31, 0, 0, 0);
  Check(2000, 2, 29, 12, 34, 56);
  Check(2038, 1, 19, 3, 14, 7);
  Check(1901, 12, 13, 20, 45, 52);
  IF (SIZE(LONGINT) > 4) &
      PlatformNative.LocalTime(2208988800, ye, mo, da, ho, mi, se) THEN
    Check(2040, 1, 1, 0, 0, 0)
  END;
  error := Platform.Unlink(name); ASSERT(error = 0);
  Platform.GetClock(t, d);
  ASSERT((d MOD 32 >= 1) & (d MOD 32 <= 31));
  ASSERT((d DIV 32 MOD 16 >= 1) & (d DIV 32 MOD 16 <= 12));
  ASSERT((t DIV 4096 < 24) & (t DIV 64 MOD 64 < 60) & (t MOD 64 <= 60));
  (* In model C LONGINT can instead be wider than native time_t. The native
     boundary must reject overflow without touching its output fields. *)
  ye := 11; mo := 12; da := 13; ho := 14; mi := 15; se := 16;
  ASSERT(~PlatformNative.LocalTime(MAX(SYSTEM.INT64), ye, mo, da, ho, mi, se));
  ASSERT((ye = 11) & (mo = 12) & (da = 13) & (ho = 14) & (mi = 15) & (se = 16));
  ASSERT(PlatformNative.LocalTime(0, ye, mo, da, ho, mi, se));
  ASSERT((ye = 70) & (mo = 0) & (da = 1) & (ho = 0) & (mi = 0) & (se = 0));
  ASSERT(PlatformNative.LocalTime(-1, ye, mo, da, ho, mi, se));
  ASSERT((ye = 69) & (mo = 11) & (da = 31) & (ho = 23) & (mi = 59) & (se = 59));
  Out.String("platform time tests passed"); Out.Ln
END TestPlatformTime.
