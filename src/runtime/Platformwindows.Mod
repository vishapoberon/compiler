MODULE Platform;
IMPORT SYSTEM, PlatformNative;

(* TODO:
   Use Unicode APIs with manual UTF8 conversion and prepend '\\?\' to
   file paths in order to get 32768 character path length limit (as
   opposed to 256 bytes. *)


TYPE
  SignalHandler = PROCEDURE(signal: SYSTEM.INT32);
  Command* = PROCEDURE;

  ErrorCode*  = INTEGER;
  FileHandle* = SYSTEM.ADDRESS;
  DirectoryHandle* = SYSTEM.ADDRESS;
  Directory = POINTER TO DirectoryDesc;
  DirectoryDesc = RECORD search, entry: SYSTEM.ADDRESS; first: BOOLEAN END;

  FileIdentity* = RECORD
    volume:    LONGINT;  (* dev on Unix filesystems, volume serial number on NTFS *)
    indexhigh: LONGINT;  (* inode on Unix filesystems, file id on NTFS *)
    indexlow:  LONGINT;
    mtimehigh: LONGINT;  (* File modification time, value is system dependent *)
    mtimelow:  LONGINT;  (* File modification time, value is system dependent *)
  END;

VAR
  LittleEndian-:    BOOLEAN;
  PID-:             INTEGER;    (* Note: Must be updated by Fork implementation *)
  CWD-:             ARRAY 4096 OF CHAR;
  TimeStart:        LONGINT;

  SeekSet-:         INTEGER;
  SeekCur-:         INTEGER;
  SeekEnd-:         INTEGER;

  StdIn-:           FileHandle;
  StdOut-:          FileHandle;
  StdErr-:          FileHandle;

  NL-:              ARRAY 3 OF CHAR;  (* Platform specific newline representation *)



PROCEDURE -AincludeWindowsWrapper '#include "WindowsWrapper.h"';


(* Error code tests *)

(* Recoverable commands are currently a Unix-host facility. *)
PROCEDURE RunCommand*(command: Command): SYSTEM.INT32;
BEGIN command; RETURN 0 END RunCommand;

PROCEDURE CommandCritical*(enter: BOOLEAN);
BEGIN END CommandCritical;

PROCEDURE -ERRORTOOMANYOPENFILES(): ErrorCode 'ERROR_TOO_MANY_OPEN_FILES';
PROCEDURE -ERRORPATHNOTFOUND():     ErrorCode 'ERROR_PATH_NOT_FOUND';
PROCEDURE -ERRORFILENOTFOUND():     ErrorCode 'ERROR_FILE_NOT_FOUND';
PROCEDURE -ERRORNOTSAMEDEVICE():    ErrorCode 'ERROR_NOT_SAME_DEVICE';
PROCEDURE -ERRORACCESSDENIED():     ErrorCode 'ERROR_ACCESS_DENIED';
PROCEDURE -ERRORWRITEPROTECT():     ErrorCode 'ERROR_WRITE_PROTECT';
PROCEDURE -ERRORSHARINGVIOLATION(): ErrorCode 'ERROR_SHARING_VIOLATION';
PROCEDURE -ERRORNOTREADY():         ErrorCode 'ERROR_NOT_READY';
PROCEDURE -ETIMEDOUT():             ErrorCode 'WSAETIMEDOUT';
PROCEDURE -ECONNREFUSED():          ErrorCode 'WSAECONNREFUSED';
PROCEDURE -ECONNABORTED():          ErrorCode 'WSAECONNABORTED';
PROCEDURE -ENETUNREACH():           ErrorCode 'WSAENETUNREACH';
PROCEDURE -EHOSTUNREACH():          ErrorCode 'WSAEHOSTUNREACH';
PROCEDURE -EINTR():                 ErrorCode 'WSAEINTR';



PROCEDURE TooManyFiles*(e: ErrorCode): BOOLEAN;
BEGIN RETURN e = ERRORTOOMANYOPENFILES() END TooManyFiles;

PROCEDURE NoSuchDirectory*(e: ErrorCode): BOOLEAN;
BEGIN RETURN e = ERRORPATHNOTFOUND() END NoSuchDirectory;

PROCEDURE DifferentFilesystems*(e: ErrorCode): BOOLEAN;
BEGIN RETURN e = ERRORNOTSAMEDEVICE() END DifferentFilesystems;

PROCEDURE Inaccessible*(e: ErrorCode): BOOLEAN;
BEGIN
  RETURN (e = ERRORACCESSDENIED()) OR (e = ERRORWRITEPROTECT())
      OR (e = ERRORNOTREADY())     OR (e = ERRORSHARINGVIOLATION());
END Inaccessible;

PROCEDURE Absent*(e: ErrorCode): BOOLEAN;
BEGIN RETURN (e = ERRORFILENOTFOUND()) OR (e = ERRORPATHNOTFOUND()) END Absent;

PROCEDURE TimedOut*(e: ErrorCode): BOOLEAN;
BEGIN RETURN (e = ETIMEDOUT()) END TimedOut;

PROCEDURE ConnectionFailed*(e: ErrorCode): BOOLEAN;
BEGIN RETURN (e = ECONNREFUSED()) OR (e = ECONNABORTED())
          OR (e = ENETUNREACH())  OR (e = EHOSTUNREACH()) END ConnectionFailed;

PROCEDURE Interrupted*(e: ErrorCode): BOOLEAN;
BEGIN RETURN e = EINTR() END Interrupted;




(* Expose file and path name length limits (same on Windows) *)

PROCEDURE -MAXPATH(): INTEGER 'MAX_PATH';

PROCEDURE MaxNameLength*(): INTEGER;  BEGIN RETURN MAXPATH() END MaxNameLength;
PROCEDURE MaxPathLength*(): INTEGER;  BEGIN RETURN MAXPATH() END MaxPathLength;




(* OS memory allocaton *)

PROCEDURE -allocate(size: SYSTEM.ADDRESS): SYSTEM.ADDRESS "(ADDRESS)((void*)HeapAlloc(GetProcessHeap(), 0, (size_t)size))";
PROCEDURE OSAllocate*(size: SYSTEM.ADDRESS): SYSTEM.ADDRESS; BEGIN RETURN allocate(size) END OSAllocate;

PROCEDURE -free(address: SYSTEM.ADDRESS) "HeapFree(GetProcessHeap(), 0, (void*)address)";
PROCEDURE OSFree*(address: SYSTEM.ADDRESS); BEGIN free(address) END OSFree;




(* Program arguments and environmet access *)

PROCEDURE -getenv(name: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR): INTEGER
"(INTEGER)GetEnvironmentVariable((char*)name, (char*)buf, buf__len)";

PROCEDURE getEnv*(var: ARRAY OF CHAR; VAR val: ARRAY OF CHAR): BOOLEAN;
  VAR
    buf: ARRAY 4096 OF CHAR;
    res: INTEGER;
BEGIN
  res := getenv(var, buf);
  IF (res > 0) & (res < LEN(buf)) THEN
    COPY(buf, val);
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END;
END getEnv;

PROCEDURE GetEnv*(var: ARRAY OF CHAR; VAR val: ARRAY OF CHAR);
BEGIN
  IF ~getEnv(var, val) THEN val[0] := 0X END;
END GetEnv;





(* Signals and traps *)

(* PROCEDURE -signal(sig: LONGINT; func: SignalHandler) "signal(sig, func)"; *)

(* TODO *)

(* Ctrl/c handling *)

PROCEDURE -SetInterruptHandler*(h: SignalHandler) "SystemSetInterruptHandler((ADDRESS)h)";
PROCEDURE -SetQuitHandler*     (h: SignalHandler) "SystemSetQuitHandler((ADDRESS)h)";

PROCEDURE SetBadInstructionHandler*(handler: SignalHandler);
BEGIN (* TODO *) END SetBadInstructionHandler;




(* Time of day *)

PROCEDURE -getLocalTime  "SYSTEMTIME st; GetLocalTime(&st)";
PROCEDURE -stmsec(): INTEGER  "(INTEGER)st.wMilliseconds";
PROCEDURE -stsec():  INTEGER  "(INTEGER)st.wSecond";
PROCEDURE -stmin():  INTEGER  "(INTEGER)st.wMinute";
PROCEDURE -sthour(): INTEGER  "(INTEGER)st.wHour";
PROCEDURE -stmday(): INTEGER  "(INTEGER)st.wDay";
PROCEDURE -stmon():  INTEGER  "(INTEGER)st.wMonth";
PROCEDURE -styear(): INTEGER  "(INTEGER)st.wYear";

PROCEDURE YMDHMStoClock(ye,mo,da,ho,mi,se: INTEGER; VAR t, d: LONGINT);
BEGIN
  d := ASH(ye MOD 100, 9) + ASH(mo, 5) + da;
  t := ASH(ho, 12)        + ASH(mi, 6)   + se;
END YMDHMStoClock;

PROCEDURE GetClock*(VAR t, d: LONGINT);
BEGIN
  getLocalTime;
  YMDHMStoClock(styear(), stmon(), stmday(), sthour(), stmin(), stsec(), t, d);
END GetClock;

PROCEDURE -GetTickCount(): LONGINT "(LONGINT)(UINT32)GetTickCount()";

PROCEDURE Time*(): LONGINT;
VAR ms: LONGINT;
BEGIN
  ms := GetTickCount();
  RETURN (ms - TimeStart) MOD 7FFFFFFFH;
END Time;


PROCEDURE -sleep(ms: LONGINT) "Sleep((DWORD)ms)";

PROCEDURE Delay*(ms: LONGINT);
BEGIN
  WHILE ms > 30000 DO sleep(30000); ms := ms-30000 END;
  IF ms > 0 THEN sleep(ms) END;
END Delay;


PROCEDURE -stToFt  "FILETIME ft; SystemTimeToFileTime(&st, &ft)";
PROCEDURE -ftToUli "ULARGE_INTEGER ul; ul.LowPart=ft.dwLowDateTime; ul.HighPart=ft.dwHighDateTime";
PROCEDURE -tous1970  "ul.QuadPart = (ul.QuadPart - 116444736000000000ULL)/10LL";
PROCEDURE -ulSec():  LONGINT  "(LONGINT)(ul.QuadPart / 1000000LL)";
PROCEDURE -uluSec(): LONGINT  "(LONGINT)(ul.QuadPart % 1000000LL)";

PROCEDURE GetTimeOfDay*(VAR sec, usec: LONGINT);
BEGIN
  getLocalTime;  stToFt;  ftToUli;  tous1970;
  sec := ulSec();  usec := uluSec();
END GetTimeOfDay;



(* System call *)

PROCEDURE -startupInfo                                "STARTUPINFO si = {0}; si.cb = sizeof(si);";
PROCEDURE -processInfo                                "PROCESS_INFORMATION pi = {0};";
PROCEDURE -createProcess(str: ARRAY OF CHAR): INTEGER "(INTEGER)CreateProcess(0, (char*)str, 0,0,0,0,0,0,&si,&pi)";
PROCEDURE -waitForProcess(): INTEGER                  "(INTEGER)WaitForSingleObject(pi.hProcess, INFINITE)";
PROCEDURE -getExitCodeProcess(VAR exitcode: INTEGER)  "GetExitCodeProcess(pi.hProcess, (DWORD*)exitcode);";
PROCEDURE -cleanupProcess                             "CloseHandle(pi.hProcess); CloseHandle(pi.hThread);";
PROCEDURE -err(): INTEGER                             "(INTEGER)GetLastError()";

PROCEDURE System*(cmd : ARRAY OF CHAR): INTEGER;
VAR
  result: INTEGER;
BEGIN
  result := 127;
  startupInfo; processInfo;
  IF createProcess(cmd) # 0 THEN
    IF waitForProcess() = 0 THEN getExitCodeProcess(result) END;
    cleanupProcess;
  END;
  RETURN result * 256;
END System;

PROCEDURE Error*(): ErrorCode; BEGIN RETURN err() END Error;


(* File system *)

PROCEDURE OpenDirectory*(path: ARRAY OF CHAR;
                        VAR handle: DirectoryHandle): ErrorCode;
VAR dir: Directory; pattern: ARRAY 4096 OF CHAR; n: LONGINT; attributes, error: SYSTEM.INT32;
BEGIN
  handle := 0; attributes := PlatformNative.Attributes(path);
  IF PlatformNative.InvalidAttributes(attributes) THEN RETURN SHORT(PlatformNative.Error()) END;
  IF ~PlatformNative.Directory(attributes) THEN RETURN SHORT(PlatformNative.DirectoryError()) END;
  n := 0; WHILE (n < LEN(path)) & (path[n] # 0X) DO INC(n) END;
  IF (n = LEN(path)) OR (n + 3 > LEN(pattern)) THEN RETURN SHORT(PlatformNative.NameTooLong()) END;
  COPY(path, pattern);
  IF (n > 0) & (pattern[n - 1] # "/") & (pattern[n - 1] # 5CX) THEN pattern[n] := "/"; INC(n) END;
  pattern[n] := "*"; pattern[n + 1] := 0X;
  dir := SYSTEM.VAL(Directory, OSAllocate(SIZE(DirectoryDesc)));
  IF dir = NIL THEN RETURN SHORT(PlatformNative.NoMemory()) END;
  dir.entry := OSAllocate(PlatformNative.EntrySize());
  IF dir.entry = 0 THEN OSFree(SYSTEM.VAL(SYSTEM.ADDRESS, dir)); RETURN SHORT(PlatformNative.NoMemory()) END;
  dir.search := PlatformNative.First(pattern, dir.entry);
  dir.first := dir.search # PlatformNative.Invalid();
  IF ~dir.first THEN
    error := PlatformNative.Error();
    IF ~PlatformNative.NoFiles(error) THEN
      OSFree(dir.entry); OSFree(SYSTEM.VAL(SYSTEM.ADDRESS, dir)); RETURN SHORT(error)
    END
  END;
  handle := SYSTEM.VAL(SYSTEM.ADDRESS, dir); RETURN 0
END OpenDirectory;

PROCEDURE ReadDirectory*(handle: DirectoryHandle; VAR name: ARRAY OF CHAR;
                        VAR done: BOOLEAN): ErrorCode;
VAR dir: Directory; address, i: SYSTEM.ADDRESS; error: SYSTEM.INT32; ch: CHAR;
BEGIN
  dir := SYSTEM.VAL(Directory, handle); done := FALSE;
  IF LEN(name) > 0 THEN name[0] := 0X END;
  IF dir.search = PlatformNative.Invalid() THEN done := TRUE; RETURN 0 END;
  IF ~dir.first & ~PlatformNative.Next(dir.search, dir.entry) THEN
    done := TRUE; error := PlatformNative.Error();
    IF PlatformNative.NoMoreFiles(error) THEN RETURN 0 ELSE RETURN SHORT(error) END
  END;
  dir.first := FALSE; address := PlatformNative.EntryName(dir.entry); i := 0;
  LOOP
    SYSTEM.GET(address + i, ch);
    IF i >= LEN(name) THEN RETURN SHORT(PlatformNative.NameTooLong()) END;
    IF i = LEN(name) - 1 THEN
      name[i] := 0X;
      IF ch # 0X THEN RETURN SHORT(PlatformNative.NameTooLong()) END
    ELSE name[i] := ch
    END;
    IF ch = 0X THEN RETURN 0 END;
    INC(i)
  END
END ReadDirectory;

PROCEDURE CloseDirectory*(VAR handle: DirectoryHandle): ErrorCode;
VAR dir: Directory; error: SYSTEM.INT32;
BEGIN
  IF handle = 0 THEN RETURN 0 END;
  dir := SYSTEM.VAL(Directory, handle); handle := 0; error := 0;
  IF (dir.search # PlatformNative.Invalid()) & ~PlatformNative.Close(dir.search) THEN error := PlatformNative.Error() END;
  OSFree(dir.entry); OSFree(SYSTEM.VAL(SYSTEM.ADDRESS, dir)); RETURN SHORT(error)
END CloseDirectory;

PROCEDURE IsDirectory*(path: ARRAY OF CHAR): BOOLEAN;
VAR attributes: SYSTEM.INT32;
BEGIN
  attributes := PlatformNative.Attributes(path);
  RETURN ~PlatformNative.InvalidAttributes(attributes) & PlatformNative.Directory(attributes)
END IsDirectory;

PROCEDURE -invalidHandleValue(): SYSTEM.ADDRESS "((ADDRESS)INVALID_HANDLE_VALUE)";

PROCEDURE -openrw (n: ARRAY OF CHAR): FileHandle
"(ADDRESS)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)";

PROCEDURE -openro (n: ARRAY OF CHAR): FileHandle
"(ADDRESS)CreateFile((char*)n, GENERIC_READ              , FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)";

PROCEDURE -opennew(n: ARRAY OF CHAR): FileHandle
"(ADDRESS)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)";




(* File APIs *)

PROCEDURE OldRO*(VAR n: ARRAY OF CHAR; VAR h: FileHandle): ErrorCode;
VAR fd: FileHandle;
BEGIN
  fd := openro(n);
  IF (fd = invalidHandleValue()) THEN RETURN err() ELSE h := fd; RETURN 0 END;
END OldRO;

PROCEDURE OldRW*(VAR n: ARRAY OF CHAR; VAR h: FileHandle): ErrorCode;
VAR fd: FileHandle;
BEGIN
  fd := openrw(n);
  IF (fd = invalidHandleValue()) THEN RETURN err() ELSE h := fd; RETURN 0 END;
END OldRW;

PROCEDURE New*(VAR n: ARRAY OF CHAR; VAR h: FileHandle): ErrorCode;
VAR fd: FileHandle;
BEGIN
  fd := opennew(n);
  IF (fd = invalidHandleValue()) THEN RETURN err() ELSE h := fd; RETURN 0 END;
END New;



PROCEDURE -closeHandle(h: FileHandle): INTEGER "(INTEGER)CloseHandle((HANDLE)h)";

PROCEDURE Close*(h: FileHandle): ErrorCode;
BEGIN
  IF closeHandle(h) = 0 THEN RETURN err() ELSE RETURN 0 END
END Close;


PROCEDURE -openwriteattributes(n: ARRAY OF CHAR): FileHandle
"(ADDRESS)CreateFile((char*)n, FILE_WRITE_ATTRIBUTES, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)";

PROCEDURE -mtimevars "SYSTEMTIME mst = {0}; FILETIME mft";
PROCEDURE -setmtimedate(year, month, day: LONGINT)
"mst.wYear = (WORD)year; mst.wMonth = (WORD)month; mst.wDay = (WORD)day";
PROCEDURE -setmtimetime(hour, minute, second: LONGINT)
"mst.wHour = (WORD)hour; mst.wMinute = (WORD)minute; mst.wSecond = (WORD)second";
PROCEDURE -makemtime(): INTEGER "(INTEGER)SystemTimeToFileTime(&mst, &mft)";
PROCEDURE -applymtime(h: FileHandle): INTEGER
"(INTEGER)SetFileTime((HANDLE)h, 0, 0, &mft)";

PROCEDURE SetFileMTime* (VAR n: ARRAY OF CHAR; year, month, day,
                         hour, minute, second: LONGINT): ErrorCode;
  VAR handle: FileHandle; result: INTEGER; error, closeError: ErrorCode;
BEGIN
  handle := openwriteattributes(n);
  IF handle = invalidHandleValue() THEN RETURN err() END;
  mtimevars;
  setmtimedate(year, month, day);
  setmtimetime(hour, minute, second);
  result := makemtime();
  IF result # 0 THEN result := applymtime(handle) END;
  IF result = 0 THEN error := err() ELSE error := 0 END;
  closeError := Close(handle);
  IF error # 0 THEN RETURN error ELSE RETURN closeError END
END SetFileMTime;



PROCEDURE -byHandleFileInformation "BY_HANDLE_FILE_INFORMATION bhfi";
PROCEDURE -getFileInformationByHandle(h: FileHandle): INTEGER "(INTEGER)GetFileInformationByHandle((HANDLE)h, &bhfi)";
PROCEDURE -bhfiMtimeHigh(): LONGINT "(LONGINT)bhfi.ftLastWriteTime.dwHighDateTime";
PROCEDURE -bhfiMtimeLow():  LONGINT "(LONGINT)bhfi.ftLastWriteTime.dwLowDateTime";
PROCEDURE -bhfiVsn():       LONGINT "(LONGINT)bhfi.dwVolumeSerialNumber";
PROCEDURE -bhfiIndexHigh(): LONGINT "(LONGINT)bhfi.nFileIndexHigh";
PROCEDURE -bhfiIndexLow():  LONGINT "(LONGINT)bhfi.nFileIndexLow";


PROCEDURE Identify*(h: FileHandle; VAR identity: FileIdentity): ErrorCode;
BEGIN
  byHandleFileInformation;
  IF getFileInformationByHandle(h) = 0 THEN RETURN err() END;
  identity.volume    := bhfiVsn();
  identity.indexhigh := bhfiIndexHigh();
  identity.indexlow  := bhfiIndexLow();
  identity.mtimehigh := bhfiMtimeHigh();
  identity.mtimelow  := bhfiMtimeLow();
  RETURN 0
END Identify;

PROCEDURE IdentifyByName*(n: ARRAY OF CHAR; VAR identity: FileIdentity): ErrorCode;
VAR
  h:   FileHandle;
  e,i: ErrorCode;
BEGIN
  e := OldRO(n, h);
  IF e # 0 THEN RETURN e END;
  e := Identify(h, identity);
  i := Close(h);
  RETURN e;
END IdentifyByName;


PROCEDURE SameFile*(i1, i2: FileIdentity): BOOLEAN;
BEGIN RETURN (i1.indexhigh = i2.indexhigh) & (i1.indexlow = i2.indexlow) & (i1.volume = i2.volume)
END SameFile;

PROCEDURE SameFileTime*(i1, i2: FileIdentity): BOOLEAN;
BEGIN RETURN (i1.mtimehigh = i2.mtimehigh) & (i1.mtimelow = i2.mtimelow)
END SameFileTime;

PROCEDURE SetMTime*(VAR target: FileIdentity; source: FileIdentity);
BEGIN target.mtimehigh := source.mtimehigh;  target.mtimelow := source.mtimelow;
END SetMTime;

PROCEDURE -identityToFileTime(i: FileIdentity)
"FILETIME ft; ft.dwHighDateTime = i.mtimehigh; ft.dwLowDateTime = i.mtimelow";

PROCEDURE -fileTimeToSysTime
"SYSTEMTIME st; FileTimeToSystemTime(&ft, &st)";

PROCEDURE MTimeAsClock*(i: FileIdentity; VAR t, d: LONGINT);
BEGIN
  identityToFileTime(i); fileTimeToSysTime;
  YMDHMStoClock(styear(), stmon(), stmday(), sthour(), stmin(), stsec(), t, d);
END MTimeAsClock;

PROCEDURE -largeInteger "LARGE_INTEGER li";
PROCEDURE -liLongint(): LONGINT "(LONGINT)li.QuadPart";
PROCEDURE -getFileSize(h: FileHandle): INTEGER "(INTEGER)GetFileSizeEx((HANDLE)h, &li)";

PROCEDURE Size*(h: FileHandle; VAR l: LONGINT): ErrorCode;
BEGIN
  largeInteger;
  IF getFileSize(h) = 0 THEN RETURN err() END;
  l := liLongint();
  RETURN 0;
END Size;


PROCEDURE -readfile (fd: FileHandle; p: SYSTEM.ADDRESS; l: LONGINT; VAR n: SYSTEM.INT32): INTEGER
"(INTEGER)ReadFile((HANDLE)fd, (void*)p, (DWORD)l, (DWORD*)n, 0)";

PROCEDURE Read*(h: FileHandle; p: SYSTEM.ADDRESS; l: LONGINT; VAR n: LONGINT): ErrorCode;
VAR result: INTEGER; lengthread: SYSTEM.INT32;
BEGIN
  result := readfile(h, p, l, lengthread);
  IF result = 0 THEN n := 0; RETURN err() ELSE n := lengthread; RETURN 0 END
END Read;

PROCEDURE ReadBuf*(h: FileHandle; VAR b: ARRAY OF SYSTEM.BYTE; VAR n: LONGINT): ErrorCode;
VAR result: INTEGER; lengthread: SYSTEM.INT32;
BEGIN
  result := readfile(h, SYSTEM.ADR(b), LEN(b), lengthread);
  IF result = 0 THEN n := 0; RETURN err() ELSE n := lengthread; RETURN 0 END
END ReadBuf;



PROCEDURE -writefile(fd: FileHandle; p: SYSTEM.ADDRESS; l: LONGINT; VAR n: SYSTEM.INT32): INTEGER
"(INTEGER)WriteFile((HANDLE)fd, (void*)(p), (DWORD)l, (DWORD*)n, 0)";

PROCEDURE WriteCount*(h: FileHandle; p: SYSTEM.ADDRESS; l: LONGINT;
                      VAR n: LONGINT): ErrorCode;
VAR result: INTEGER; written: SYSTEM.INT32;
BEGIN
  result := writefile(h, p, l, written);
  IF result = 0 THEN n := 0; RETURN err() ELSE n := written; RETURN 0 END
END WriteCount;

PROCEDURE Write*(h: FileHandle; p: SYSTEM.ADDRESS; l: LONGINT): ErrorCode;
VAR n: LONGINT;
BEGIN
  RETURN WriteCount(h, p, l, n)
END Write;



PROCEDURE -flushFileBuffers(h: FileHandle): INTEGER "(INTEGER)FlushFileBuffers((HANDLE)h)";

PROCEDURE Sync*(h: FileHandle): ErrorCode;
BEGIN
  IF flushFileBuffers(h) = 0 THEN RETURN err() ELSE RETURN 0 END
END Sync;



PROCEDURE -setFilePointerEx(h: FileHandle; o: LONGINT; r: INTEGER; VAR rc: INTEGER)
"li.QuadPart=o; *rc = (INTEGER)SetFilePointerEx((HANDLE)h, li, 0, (DWORD)r)";

PROCEDURE -seekset(): INTEGER "FILE_BEGIN";
PROCEDURE -seekcur(): INTEGER "FILE_CURRENT";
PROCEDURE -seekend(): INTEGER "FILE_END";

PROCEDURE Seek*(h: FileHandle; o: LONGINT; r: INTEGER): ErrorCode;
VAR rc: INTEGER;
BEGIN
  largeInteger;
  setFilePointerEx(h, o, r, rc);
  IF rc = 0 THEN RETURN err() ELSE RETURN 0 END
END Seek;

PROCEDURE -setEndOfFile(h: FileHandle): INTEGER "(INTEGER)SetEndOfFile((HANDLE)h)";
PROCEDURE -getFilePos(h: FileHandle; VAR r: LONGINT; VAR rc: INTEGER)
"LARGE_INTEGER liz = {0}; *rc = (INTEGER)SetFilePointerEx((HANDLE)h, liz, &li, FILE_CURRENT); *r = (LONGINT)li.QuadPart";

PROCEDURE Tell*(h: FileHandle; VAR offset: LONGINT): ErrorCode;
VAR rc: INTEGER;
BEGIN
  largeInteger;
  getFilePos(h, offset, rc);
  IF rc = 0 THEN offset := 0; RETURN err() ELSE RETURN 0 END
END Tell;

PROCEDURE Truncate*(h: FileHandle; limit: LONGINT): ErrorCode;
VAR rc: INTEGER; oldpos: LONGINT;
BEGIN
  largeInteger;
  getFilePos(h, oldpos, rc);
  IF rc = 0                                          THEN RETURN err() END;
  setFilePointerEx(h, limit, seekset(), rc);
  IF rc = 0                                          THEN RETURN err() END;
  IF setEndOfFile(h) = 0                             THEN RETURN err() END;
  setFilePointerEx(h, oldpos, seekset(), rc);  (* Restore original file position *)
  IF rc = 0                                          THEN RETURN err() END;
  RETURN 0;
END Truncate;



PROCEDURE -deleteFile(n: ARRAY OF CHAR): INTEGER "(INTEGER)DeleteFile((char*)n)";

PROCEDURE Unlink*(VAR n: ARRAY OF CHAR): ErrorCode;
BEGIN
  IF deleteFile(n) = 0 THEN RETURN err() ELSE RETURN 0 END
END Unlink;


PROCEDURE -setCurrentDirectory(n: ARRAY OF CHAR): INTEGER "(INTEGER)SetCurrentDirectory((char*)n)";
PROCEDURE -getCurrentDirectory(VAR n: ARRAY OF CHAR) "GetCurrentDirectory(n__len, (char*)n)";

PROCEDURE Chdir*(VAR n: ARRAY OF CHAR): ErrorCode;
  VAR r: INTEGER;
BEGIN
  r := setCurrentDirectory(n);
  IF r = 0 THEN RETURN err() END;
  getCurrentDirectory(CWD);
  RETURN 0;
END Chdir;



PROCEDURE -moveFile(o,n: ARRAY OF CHAR): INTEGER
"(INTEGER)MoveFileEx((char*)o, (char*)n, MOVEFILE_REPLACE_EXISTING)";

PROCEDURE Rename*(VAR o,n: ARRAY OF CHAR): ErrorCode;
BEGIN
  IF moveFile(o,n) = 0 THEN RETURN err() ELSE RETURN 0 END
END Rename;




(* Process termination *)

PROCEDURE -exit(code: LONGINT) "ExitProcess((UINT)code)";
PROCEDURE Exit*(code: LONGINT); BEGIN exit(code) END Exit;


PROCEDURE -GetConsoleMode(h: FileHandle; VAR m: SYSTEM.INT32): BOOLEAN "GetConsoleMode((HANDLE)h, (DWORD*)m)";
PROCEDURE -SetConsoleMode(h: FileHandle; m: SYSTEM.INT32) "SetConsoleMode((HANDLE)h, (DWORD)m)";

PROCEDURE EnableVT100;
CONST VTprocessing = 4; (* ENABLE_VIRTUAL_TERMINAL_PROCESSING: value specified by MSDN *)
VAR mode: SYSTEM.INT32;
BEGIN IF GetConsoleMode(StdOut, mode) THEN SetConsoleMode(StdOut, mode+VTprocessing) END
END EnableVT100;

PROCEDURE IsConsole*(h: FileHandle): BOOLEAN;
VAR mode: SYSTEM.INT32;
BEGIN RETURN GetConsoleMode(h, mode)
END IsConsole;


PROCEDURE TestLittleEndian;
  VAR i: INTEGER;
 BEGIN i := 1; SYSTEM.GET(SYSTEM.ADR(i), LittleEndian); END TestLittleEndian;


PROCEDURE -getstdinhandle():  FileHandle "(ADDRESS)GetStdHandle(STD_INPUT_HANDLE)";
PROCEDURE -getstdouthandle(): FileHandle "(ADDRESS)GetStdHandle(STD_OUTPUT_HANDLE)";
PROCEDURE -getstderrhandle(): FileHandle "(ADDRESS)GetStdHandle(STD_ERROR_HANDLE)";
PROCEDURE -getpid():          INTEGER    "(INTEGER)GetCurrentProcessId()";

BEGIN
  TestLittleEndian;

  TimeStart   := 0;   TimeStart := Time();
  CWD         := "";  getCurrentDirectory(CWD);
  PID         := getpid();

  SeekSet := seekset();
  SeekCur := seekcur();
  SeekEnd := seekend();

  StdIn  := getstdinhandle();
  StdOut := getstdouthandle();
  StdErr := getstderrhandle();

  EnableVT100;

  NL[0] := 0DX;  (* CR *)
  NL[1] := 0AX;  (* LF *)
  NL[2] := 0X;
END Platform.
