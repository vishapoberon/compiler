MODULE TLSNow;
(* the current time in UTC, for certificate validity: GetTimeOfDay of Linux0 (polpo's, or the one
   of the voc Internet module), days to the civil date after H. Hinnant's days_from_civil
   inverse. Seconds are signed 32 bits: good until 2038. *)
IMPORT Linux0 := unixNet, SYSTEM, TLSX509Validity;

PROCEDURE Current*(VAR t: TLSX509Validity.Time);
VAR tv: ARRAY 2 OF LONGINT; r, secs, days, sod, z, era, doe, yoe, doy, mp: LONGINT;
BEGIN
  tv[0] := 0; tv[1] := 0;
  r := Linux0.GetTimeOfDay(SYSTEM.ADR(tv[0]), 0);
  secs := tv[0];
  days := secs DIV 86400; sod := secs MOD 86400;
  t.hour := sod DIV 3600; t.minute := sod MOD 3600 DIV 60; t.second := sod MOD 60;
  z := days + 719468;                              (* days since 0000-03-01 *)
  era := z DIV 146097; doe := z - era * 146097;    (* 400 year eras *)
  yoe := (doe - doe DIV 1460 + doe DIV 36524 - doe DIV 146096) DIV 365;
  doy := doe - (365 * yoe + yoe DIV 4 - yoe DIV 100);
  mp := (5 * doy + 2) DIV 153;                     (* March = 0 *)
  t.day := doy - (153 * mp + 2) DIV 5 + 1;
  IF mp < 10 THEN t.month := mp + 3 ELSE t.month := mp - 9 END;
  t.year := yoe + era * 400;
  IF t.month <= 2 THEN INC(t.year) END
END Current;

END TLSNow.
