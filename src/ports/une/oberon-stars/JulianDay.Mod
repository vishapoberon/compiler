(* License: GPL-3.0 *)

MODULE JulianDay;
IMPORT SYSTEM, Out, time;

CONST
    UNIXEPOCHJD = 2440587.5D0;
    DAYSECONDS* = 86400.0D0;

PROCEDURE -Aincludetime '#include <time.h>';
PROCEDURE -sectotm(u: time.unxTime) "struct tm *time = localtime((time_t*) &u)";
PROCEDURE -tmsec():  LONGINT   "(LONGINT)time->tm_sec";
PROCEDURE -tmmin():  LONGINT   "(LONGINT)time->tm_min";
PROCEDURE -tmhour(): LONGINT   "(LONGINT)time->tm_hour";
PROCEDURE -tmmday(): LONGINT   "(LONGINT)time->tm_mday";
PROCEDURE -tmmon():  LONGINT   "(LONGINT)time->tm_mon";
PROCEDURE -tmyear(): LONGINT   "(LONGINT)time->tm_year";

PROCEDURE FromUnix*(u: time.unxTime): LONGREAL;
BEGIN
    RETURN UNIXEPOCHJD + u/DAYSECONDS;
END FromUnix;

PROCEDURE ToUnix*(jd: LONGREAL): time.unxTime;
BEGIN
    RETURN ENTIER(((jd - UNIXEPOCHJD)*DAYSECONDS));
END ToUnix;

PROCEDURE Now*(): LONGREAL;
VAR u: time.unxTime;
BEGIN
    time.unixTime(u);
    RETURN FromUnix(u);
END Now;

(* Extract year, month, day, hour, minute and second from Unix time *)
PROCEDURE LocalTimeFromUnix*(u: time.unxTime; VAR year, month, day, hour, min, sec: LONGINT);
BEGIN
    sectotm(u);
    year := tmyear() + 1900;
    month := tmmon() + 1;
    day := tmmday();
    hour := tmhour();
    min := tmmin();
    sec := tmsec();
END LocalTimeFromUnix;

(* Extract year, month, day, hour, minute and second from Julian Date *)
PROCEDURE LocalTimeFromJD*(jd: LONGREAL; VAR year, month, day, hour, min, sec: LONGINT);
VAR u: time.unxTime;
BEGIN
    u := ToUnix(jd);
    LocalTimeFromUnix(u, year, month, day, hour, min, sec);
END LocalTimeFromJD;

PROCEDURE WriteLeadingZero(n: LONGINT);
BEGIN
    IF n < 10 THEN
        Out.Int(0, 1);
        Out.Int(n, 1);
    ELSE
        Out.Int(n, 2);
    END
END WriteLeadingZero;

PROCEDURE Write*(jd: LONGREAL);
VAR
    year, month, day, hour, min, sec: LONGINT;
BEGIN
    LocalTimeFromJD(jd, year, month, day, hour, min, sec);
    Out.Int(year, 4);
    Out.Char("/");
    WriteLeadingZero(month);
    Out.Char("/");
    WriteLeadingZero(day);
    Out.Char(" ");
    WriteLeadingZero(hour);
    Out.Char(":");
    WriteLeadingZero(min);
    Out.Char(":");
    WriteLeadingZero(sec);
END Write;

END JulianDay.
