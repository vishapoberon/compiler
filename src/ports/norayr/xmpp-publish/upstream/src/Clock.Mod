MODULE Clock;
<* Warnings := FALSE *>
(*  UTC timestamps for the Atom entry.  Uses the C library `time' + `gmtime_r'
    and formats ISO-8601 manually, so no locale or non-ASCII issues. *)

IMPORT Runtime, SYSTEM, C;

TYPE
  (*  Prefix of C `struct tm'.  The record is padded to cover the whole glibc
      struct (incl. tm_gmtoff and tm_zone) so gmtime_r does not overrun it.  *)
  Tm = RECORD
    sec, min, hour, mday, mon, year, wday, yday, isdst: C.int;
    gmtoffLo, gmtoffHi, zoneLo, zoneHi, spare: C.int
  END;

VAR
  null: SYSTEM.ADDRESS;   (* zero initialised -> C NULL *)

PROCEDURE Get (VAR tm: Tm): BOOLEAN;
VAR
  now: HUGEINT;
BEGIN
  now := Runtime.time(null);
  RETURN Runtime.gmtime_r(SYSTEM.ADR(now), SYSTEM.ADR(tm)) # null
END Get;

PROCEDURE Put2 (VAR s: ARRAY OF CHAR; VAR pos: LONGINT; val: LONGINT);
BEGIN
  s[pos] := CHR(ORD("0") + (val DIV 10) MOD 10); INC(pos);
  s[pos] := CHR(ORD("0") + val MOD 10); INC(pos)
END Put2;

PROCEDURE Put4 (VAR s: ARRAY OF CHAR; VAR pos: LONGINT; val: LONGINT);
BEGIN
  s[pos] := CHR(ORD("0") + (val DIV 1000) MOD 10); INC(pos);
  s[pos] := CHR(ORD("0") + (val DIV 100) MOD 10); INC(pos);
  Put2(s, pos, val MOD 100)
END Put4;

PROCEDURE NowIso* (VAR s: ARRAY OF CHAR);
(*  e.g. "2026-09-18T14:05:09Z"  *)
VAR
  tm: Tm;
  pos: LONGINT;
BEGIN
  IF Get(tm) THEN
    pos := 0;
    Put4(s, pos, tm.year + 1900);
    s[pos] := "-"; INC(pos); Put2(s, pos, tm.mon + 1);
    s[pos] := "-"; INC(pos); Put2(s, pos, tm.mday);
    s[pos] := "T"; INC(pos); Put2(s, pos, tm.hour);
    s[pos] := ":"; INC(pos); Put2(s, pos, tm.min);
    s[pos] := ":"; INC(pos); Put2(s, pos, tm.sec);
    s[pos] := "Z"; INC(pos); s[pos] := 0X
  ELSE
    s[0] := 0X
  END
END NowIso;

PROCEDURE Today* (VAR s: ARRAY OF CHAR);
(*  e.g. "2026-09-18"  *)
VAR
  tm: Tm;
  pos: LONGINT;
BEGIN
  IF Get(tm) THEN
    pos := 0;
    Put4(s, pos, tm.year + 1900);
    s[pos] := "-"; INC(pos); Put2(s, pos, tm.mon + 1);
    s[pos] := "-"; INC(pos); Put2(s, pos, tm.mday);
    s[pos] := 0X
  ELSE
    s[0] := 0X
  END
END Today;

END Clock.
