MODULE ssqSys;
(* Sys.Mod -- System dependent procedures. (c) sts-q 2022-Nov 2024-Feb.
   VOC adaptation, 2026-10-16. GPL-3.0; see LICENSE.
   Using Platform for I/O and opaque terminal state, with direct POSIX
   bindings only for descriptor flags, append-open and nanosleep. *)
IMPORT SYSTEM, Modules, Platform, ssqTypes;

CONST esc = 1BX;
TYPE INTEGER = ssqTypes.Integer; Integer = ssqTypes.Longint;
  Path = ARRAY 256 OF CHAR;
VAR
  errmess*: ARRAY 128 OF CHAR;
  starttime*: INTEGER;
  home*, q*, pwd*, iterfile*, docsfile*: Path;
  mouseTracking*: BOOLEAN;
  isXtermAlt, flagsSaved: BOOLEAN;
  savedFlags: INTEGER;
  savedTerminal: Platform.TerminalState;

PROCEDURE -A0Feature '#ifndef _POSIX_C_SOURCE';
PROCEDURE -A0Feature1 '#define _POSIX_C_SOURCE 200809L';
PROCEDURE -A0Feature2 '#endif';
PROCEDURE -Aerrno '#include <errno.h>';
PROCEDURE -Afcntl '#include <fcntl.h>';
PROCEDURE -Astdlib '#include <stdlib.h>';
PROCEDURE -Atime '#include <time.h>';
PROCEDURE -getFlags(): INTEGER 'fcntl(0, F_GETFL, 0)';
PROCEDURE -setFlags(flags: INTEGER): INTEGER 'fcntl(0, F_SETFL, flags)';
PROCEDURE -nonblock(): INTEGER 'O_NONBLOCK';
PROCEDURE -again(error: INTEGER): BOOLEAN '(error == EAGAIN || error == EWOULDBLOCK)';
PROCEDURE -nano(s, ns: Integer): INTEGER 'nanosleep(&(struct timespec){s, ns}, 0)';
PROCEDURE -openAppend(name: ARRAY OF CHAR): LONGINT
  'open((char*)name, O_WRONLY | O_CREAT | O_APPEND, 0666)';
PROCEDURE -onExit(handler: Platform.Command): INTEGER 'atexit(handler)';

PROCEDURE Add*(i, j: Integer): Integer;
BEGIN RETURN i + j END Add;

PROCEDURE Xchg*(i, j: INTEGER);
  VAR temp: INTEGER;
BEGIN temp := i; i := j; j := temp END Xchg;

PROCEDURE BitAnd*(i, j: INTEGER): INTEGER;
BEGIN RETURN SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, i) * SYSTEM.VAL(SET, j)) END BitAnd;

PROCEDURE BitOr*(i, j: INTEGER): INTEGER;
BEGIN RETURN SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, i) + SYSTEM.VAL(SET, j)) END BitOr;

PROCEDURE BitXor*(i, j: INTEGER): INTEGER;
BEGIN RETURN SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, i) / SYSTEM.VAL(SET, j)) END BitXor;

PROCEDURE System*(cmd: ARRAY OF CHAR);
  VAR result: LONGINT;
BEGIN result := Platform.System(cmd) END System;

PROCEDURE Sleep*(n: INTEGER);
BEGIN ASSERT(n >= 0); Platform.Delay(n) END Sleep;

PROCEDURE NanoSleep*(s, ns: Integer);
  VAR result: INTEGER;
BEGIN
  ASSERT((s >= 0) & (ns >= 0) & (ns < 1000000000));
  result := nano(s, ns)
END NanoSleep;

PROCEDURE Uptime*(): INTEGER;
BEGIN RETURN ssqTypes.Short(Platform.Time()) END Uptime;

PROCEDURE Time*(): INTEGER; (* Unix seconds, not local-time seconds. *)
  VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN ssqTypes.Short(sec) END Time;

PROCEDURE TimeValues*(VAR hh, mm, ss: INTEGER; time: INTEGER);
  CONST DeltaUTC = 2 * 3600; (* Preserving upstream's fixed UTC+2 display. *)
  VAR t: INTEGER;
BEGIN
  t := ssqTypes.Short((LONG(time) + DeltaUTC) MOD 86400);
  hh := t DIV 3600; mm := t MOD 3600 DIV 60; ss := t MOD 60
END TimeValues;

PROCEDURE Nanotime*(VAR sec, nanoseconds: INTEGER): BOOLEAN;
  VAR s, n: LONGINT;
BEGIN
  Platform.GetTimeOfDay(s, n);
  sec := ssqTypes.Short(s); nanoseconds := ssqTypes.Short(n) * 1000;
  RETURN TRUE
END Nanotime;

PROCEDURE mTime*(): INTEGER;
  VAR sec, ns: INTEGER;
BEGIN
  IF Nanotime(sec, ns) THEN RETURN (sec MOD 86400) * 1000 + ns DIV 1000000 END;
  RETURN -1
END mTime;

PROCEDURE Argc*(): INTEGER;
BEGIN RETURN Modules.ArgCount END Argc;

PROCEDURE Argv*(VAR value: ARRAY OF CHAR; pos: INTEGER): BOOLEAN;
BEGIN
  value[0] := 0X;
  IF (pos >= 0) & (pos < Argc()) THEN Modules.GetArg(SHORT(pos), value); RETURN TRUE END;
  RETURN FALSE
END Argv;

PROCEDURE Getenv*(VAR value: ARRAY OF CHAR; name: ARRAY OF CHAR): BOOLEAN;
BEGIN value[0] := 0X; RETURN Platform.getEnv(name, value) END Getenv;

PROCEDURE OutChars*(a: ARRAY OF CHAR; offset, len: INTEGER);
  VAR error: Platform.ErrorCode;
BEGIN
  ASSERT((offset >= 0) & (len >= 0) & (offset <= LEN(a) - len));
  IF len > 0 THEN
    error := Platform.Write(Platform.StdOut, SYSTEM.ADR(a[offset]), len);
    ASSERT(error = 0)
  END
END OutChars;

PROCEDURE OutChr*(c: CHAR);
  VAR a: ARRAY 1 OF CHAR;
BEGIN a[0] := c; OutChars(a, 0, 1) END OutChr;

PROCEDURE Out*(buffer: ARRAY OF CHAR);
  VAR len: INTEGER;
BEGIN
  len := 0;
  WHILE (len < LEN(buffer)) & (buffer[len] # 0X) DO INC(len) END;
  OutChars(buffer, 0, len)
END Out;

PROCEDURE ReadKeys*(VAR buffer: ARRAY OF CHAR): INTEGER;
  VAR n: LONGINT; error: Platform.ErrorCode;
BEGIN
  IF LEN(buffer) = 0 THEN RETURN 0 END;
  REPEAT error := Platform.Read(Platform.StdIn, SYSTEM.ADR(buffer), LEN(buffer), n)
  UNTIL ~Platform.Interrupted(error);
  IF error = 0 THEN RETURN ssqTypes.Short(n) END;
  IF again(error) THEN RETURN 0 END;
  RETURN -error
END ReadKeys;

PROCEDURE ReadLine*(VAR a: ARRAY OF CHAR): INTEGER;
  VAR c: CHAR; len: INTEGER; n: LONGINT; error: Platform.ErrorCode;
BEGIN
  IF LEN(a) = 0 THEN RETURN -1 END;
  len := 0; a[0] := 0X;
  LOOP
    REPEAT error := Platform.Read(Platform.StdIn, SYSTEM.ADR(c), 1, n)
    UNTIL ~Platform.Interrupted(error);
    IF error # 0 THEN RETURN -1 END;
    IF n = 0 THEN IF len = 0 THEN RETURN -1 ELSE RETURN len END END;
    IF c = 0AX THEN RETURN len END;
    IF len >= LEN(a) - 1 THEN RETURN -1 END;
    a[len] := c; INC(len); a[len] := 0X
  END
END ReadLine;

PROCEDURE Csi(seq: ARRAY OF CHAR);
BEGIN OutChr(esc); Out(seq) END Csi;
PROCEDURE ScreenOther*;
BEGIN Csi('[?1049h') END ScreenOther;
PROCEDURE ScreenNormal*;
BEGIN Csi('[?1049l') END ScreenNormal;
PROCEDURE MouseTrackingOn*;
BEGIN Csi('[?1002;1006;1015h'); mouseTracking := TRUE END MouseTrackingOn;
PROCEDURE MouseTrackingOff*;
BEGIN Csi('[?1002;1006;1015l'); mouseTracking := FALSE END MouseTrackingOff;

PROCEDURE GoNonblocking*;
  VAR flags, result: INTEGER;
BEGIN
  IF ~flagsSaved THEN
    flags := getFlags(); ASSERT(flags >= 0);
    result := setFlags(BitOr(flags, nonblock())); ASSERT(result = 0);
    savedFlags := flags; flagsSaved := TRUE
  END
END GoNonblocking;

PROCEDURE XtermStd*;
  VAR error: Platform.ErrorCode; result: INTEGER;
BEGIN
  IF mouseTracking THEN MouseTrackingOff END;
  IF isXtermAlt THEN ScreenNormal; isXtermAlt := FALSE END;
  IF savedTerminal # 0 THEN
    REPEAT error := Platform.RestoreTerminalState(Platform.StdIn, savedTerminal)
    UNTIL ~Platform.Interrupted(error);
    Platform.ReleaseTerminalState(savedTerminal)
  END;
  IF flagsSaved THEN result := setFlags(savedFlags); flagsSaved := FALSE END
END XtermStd;

PROCEDURE XtermAlt*;
  VAR envar: ARRAY 128 OF CHAR; working: Platform.TerminalState;
    error: Platform.ErrorCode;
BEGIN
  IF isXtermAlt THEN RETURN END;
  IF Platform.IsConsole(Platform.StdIn) THEN
    error := Platform.CaptureTerminalState(Platform.StdIn, savedTerminal);
    ASSERT(error = 0);
    error := Platform.CopyTerminalState(savedTerminal, working); ASSERT(error = 0);
    Platform.MakeTerminalRaw(working);
    error := Platform.RestoreTerminalState(Platform.StdIn, working);
    Platform.ReleaseTerminalState(working); ASSERT(error = 0)
  END;
  ScreenOther; isXtermAlt := TRUE;
  IF Getenv(envar, 'PETMOUSE') & (envar = 'true') THEN MouseTrackingOn END;
  GoNonblocking
END XtermAlt;

PROCEDURE XtermSize*(VAR lines, cols: INTEGER);
  VAR r, c: LONGINT;
BEGIN
  lines := 0; cols := 0;
  IF Platform.GetTerminalDimensions(Platform.StdIn, r, c) = 0 THEN
    lines := ssqTypes.Short(r); cols := ssqTypes.Short(c)
  END
END XtermSize;

PROCEDURE Exit*;
BEGIN XtermStd; HALT(0) END Exit;
PROCEDURE ExitFail*;
BEGIN XtermStd; HALT(1) END ExitFail;

PROCEDURE Assert*(b: BOOLEAN; mess: ARRAY OF CHAR);
BEGIN
  IF ~b THEN
    XtermStd; OutChr(0AX); Out('############  Sys.Assert failed: ');
    Out(mess); OutChr(0AX); ExitFail
  END
END Assert;

PROCEDURE ERR*(mess: ARRAY OF CHAR): BOOLEAN;
BEGIN COPY(mess, errmess); RETURN FALSE END ERR;

PROCEDURE FileExists*(name: ARRAY OF CHAR): BOOLEAN;
  VAR identity: Platform.FileIdentity;
BEGIN RETURN Platform.IdentifyByName(name, identity) = 0 END FileExists;

PROCEDURE FileRead*(VAR text: ARRAY OF CHAR; VAR length: INTEGER; name: ARRAY OF CHAR): BOOLEAN;
  VAR fd: Platform.FileHandle; error, closed: Platform.ErrorCode;
    n: LONGINT; extra: CHAR;
BEGIN
  length := 0;
  IF LEN(text) = 0 THEN RETURN FALSE END;
  text[0] := 0X;
  error := Platform.OldRO(name, fd);
  IF error # 0 THEN RETURN FALSE END;
  REPEAT
    REPEAT error := Platform.Read(fd, SYSTEM.ADR(text[length]), LEN(text) - 1 - length, n)
    UNTIL ~Platform.Interrupted(error);
    INC(length, ssqTypes.Short(n))
  UNTIL (error # 0) OR (n = 0) OR (length = LEN(text) - 1);
  text[length] := 0X;
  IF (error = 0) & (length = LEN(text) - 1) THEN
    REPEAT error := Platform.Read(fd, SYSTEM.ADR(extra), 1, n)
    UNTIL ~Platform.Interrupted(error)
  END;
  closed := Platform.Close(fd);
  RETURN (error = 0) & (closed = 0) & (n = 0)
END FileRead;

PROCEDURE FileWrite*(name, text: ARRAY OF CHAR; length: INTEGER): BOOLEAN;
  VAR fd: Platform.FileHandle; error, closed: Platform.ErrorCode;
BEGIN
  IF (length < 0) OR (length > LEN(text)) THEN RETURN FALSE END;
  error := Platform.OpenFile(name, Platform.WriteOnly, Platform.CreateAlways, fd);
  IF error # 0 THEN RETURN FALSE END;
  error := Platform.Write(fd, SYSTEM.ADR(text), length); closed := Platform.Close(fd);
  RETURN (error = 0) & (closed = 0)
END FileWrite;

PROCEDURE FileAppendLine*(name, line: ARRAY OF CHAR): BOOLEAN;
  VAR fd: Platform.FileHandle; error, closed: Platform.ErrorCode;
    length: INTEGER; lf: CHAR;
BEGIN
  length := 0;
  WHILE (length < LEN(line)) & (line[length] # 0X) DO INC(length) END;
  fd := openAppend(name);
  IF fd < 0 THEN RETURN FALSE END;
  error := Platform.Write(fd, SYSTEM.ADR(line), length);
  IF error = 0 THEN lf := 0AX; error := Platform.Write(fd, SYSTEM.ADR(lf), 1) END;
  closed := Platform.Close(fd);
  RETURN (error = 0) & (closed = 0)
END FileAppendLine;

PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0;
  WHILE (i < LEN(a)) & (a[i] # 0X) DO INC(i) END;
  j := 0;
  WHILE (i < LEN(a) - 1) & (b[j] # 0X) DO a[i] := b[j]; INC(i); INC(j) END;
  IF i < LEN(a) THEN a[i] := 0X END
END Append;

PROCEDURE InstallCleanup;
  VAR result: INTEGER;
BEGIN
  Modules.InstallTermHandler(XtermStd);
  IF Modules.res # 0 THEN
    (* Conventional code has no procedure-owner metadata. Its code stays
       loaded until exit; modular code instead uses the unload-aware hook. *)
    result := onExit(XtermStd); ASSERT(result = 0);
    Modules.res := 0; Modules.resMsg := ''
  END
END InstallCleanup;

BEGIN
  savedTerminal := 0; flagsSaved := FALSE; isXtermAlt := FALSE; mouseTracking := FALSE;
  InstallCleanup;
  starttime := Time();
  IF Getenv(pwd, 'PWD') THEN Append(pwd, '/') END;
  IF Getenv(home, 'HOME') THEN Append(home, '/') END;
  IF Getenv(q, 'HOME') THEN Append(q, '/q/') END;
  IF Getenv(iterfile, 'HOME') THEN Append(iterfile, '/r/iterfile') END;
  IF Getenv(docsfile, 'HOME') THEN Append(docsfile, '/r/docsfile') END
END ssqSys.
