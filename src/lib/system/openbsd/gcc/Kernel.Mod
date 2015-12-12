MODULE Kernel; 
(*
  J. Templ, 16.4.95 
  communication with C-runtime and storage management
*)
  
  IMPORT SYSTEM, Unix, Args;

  TYPE
(* from time.h on OpenBSD; added yday; changed gmtoff, zone order;
    sec to isdst changed to INTEGER; -- antranigv
  struct tm {
        int     tm_sec;         
        int     tm_min;         
        int     tm_hour;        
        int     tm_mday;        
        int     tm_mon;         
        int     tm_year;        
        int     tm_wday;        
        int     tm_yday;        
        int     tm_isdst;       
        long    tm_gmtoff;      
        char    *tm_zone;       
}; *)

    RealTime = POINTER TO TimeDesc;
    TimeDesc = RECORD
      sec, min, hour, mday, mon, year, wday, yday, isdst : INTEGER;
      gmtoff, zone : LONGINT
(*      sec, min, hour, mday, mon, year, wday, isdst, zone, gmtoff: INTEGER*)
    END ;

    KeyCmd* = PROCEDURE;

    ObjFinalizer* = PROCEDURE(obj: SYSTEM.PTR);


  VAR
    (* trap handling *)
    trapEnv*: Unix.JmpBuf;  (* saved stack environment for trap handling *)
    
    (* oberon heap management *)
    nofiles*: LONGINT;

    (* input event handling *)
    readSet*, readySet*: Unix.FdSet;

    FKey*: ARRAY 16 OF KeyCmd;

    littleEndian*: BOOLEAN;

    TimeUnit*: LONGINT;  (* 1 sec *)

    LIB*, CWD*: ARRAY 256 OF CHAR;
    OBERON*: ARRAY 1024 OF CHAR;


    timeStart: LONGINT; (* milliseconds *)

  PROCEDURE -includesetjmp()
    '#include "setjmp.h"';
(* for localtime *)
  PROCEDURE -includetime()
    '#include "time.h"';

  PROCEDURE -Lock*()
    "SYSTEM_lock++";

  PROCEDURE -Unlock*()
    "SYSTEM_lock--; if (SYSTEM_interrupted && SYSTEM_lock == 0) __HALT(-9)";

  PROCEDURE -Exit*(n: LONGINT)
    "exit(n)";

  PROCEDURE -sigsetjmp*(VAR env: Unix.JmpBuf; savemask: LONGINT): LONGINT
      "__sigsetjmp(env, savemask)";

  PROCEDURE -siglongjmp*(VAR env:Unix. JmpBuf; val: LONGINT)
      "siglongjmp(env, val)";

  PROCEDURE -heapsize*(): LONGINT
      "SYSTEM_heapsize";

  PROCEDURE -allocated*(): LONGINT
      "SYSTEM_allocated";

  PROCEDURE -localtime(VAR clock: LONGINT): RealTime
      "(Kernel_RealTime)localtime(clock)";

  PROCEDURE -malloc*(size: LONGINT): LONGINT
      "(LONGINT)malloc(size)";

  PROCEDURE -free*(adr: LONGINT)
      "(void)free(adr)";

  PROCEDURE -getcwd(VAR cwd: Unix.Name)
    "getcwd(cwd, cwd__len)";


  PROCEDURE GetClock* (VAR t, d: LONGINT);
    VAR tv: Unix.Timeval; tz: Unix.Timezone; time: RealTime;
    l : LONGINT;
  BEGIN
    l := Unix.Gettimeofday(tv, tz);
    time := localtime(tv.sec);
    t := time.sec + ASH(time.min, 6) + ASH(time.hour, 12);
    d := time.mday + ASH(time.mon+1, 5) + ASH(time.year MOD 100, 9); 
  END GetClock;

  PROCEDURE SetClock* (t, d: LONGINT);
    VAR err: ARRAY 25 OF CHAR;
  BEGIN err := "not yet implemented"; HALT(99)
  END SetClock;

  PROCEDURE Time*(): LONGINT;
    VAR timeval: Unix.Timeval; timezone: Unix.Timezone;
    l : LONGINT;
  BEGIN
    l := Unix.Gettimeofday(timeval, timezone);
    RETURN (timeval.usec DIV 1000 + timeval.sec * 1000 - timeStart) MOD 7FFFFFFFH
  END  Time;

(*
  PROCEDURE UserTime*(): LONGINT;
    VAR rusage: Unix.Rusage;
  BEGIN
    Unix.Getrusage(0, S.ADR(rusage));
    RETURN rusage.utime.sec*1000 + rusage.utime.usec DIV 1000
        (*  + rusage.stime.sec*1000 + rusage.stime.usec DIV 1000*)
  END  UserTime;
*)

  PROCEDURE Select*(delay: LONGINT);
    VAR rs, ws, xs: Unix.FdSet; n: LONGINT; tv: Unix.Timeval;
  BEGIN
    rs := readSet;
    FOR n := 0 TO 7 DO ws[n] := {}; xs[n] := {}; readySet[n] := {} END;
    IF delay < 0 THEN delay := 0 END ;
    tv.sec := delay DIV 1000; tv.usec := delay MOD 1000 * 1000;
    n := Unix.Select(256, rs, ws, xs, tv);
    IF n >= 0 THEN readySet := rs END
  END Select;

  PROCEDURE -GC*(markStack: BOOLEAN)
    "SYSTEM_GC(markStack)";

  PROCEDURE -RegisterObject*(obj: SYSTEM.PTR; finalize: ObjFinalizer)
    "SYSTEM_REGFIN(obj, finalize)";

  PROCEDURE -SetHalt*(p: PROCEDURE(n: LONGINT))
      "SYSTEM_Halt = p";

  PROCEDURE InstallTermHandler*(p: PROCEDURE);
    (* not yet supported; no Modules.Free *)
  END InstallTermHandler;

  PROCEDURE LargestAvailable*(): LONGINT;
  BEGIN
    (* dummy proc for System 3 compatibility
        no meaningful value except may be the remaining swap space can be returned
        in the context of an extensible heap *)
    RETURN MAX(LONGINT)
  END LargestAvailable;

  PROCEDURE Halt(n: LONGINT);
    VAR res: LONGINT;
  BEGIN res := Unix.Kill(Unix.Getpid(), 4);
  END Halt;

  PROCEDURE EndianTest;
    VAR i: LONGINT; dmy: INTEGER;
  BEGIN
    dmy := 1; i := SYSTEM.ADR(dmy);
    SYSTEM.GET(i, littleEndian);  (* indirection via i avoids warning on SUN cc -O *)
  END EndianTest;

  PROCEDURE -SizeofUnixJmpBuf(): INTEGER
    "sizeof(Unix_JmpBuf)";

  PROCEDURE -SizeofSigJmpBuf(): INTEGER
    "sizeof(sigjmp_buf)";

  PROCEDURE -Error(msg: ARRAY OF CHAR; len: INTEGER)
    "write(1/*stdout*/, msg, len); char ch = 0xa; write(1, &ch, 1)";

  PROCEDURE JmpBufCheck; (* check for inconsistent usage of sigjmp_buf *)
    VAR x, y: LONGINT;
  BEGIN
    x := SizeofUnixJmpBuf();
    y := SizeofSigJmpBuf();
    IF x < y THEN
      Error("Kernel.JmpBufCheck: inconsistent usage of sigjmp_buf", 52);
      Exit(1);
    END
  END JmpBufCheck;

BEGIN
  EndianTest();
  SetHalt(Halt);
  CWD := ""; OBERON := "."; LIB := "";
  getcwd(CWD);
  Args.GetEnv("OBERON", OBERON);
  Args.GetEnv("OBERON_LIB", LIB);
  TimeUnit := 1000; timeStart := 0; timeStart := Time();
  JmpBufCheck()
END Kernel.
