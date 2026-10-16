MODULE NetHost;
(* VOC host services for the Polpo network ports; not a filesystem stack. *)
IMPORT SYSTEM, Platform, Strings;

CONST Directory* = 0; SubDir* = Directory;
TYPE FileName* = ARRAY 1200 OF CHAR;
  Enumerator* = PROCEDURE (name: ARRAY OF CHAR; time, date, size: LONGINT;
    attributes: SET; VAR continue: BOOLEAN);

PROCEDURE -IncludeStat "#include <sys/stat.h>";
PROCEDURE -IncludeTime "#include <time.h>";
PROCEDURE -IncludeStdlib "#include <stdlib.h>";
PROCEDURE -IncludeUnistd "#include <unistd.h>";
PROCEDURE -IncludeErrno "#include <errno.h>";

PROCEDURE -Info(name: ARRAY OF CHAR; VAR attributes: SET; VAR size, mtime: LONGINT): BOOLEAN
  "({struct stat st; int r=stat((char*)name,&st); *attributes=0; *size=0; *mtime=0; if(!r){if(S_ISDIR(st.st_mode))*attributes=1; if(st.st_size<=2147483647)*size=(LONGINT)st.st_size; if(st.st_mtime<=2147483647)*mtime=(LONGINT)st.st_mtime;} r==0;})";
PROCEDURE -mkdir(name: ARRAY OF CHAR): LONGINT "mkdir((char*)name,0700)==0?0:-errno";
PROCEDURE -temporary(VAR name: ARRAY OF CHAR): LONGINT "mkstemp((char*)name)";
PROCEDURE -mode(fd, permissions: LONGINT): BOOLEAN "fchmod(fd,permissions)==0";
PROCEDURE -now(): LONGINT "(LONGINT)time(0)";
PROCEDURE -utc(seconds: LONGINT; VAR date, clock: LONGINT)
  "{time_t v=seconds; struct tm t; if(gmtime_r(&v,&t)){*date=t.tm_year*512+(t.tm_mon+1)*32+t.tm_mday; *clock=t.tm_hour*4096+t.tm_min*64+t.tm_sec;} else {*date=0; *clock=0;}}";

PROCEDURE Exists*(name: ARRAY OF CHAR; VAR full: ARRAY OF CHAR; VAR attributes: SET): BOOLEAN;
VAR size, mtime: LONGINT;
BEGIN
  COPY(name, full);
  RETURN Info(name, attributes, size, mtime)
END Exists;

PROCEDURE CreateDirectory*(name: ARRAY OF CHAR; VAR result: INTEGER);
BEGIN result := SHORT(mkdir(name))
END CreateDirectory;

(* Use an owner-only temporary in the destination directory, set permissions
   before writing, then atomically rename. Never expose a new identity key with
   the public permissions of a default Files.New work file. *)
PROCEDURE WriteFile*(name: ARRAY OF CHAR; VAR data: ARRAY OF CHAR; n, permissions: LONGINT): BOOLEAN;
VAR temp: FileName; fd: LONGINT; result, ignored: Platform.ErrorCode; ok: BOOLEAN;
BEGIN
  IF (n < 0) OR (n > LEN(data)) OR (Strings.Length(name) + 8 >= LEN(temp)) THEN RETURN FALSE END;
  COPY(name, temp); Strings.Append(".XXXXXX", temp);
  fd := temporary(temp); IF fd < 0 THEN RETURN FALSE END;
  ok := mode(fd, permissions);
  IF ok & (n > 0) THEN
    result := Platform.Write(fd, SYSTEM.ADR(data[0]), n); ok := result = 0
  END;
  result := Platform.Close(fd); ok := ok & (result = 0);
  IF ok THEN result := Platform.Rename(temp, name); ok := result = 0 END;
  IF ~ok THEN ignored := Platform.Unlink(temp) END;
  RETURN ok
END WriteFile;

PROCEDURE ReadInput*(VAR data: ARRAY OF CHAR; position, n: LONGINT): LONGINT;
VAR got: LONGINT; result: Platform.ErrorCode;
BEGIN
  IF (position < 0) OR (position > LEN(data)) OR (n < 0) OR (n > LEN(data) - position) THEN RETURN -1 END;
  IF n = 0 THEN RETURN 0 END;
  result := Platform.Read(Platform.StdIn, SYSTEM.ADR(data[position]), n, got);
  IF result # 0 THEN RETURN -LONG(result) END;
  RETURN got
END ReadInput;

PROCEDURE Enumerate*(directory: ARRAY OF CHAR; visit: Enumerator; VAR result: LONGINT);
VAR handle: Platform.DirectoryHandle; entry, full: FileName; done, continue: BOOLEAN;
  attributes: SET; error, ignored: Platform.ErrorCode; size, mtime: LONGINT;
BEGIN
  error := Platform.OpenDirectory(directory, handle); result := -LONG(error);
  IF error # 0 THEN RETURN END;
  done := FALSE; continue := TRUE;
  WHILE ~done & continue & (error = 0) DO
    error := Platform.ReadDirectory(handle, entry, done);
    IF (error = 0) & ~done & (entry # ".") & (entry # "..") THEN
      COPY(directory, full);
      IF (full # "") & (full[Strings.Length(full) - 1] # "/") THEN Strings.Append("/", full) END;
      IF Strings.Length(full) + Strings.Length(entry) < LEN(full) THEN
        Strings.Append(entry, full);
        IF Info(full, attributes, size, mtime) THEN visit(entry, 0, 0, size, attributes, continue) END
      ELSE error := 1
      END
    END
  END;
  ignored := Platform.CloseDirectory(handle);
  IF error = 0 THEN error := ignored END;
  result := -LONG(error)
END Enumerate;

PROCEDURE Now*(): LONGINT;
BEGIN RETURN now()
END Now;

PROCEDURE MTime*(name: ARRAY OF CHAR): LONGINT;
VAR attributes: SET; size, mtime: LONGINT;
BEGIN
  IF Info(name, attributes, size, mtime) THEN RETURN mtime END;
  RETURN 0
END MTime;

PROCEDURE UTC*(seconds: LONGINT; VAR date, clock: LONGINT);
BEGIN utc(seconds, date, clock)
END UTC;

END NetHost.
